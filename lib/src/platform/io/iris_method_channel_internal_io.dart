import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart'
    show VoidCallback, debugPrint, visibleForTesting;
import 'package:iris_method_channel/iris_method_channel.dart';
import 'package:iris_method_channel/src/platform/io/bindings/native_iris_api_common_bindings.dart'
    as iris;
import 'package:iris_method_channel/src/platform/io/iris_event_io.dart';

// ignore_for_file: public_member_api_docs

class _Messenger implements DisposableObject {
  _Messenger(this.requestPort, this.responseQueue);
  final SendPort requestPort;
  final StreamQueue<dynamic> responseQueue;
  bool _isDisposed = false;

  Future<CallApiResult> send(Request request) async {
    if (_isDisposed) {
      return CallApiResult(
          irisReturnCode: kDisposedIrisMethodCallReturnCode,
          data: kDisposedIrisMethodCallData);
    }
    requestPort.send(request);
    return await responseQueue.next;
  }

  Future<List<CallApiResult>> listSend(Request request) async {
    if (_isDisposed) {
      return [
        CallApiResult(
            irisReturnCode: kDisposedIrisMethodCallReturnCode,
            data: kDisposedIrisMethodCallData)
      ];
    }
    requestPort.send(request);
    return await responseQueue.next;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    requestPort.send(null);
    try {
      // Wait for `executor.dispose` done in isolate.
      final response = await responseQueue.next;
      if (response is _DisposeFailure) {
        throw StateError(
            'Native Iris disposal failed: ${response.error}\n${response.stackTrace}');
      }
    } finally {
      await responseQueue.cancel();
    }
  }
}

class _InitilizationArgs {
  _InitilizationArgs(
    this.apiCallPortSendPort,
    this.eventPortSendPort,
    this.onExitSendPort,
    this.provider,
    this.argNativeHandles,
    this.nativeSessionId,
  );

  final SendPort apiCallPortSendPort;
  final SendPort eventPortSendPort;
  final SendPort? onExitSendPort;
  final PlatformBindingsProvider provider;
  final List<InitilizationArgProvider> argNativeHandles;
  final int nativeSessionId;
}

class _InitilizationFailure {
  const _InitilizationFailure(this.error, this.stackTrace);

  final String error;
  final String stackTrace;
}

class _DisposeFailure {
  const _DisposeFailure(this.error, this.stackTrace);

  final String error;
  final String stackTrace;
}

class InitilizationResultIO implements InitilizationResult {
  InitilizationResultIO(
    this._apiCallPortSendPort,
    this.irisApiEngineNativeHandle,
    this.nativeSessionId,
    this.extraData,
    this._debugIrisCEventHandlerNativeHandle,
    this._debugIrisEventHandlerNativeHandle,
  );

  final SendPort _apiCallPortSendPort;
  final int irisApiEngineNativeHandle;

  @override
  final int nativeSessionId;

  /// Same as [CreateApiEngineResult.extraData]
  final Map<String, Object> extraData;

  final int? _debugIrisCEventHandlerNativeHandle;
  final int? _debugIrisEventHandlerNativeHandle;
}

class _HotRestartFinalizer {
  _HotRestartFinalizer(this.provider) {
    _onExitPort = ReceivePort();
    _onExitSubscription = _onExitPort?.listen(_finalize);
  }

  final PlatformBindingsProvider provider;

  final List<HotRestartListener> _hotRestartListeners = [];

  ReceivePort? _onExitPort;
  StreamSubscription? _onExitSubscription;

  SendPort? get onExitSendPort => _onExitPort?.sendPort;

  bool _isFinalize = false;

  void _closeOnExitPort() {
    _onExitSubscription?.cancel();
    _onExitSubscription = null;
    _onExitPort?.close();
    _onExitPort = null;
  }

  int _nativeSessionId = 0;
  set nativeSessionId(int value) {
    _nativeSessionId = value;
  }

  int? _debugIrisApiEngineNativeHandle;
  set debugIrisApiEngineNativeHandle(int value) {
    _debugIrisApiEngineNativeHandle = value;
  }

  int? _debugIrisCEventHandlerNativeHandle;
  set debugIrisCEventHandlerNativeHandle(int? value) {
    _debugIrisCEventHandlerNativeHandle = value;
  }

  int? _debugIrisEventHandlerNativeHandle;
  set debugIrisEventHandlerNativeHandle(int? value) {
    _debugIrisEventHandlerNativeHandle = value;
  }

  // ignore: avoid_annotating_with_dynamic
  void _finalize(dynamic msg) {
    if (_isFinalize) {
      return;
    }
    _isFinalize = true;

    // We will receive a value of `0` as message when the `IrisMethodChannel.dispose`
    // is called normally, which will call the `Isolate.exit(onExitSendPort, 0)`
    // to send a value of `0` as a exit response. See `_execute` function for more detail.
    if (msg != null && msg == 0) {
      _closeOnExitPort();
      return;
    }

    for (final listener in _hotRestartListeners.reversed) {
      try {
        listener(msg);
      } catch (e, s) {
        debugPrint('HotRestartListener failed: $e\n$s');
      }
    }

    final sessionIrisEvent = provider.provideIrisEvent();
    if (_nativeSessionId != 0 && sessionIrisEvent is NativeSessionLifecycle) {
      try {
        // ignore: cast_nullable_to_non_nullable
        (sessionIrisEvent as NativeSessionLifecycle)
            .forceDestroyNativeSession(_nativeSessionId);
      } finally {
        _closeOnExitPort();
      }
      return;
    }

    if (_debugIrisApiEngineNativeHandle == null ||
        _debugIrisEventHandlerNativeHandle == null ||
        _debugIrisCEventHandlerNativeHandle == null) {
      _closeOnExitPort();
      return;
    }

    // When hot restart happen, the `IrisMethodChannel.dispose` function will not
    // be called normally, cause the native API engine can not be destroy correctly,
    // so we need to release the native resources which create by the
    // `NativeBindingDelegate` explicitly.
    try {
      final nativeBindingDelegate = provider.provideNativeBindingDelegate();
      nativeBindingDelegate.initialize();

      nativeBindingDelegate.destroyNativeApiEngine(IrisApiEngineHandle(
          ffi.Pointer<ffi.Void>.fromAddress(_debugIrisApiEngineNativeHandle!)));

      nativeBindingDelegate.destroyIrisEventHandler(IrisEventHandlerHandle(
          ffi.Pointer<ffi.Void>.fromAddress(
              _debugIrisEventHandlerNativeHandle!)));
      calloc.free(ffi.Pointer<ffi.Void>.fromAddress(
          _debugIrisCEventHandlerNativeHandle!));

      final irisEvent =
          (provider.provideIrisEvent() ?? IrisEventIO()) as IrisEventIO;
      irisEvent.dispose();
    } finally {
      _closeOnExitPort();
    }
  }

  VoidCallback addHotRestartListener(HotRestartListener listener) {
    assert(() {
      final Object? debugCheckForReturnedFuture = listener as dynamic;
      if (debugCheckForReturnedFuture is Future) {
        throw UnsupportedError(
            'HotRestartListener must be a void method without an `async` keyword.');
      }
      return true;
    }());

    _hotRestartListeners.add(listener);
    return () {
      removeHotRestartListener(listener);
    };
  }

  void removeHotRestartListener(HotRestartListener listener) {
    _hotRestartListeners.remove(listener);
  }

  void dispose() {
    _hotRestartListeners.clear();
  }
}

/// Extension functions of `PlatformBindingsDelegateInterfaceIO`
extension PlatformBindingsDelegateInterfaceIOExt
    on PlatformBindingsDelegateInterface {
  CallApiResult invokeMethod(
    IrisApiEngineHandle irisApiEnginePtr,
    IrisMethodCall methodCall,
  ) {
    return using<CallApiResult>((Arena arena) {
      final funcName = methodCall.funcName;
      final params = methodCall.params;
      final buffers = methodCall.buffers;
      final rawBufferParams = methodCall.rawBufferParams;
      assert(!(buffers != null && rawBufferParams != null));

      List<BufferParam>? bufferParamList = [];

      if (buffers != null) {
        for (int i = 0; i < buffers.length; i++) {
          final buffer = buffers[i];
          if (buffer.isEmpty) {
            bufferParamList.add(const BufferParam(BufferParamHandle(0), 0));
            continue;
          }
          final ffi.Pointer<ffi.Uint8> bufferData =
              arena.allocate<ffi.Uint8>(buffer.length);

          final pointerList = bufferData.asTypedList(buffer.length);
          pointerList.setAll(0, buffer);

          bufferParamList.add(BufferParam(
              BufferParamHandle(bufferData.address), buffer.length));
        }
      } else {
        bufferParamList = rawBufferParams;
      }

      final ffi.Pointer<ffi.Int8> resultPointer =
          arena.allocate<ffi.Int8>(kBasicResultLength);

      final ffi.Pointer<ffi.Int8> funcNamePointer =
          funcName.toNativeUtf8(allocator: arena).cast();

      final ffi.Pointer<Utf8> paramsPointerUtf8 =
          params.toNativeUtf8(allocator: arena);
      final paramsPointerUtf8Length = paramsPointerUtf8.length;
      final ffi.Pointer<ffi.Int8> paramsPointer = paramsPointerUtf8.cast();

      ffi.Pointer<ffi.Pointer<ffi.Void>> bufferListPtr;
      ffi.Pointer<ffi.Uint32> bufferListLengthPtr = ffi.nullptr;
      final bufferLengthLength = bufferParamList?.length ?? 0;

      if (bufferParamList != null) {
        bufferListPtr =
            arena.allocate(bufferParamList.length * ffi.sizeOf<ffi.Uint64>());

        for (int i = 0; i < bufferParamList.length; i++) {
          final bufferParam = bufferParamList[i];
          bufferListPtr[i] =
              ffi.Pointer.fromAddress(bufferParam.intPtr() as int);
        }
      } else {
        bufferListPtr = ffi.nullptr;
        bufferListLengthPtr = ffi.nullptr;
      }

      try {
        final apiParam = arena<iris.ApiParam>()
          ..ref.event = funcNamePointer
          ..ref.data = paramsPointer
          ..ref.data_size = paramsPointerUtf8Length
          ..ref.result = resultPointer
          ..ref.buffer = bufferListPtr
          ..ref.length = bufferListLengthPtr
          ..ref.buffer_count = bufferLengthLength;

        final irisReturnCode = callApi(
          methodCall,
          irisApiEnginePtr,
          IrisApiParamHandle(apiParam),
        );

        if (irisReturnCode != 0) {
          return CallApiResult(irisReturnCode: irisReturnCode, data: const {});
        }

        final result = resultPointer.cast<Utf8>().toDartString();

        final resultMap = Map<String, dynamic>.from(jsonDecode(result));

        return CallApiResult(
          irisReturnCode: irisReturnCode,
          data: resultMap,
          rawData: result,
        );
      } catch (e) {
        debugPrint('[_ApiCallExecutor] $funcName, params: $params\nerror: $e');
        return CallApiResult(irisReturnCode: -1, data: const {});
      }
    });
  }
}

class _IrisMethodChannelNative {
  _IrisMethodChannelNative(this._nativeIrisApiEngineBinding, this._irisEvent);
  final PlatformBindingsDelegateInterface _nativeIrisApiEngineBinding;

  ffi.Pointer<ffi.Void>? _irisApiEnginePtr;
  int get irisApiEngineNativeHandle {
    assert(_irisApiEnginePtr != null);
    return _irisApiEnginePtr!.address;
  }

  final IrisEventIO _irisEvent;
  ffi.Pointer<iris.IrisCEventHandler>? _irisCEventHandler;
  int get irisCEventHandlerNativeHandle {
    assert(_irisCEventHandler != null);
    return _irisCEventHandler!.address;
  }

  ffi.Pointer<ffi.Void>? _irisEventHandler;
  int get irisEventHandlerNativeHandle {
    assert(_irisEventHandler != null);
    return _irisEventHandler!.address;
  }

  int _nativeSessionId = 0;
  int get nativeSessionId => _nativeSessionId;
  SendPort? _eventSendPort;
  bool _irisEventInitialized = false;
  bool _eventHandlerRegistered = false;

  CreateApiEngineResult initilize(SendPort sendPort,
      List<InitilizationArgProvider> args, int requestedNativeSessionId) {
    _eventSendPort = sendPort;
    try {
      _irisEvent.initialize();
      _irisEventInitialized = true;
      _irisEvent.registerEventHandler(sendPort);
      _eventHandlerRegistered = true;

      _nativeIrisApiEngineBinding.initialize();
      final createResult = _nativeIrisApiEngineBinding.createApiEngine(args);
      _irisApiEnginePtr = createResult.apiEnginePtr() as ffi.Pointer<ffi.Void>?;
      if (_irisApiEnginePtr == null || _irisApiEnginePtr == ffi.nullptr) {
        throw StateError('Failed to create the native Iris API engine.');
      }

      _irisCEventHandler = calloc<iris.IrisCEventHandler>()
        ..ref.OnEvent = _irisEvent.onEventPtr.cast();

      _irisEventHandler = _nativeIrisApiEngineBinding.createIrisEventHandler(
              IrisCEventHandlerHandle(_irisCEventHandler!))()
          as ffi.Pointer<ffi.Void>?;
      if (_irisEventHandler == null || _irisEventHandler == ffi.nullptr) {
        throw StateError('Failed to create the native Iris event handler.');
      }

      final nativeBinding = _nativeIrisApiEngineBinding;
      if (requestedNativeSessionId != 0 &&
          nativeBinding is NativeCleanupCallbackProvider) {
        final cleanupCallbacks = nativeBinding as NativeCleanupCallbackProvider;
        _nativeSessionId = _irisEvent.createNativeSession(
          nativeSessionId: requestedNativeSessionId,
          irisApiEngineAddress: _irisApiEnginePtr!.address,
          irisEventHandlerAddress: _irisEventHandler!.address,
          irisCEventHandlerAddress: _irisCEventHandler!.address,
          destroyNativeApiEngineAddress:
              cleanupCallbacks.destroyNativeApiEngineAddress,
          destroyIrisEventHandlerAddress:
              cleanupCallbacks.destroyIrisEventHandlerAddress,
        );
        if (_nativeSessionId == 0) {
          throw StateError(
              'Failed to attach the reserved native Iris session.');
        }
      }

      return createResult;
    } catch (_) {
      _disposeDirectNativeResources();
      rethrow;
    }
  }

  void _disposeDirectNativeResources() {
    final eventSendPort = _eventSendPort;
    if (_eventHandlerRegistered && eventSendPort != null) {
      try {
        _irisEvent.unregisterEventHandler(eventSendPort);
      } catch (e) {
        debugPrint('Failed to unregister Iris Dart port: $e');
      }
      _eventHandlerRegistered = false;
    }

    final apiEnginePtr = _irisApiEnginePtr;
    if (apiEnginePtr != null && apiEnginePtr != ffi.nullptr) {
      _nativeIrisApiEngineBinding
          .destroyNativeApiEngine(IrisApiEngineHandle(apiEnginePtr));
      _irisApiEnginePtr = null;
    }

    final irisEventHandler = _irisEventHandler;
    if (irisEventHandler != null && irisEventHandler != ffi.nullptr) {
      _nativeIrisApiEngineBinding
          .destroyIrisEventHandler(IrisEventHandlerHandle(irisEventHandler));
      _irisEventHandler = null;
    }

    final irisCEventHandler = _irisCEventHandler;
    if (irisCEventHandler != null) {
      calloc.free(irisCEventHandler);
      _irisCEventHandler = null;
    }

    if (_irisEventInitialized) {
      _irisEvent.dispose();
      _irisEventInitialized = false;
    }
    _eventSendPort = null;
  }

  CallApiResult _invokeMethod(IrisMethodCall methodCall) {
    assert(_irisApiEnginePtr != null, 'Make sure initilize() has been called.');

    final nativeSessionId = _nativeSessionId;
    if (nativeSessionId != 0 &&
        !_irisEvent.acquireNativeSession(nativeSessionId)) {
      return CallApiResult(
        irisReturnCode: kDisposedIrisMethodCallReturnCode,
        data: kDisposedIrisMethodCallData,
      );
    }

    try {
      return _nativeIrisApiEngineBinding.invokeMethod(
          IrisApiEngineHandle(_irisApiEnginePtr!), methodCall);
    } finally {
      if (nativeSessionId != 0) {
        _irisEvent.releaseNativeSession(nativeSessionId);
      }
    }
  }

  CallApiResult invokeMethod(IrisMethodCall methodCall) {
    return _invokeMethod(methodCall);
  }

  void dispose() {
    assert(_irisApiEnginePtr != null);

    if (_nativeSessionId != 0) {
      _irisEvent.destroyNativeSession(_nativeSessionId);
      _nativeSessionId = 0;
      _irisApiEnginePtr = null;
      _irisEventHandler = null;
      _irisCEventHandler = null;
      _eventHandlerRegistered = false;
      _irisEventInitialized = false;
      _eventSendPort = null;
      return;
    }
    _disposeDirectNativeResources();
  }

  CallApiResult createNativeEventHandler(IrisMethodCall methodCall) {
    final eventHandlerIntPtr = _irisEventHandler!.address;
    final result = _invokeMethod(IrisMethodCall(
      methodCall.funcName,
      methodCall.params,
      rawBufferParams: [BufferParam(BufferParamHandle(eventHandlerIntPtr), 1)],
    ));
    result.data['observerIntPtr'] = IrisEventHandlerHandle(eventHandlerIntPtr);
    return result;
  }

  CallApiResult destroyNativeEventHandler(IrisMethodCall methodCall) {
    assert(methodCall.rawBufferParams != null);
    assert(methodCall.rawBufferParams!.length == 1);

    CallApiResult result;
    if (methodCall.funcName.isEmpty) {
      result = CallApiResult(irisReturnCode: 0, data: {'result': 0});
    } else {
      result = _invokeMethod(methodCall);
    }

    return result;
  }
}

class IrisMethodChannelInternalIO implements IrisMethodChannelInternal {
  IrisMethodChannelInternalIO(this._nativeBindingsProvider);

  final PlatformBindingsProvider _nativeBindingsProvider;

  bool _initilized = false;
  late _Messenger _messenger;
  late StreamSubscription _evntSubscription;
  // @visibleForTesting
  // final ScopedObjects scopedEventHandlers = ScopedObjects();
  late int _nativeHandle;

  IrisEventMessageListener? _irisEventMessageListener;

  @visibleForTesting
  late Isolate workerIsolate;
  late _HotRestartFinalizer _hotRestartFinalizer;

  AsyncMemoizer? _initializeCallOnce;

  static Future<void> _execute(_InitilizationArgs args) async {
    final SendPort mainApiCallSendPort = args.apiCallPortSendPort;
    final SendPort mainEventSendPort = args.eventPortSendPort;
    final SendPort? onExitSendPort = args.onExitSendPort;
    final PlatformBindingsProvider provider = args.provider;

    final apiCallPort = ReceivePort();

    final nativeBindingDelegate = provider.provideNativeBindingDelegate();

    final IrisEvent irisEvent = provider.provideIrisEvent() ?? IrisEventIO();
    // assert(irisEvent != null);

    // final irisEvent = provider.provideIrisEvent();

    final _IrisMethodChannelNative executor = _IrisMethodChannelNative(
        nativeBindingDelegate, irisEvent as IrisEventIO);
    late CreateApiEngineResult executorInitilizationResult;
    try {
      executorInitilizationResult = executor.initilize(
          mainEventSendPort, args.argNativeHandles, args.nativeSessionId);
    } catch (e, s) {
      mainApiCallSendPort.send(_InitilizationFailure('$e', '$s'));
      Isolate.exit(onExitSendPort, 0);
    }

    int? debugIrisCEventHandlerNativeHandle;
    int? debugIrisEventHandlerNativeHandle;

    assert(() {
      debugIrisCEventHandlerNativeHandle =
          executor.irisCEventHandlerNativeHandle;
      debugIrisEventHandlerNativeHandle = executor.irisEventHandlerNativeHandle;

      return true;
    }());

    final InitilizationResult initilizationResponse = InitilizationResultIO(
      apiCallPort.sendPort,
      executor.irisApiEngineNativeHandle,
      executor.nativeSessionId,
      executorInitilizationResult.extraData,
      debugIrisCEventHandlerNativeHandle,
      debugIrisEventHandlerNativeHandle,
    );

    mainApiCallSendPort.send(initilizationResponse);

    var exitCode = 0;
    // Wait for messages from the main isolate.
    await for (final request in apiCallPort) {
      if (request == null) {
        try {
          executor.dispose();
          mainApiCallSendPort.send(null);
        } catch (e, s) {
          exitCode = 1;
          mainApiCallSendPort.send(_DisposeFailure('$e', '$s'));
        }
        // Ready exit the isolate.
        break;
      }

      assert(request is Request);

      if (request is ApiCallRequest) {
        final result = executor.invokeMethod(request.methodCall);

        mainApiCallSendPort.send(result);
      } else if (request is ApiCallListRequest) {
        final results = <CallApiResult>[];
        for (final methodCall in request.methodCalls) {
          final result = executor.invokeMethod(methodCall);
          results.add(result);
        }

        mainApiCallSendPort.send(results);
      } else if (request is CreateNativeEventHandlerRequest) {
        final result = executor.createNativeEventHandler(request.methodCall);
        mainApiCallSendPort.send(result);
      } else if (request is CreateNativeEventHandlerListRequest) {
        final results = <CallApiResult>[];
        for (final methodCall in request.methodCalls) {
          final result = executor.createNativeEventHandler(methodCall);
          results.add(result);
        }

        mainApiCallSendPort.send(results);
      } else if (request is DestroyNativeEventHandlerRequest) {
        final result = executor.destroyNativeEventHandler(request.methodCall);
        mainApiCallSendPort.send(result);
      } else if (request is DestroyNativeEventHandlerListRequest) {
        final results = <CallApiResult>[];
        for (final methodCall in request.methodCalls) {
          final result = executor.destroyNativeEventHandler(methodCall);
          results.add(result);
        }

        mainApiCallSendPort.send(results);
      }
    }

    Isolate.exit(onExitSendPort, exitCode);
  }

  @override
  Future<InitilizationResult?> initilize(
    List<InitilizationArgProvider> args, {
    int nativeSessionId = 0,
  }) async {
    if (_initilized) {
      return null;
    }

    late InitilizationResultIO initilizationResult;
    _initializeCallOnce ??= AsyncMemoizer();
    try {
      await _initializeCallOnce!.runOnce(() async {
        final apiCallPort = ReceivePort();
        final eventPort = ReceivePort();

        _hotRestartFinalizer = _HotRestartFinalizer(_nativeBindingsProvider);

        workerIsolate = await Isolate.spawn(
          _execute,
          _InitilizationArgs(
            apiCallPort.sendPort,
            eventPort.sendPort,
            _hotRestartFinalizer.onExitSendPort,
            _nativeBindingsProvider,
            args,
            nativeSessionId,
          ),
          onExit: _hotRestartFinalizer.onExitSendPort,
        );

        final responseQueue = StreamQueue<dynamic>(apiCallPort);

        final msg = await responseQueue.next;
        if (msg is _InitilizationFailure) {
          await responseQueue.cancel();
          eventPort.close();
          throw StateError(
              'Native Iris initialization failed: ${msg.error}\n${msg.stackTrace}');
        }
        assert(msg is InitilizationResult);
        initilizationResult = msg as InitilizationResultIO;
        final requestPort = initilizationResult._apiCallPortSendPort;
        _nativeHandle = initilizationResult.irisApiEngineNativeHandle;
        _hotRestartFinalizer.nativeSessionId =
            initilizationResult.nativeSessionId;

        assert(() {
          _hotRestartFinalizer.debugIrisApiEngineNativeHandle =
              initilizationResult.irisApiEngineNativeHandle;
          _hotRestartFinalizer.debugIrisCEventHandlerNativeHandle =
              initilizationResult._debugIrisCEventHandlerNativeHandle;
          _hotRestartFinalizer.debugIrisEventHandlerNativeHandle =
              initilizationResult._debugIrisEventHandlerNativeHandle;

          return true;
        }());

        _messenger = _Messenger(requestPort, responseQueue);

        _evntSubscription = eventPort.listen((message) {
          if (!_initilized) {
            return;
          }

          final eventMessage = parseMessage(message);

          _irisEventMessageListener?.call(eventMessage);
        });

        _initilized = true;
      });
    } catch (_) {
      _initializeCallOnce = null;
      rethrow;
    }

    return initilizationResult;
  }

  @override
  Future<void> dispose() async {
    if (!_initilized) {
      _initializeCallOnce = null;
      return;
    }
    _initilized = false;
    _irisEventMessageListener = null;
    _hotRestartFinalizer.dispose();

    Object? firstError;
    StackTrace? firstStackTrace;
    try {
      await _evntSubscription.cancel();
    } catch (e, s) {
      firstError = e;
      firstStackTrace = s;
    }
    try {
      await _messenger.dispose();
    } catch (e, s) {
      firstError ??= e;
      firstStackTrace ??= s;
    } finally {
      _initializeCallOnce = null;
    }

    if (firstError != null) {
      await Future<void>.error(firstError, firstStackTrace);
    }
  }

  @override
  VoidCallback addHotRestartListener(HotRestartListener listener) {
    return _hotRestartFinalizer.addHotRestartListener(listener);
  }

  @override
  void removeHotRestartListener(HotRestartListener listener) {
    _hotRestartFinalizer.removeHotRestartListener(listener);
  }

  @override
  Future<CallApiResult> execute(Request request) {
    return _messenger.send(request);
  }

  @override
  int getApiEngineHandle() {
    if (!_initilized) {
      return 0;
    }

    return _nativeHandle;
  }

  @override
  Future<List<CallApiResult>> listExecute(Request request) {
    return _messenger.listSend(request);
  }

  @override
  void setIrisEventMessageListener(IrisEventMessageListener listener) {
    _irisEventMessageListener = listener;
  }
}

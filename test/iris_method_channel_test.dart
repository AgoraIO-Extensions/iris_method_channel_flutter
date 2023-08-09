import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart' show StandardMethodCodec, MethodCall;
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_method_channel/src/bindings/native_iris_api_common_bindings.dart';
import 'package:iris_method_channel/src/bindings/native_iris_event_bindings.dart'
    as iris_event;
import 'package:iris_method_channel/src/iris_event.dart';
import 'package:iris_method_channel/src/iris_method_channel.dart';
import 'package:iris_method_channel/src/native_bindings_delegate.dart';
import 'package:iris_method_channel/src/scoped_objects.dart';

class _ApiParam {
  _ApiParam(this.event, this.data);
  final String event;
  final String data;
}

class _CallApiRecord {
  _CallApiRecord(this.methodCall, this.apiParam);
  final IrisMethodCall methodCall;
  final _ApiParam apiParam;
}

class _FakeNativeBindingDelegateMessenger {
  _FakeNativeBindingDelegateMessenger() {
    apiCallPort.listen((message) {
      assert(message is _CallApiRecord);
      callApiRecords.add(message);
    });
  }
  final apiCallPort = ReceivePort();
  final callApiRecords = <_CallApiRecord>[];

  SendPort getSendPort() => apiCallPort.sendPort;
}

class _FakeNativeBindingDelegate extends NativeBindingDelegate {
  _FakeNativeBindingDelegate(this.apiCallPortSendPort);

  final SendPort apiCallPortSendPort;

  void _response(ffi.Pointer<ApiParam> param, Map<String, Object> result) {
    using<void>((Arena arena) {
      final ffi.Pointer<Utf8> resultMapPointerUtf8 =
          jsonEncode(result).toNativeUtf8(allocator: arena);
      final ffi.Pointer<ffi.Int8> resultMapPointerInt8 =
          resultMapPointerUtf8.cast();

      for (int i = 0; i < kBasicResultLength; i++) {
        if (i >= resultMapPointerUtf8.length) {
          break;
        }

        param.ref.result[i] = resultMapPointerInt8[i];
      }
    });
  }

  @override
  int callApi(IrisMethodCall methodCall, ffi.Pointer<ffi.Void> apiEnginePtr,
      ffi.Pointer<ApiParam> param) {
    final record = _CallApiRecord(
      methodCall,
      _ApiParam(
        param.ref.event.cast<Utf8>().toDartString(),
        param.ref.data.cast<Utf8>().toDartString(),
      ),
    );
    apiCallPortSendPort.send(record);

    _response(param, {});

    return 0;
  }

  @override
  ffi.Pointer<ffi.Void> createIrisEventHandler(
      ffi.Pointer<IrisCEventHandler> eventHandler) {
    final record = _CallApiRecord(
      const IrisMethodCall('createIrisEventHandler', '{}'),
      _ApiParam(
        'createIrisEventHandler',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
    return ffi.Pointer<ffi.Void>.fromAddress(123456);
  }

  @override
  CreateNativeApiEngineResult createNativeApiEngine(
      List<ffi.Pointer<ffi.Void>> args) {
    return CreateNativeApiEngineResult(
      ffi.Pointer<ffi.Void>.fromAddress(100),
      extraData: <String, Object>{'extra_handle': 1000},
    );
  }

  @override
  void destroyIrisEventHandler(ffi.Pointer<ffi.Void> handler) {
    final record = _CallApiRecord(
      const IrisMethodCall('destroyIrisEventHandler', '{}'),
      _ApiParam(
        'destroyIrisEventHandler',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  void destroyNativeApiEngine(ffi.Pointer<ffi.Void> apiEnginePtr) {
    final record = _CallApiRecord(
      const IrisMethodCall('destroyNativeApiEngine', '{}'),
      _ApiParam(
        'destroyNativeApiEngine',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  void initialize() {
    final record = _CallApiRecord(
      const IrisMethodCall('initialize', '{}'),
      _ApiParam(
        'initialize',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }
}

class _FakeIrisEvent implements IrisEvent {
  _FakeIrisEvent(this.apiCallPortSendPort);

  final SendPort apiCallPortSendPort;

  @override
  void initialize() {
    final record = _CallApiRecord(
      const IrisMethodCall('IrisEvent_initialize', '{}'),
      _ApiParam(
        'IrisEvent_initialize',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  void registerEventHandler(SendPort sendPort) {
    final record = _CallApiRecord(
      const IrisMethodCall('IrisEvent_registerEventHandler', '{}'),
      _ApiParam(
        'IrisEvent_registerEventHandler',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  void unregisterEventHandler(SendPort sendPort) {
    final record = _CallApiRecord(
      const IrisMethodCall('IrisEvent_unregisterEventHandler', '{}'),
      _ApiParam(
        'IrisEvent_unregisterEventHandler',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  void dispose() {
    final record = _CallApiRecord(
      const IrisMethodCall('IrisEvent_dispose', '{}'),
      _ApiParam(
        'IrisEvent_dispose',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  ffi.Pointer<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Pointer<iris_event.EventParam> p1)>>
      get onEventPtr => ffi.Pointer<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Pointer<iris_event.EventParam> p1)>>.fromAddress(0);
}

class _FakeNativeBindingDelegateProvider extends NativeBindingsProvider {
  _FakeNativeBindingDelegateProvider(
      this.nativeBindingDelegate, this.irisEvent);

  final NativeBindingDelegate nativeBindingDelegate;
  final IrisEvent irisEvent;

  @override
  NativeBindingDelegate provideNativeBindingDelegate() {
    return nativeBindingDelegate;
  }

  @override
  IrisEvent provideIrisEvent() {
    return irisEvent;
  }
}

class _TestEventLoopEventHandler extends EventLoopEventHandler {
  @override
  bool handleEventInternal(
      String eventName, String eventData, List<Uint8List> buffers) {
    return true;
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeNativeBindingDelegateMessenger messenger;
  late NativeBindingsProvider nativeBindingsProvider;
  late IrisMethodChannel irisMethodChannel;

  setUp(() {
    messenger = _FakeNativeBindingDelegateMessenger();
    final _FakeNativeBindingDelegate nativeBindingDelegate =
        _FakeNativeBindingDelegate(messenger.getSendPort());
    final _FakeIrisEvent irisEvent = _FakeIrisEvent(messenger.getSendPort());
    nativeBindingsProvider =
        _FakeNativeBindingDelegateProvider(nativeBindingDelegate, irisEvent);
    irisMethodChannel = IrisMethodChannel(nativeBindingsProvider);
  });

  group('Get InitilizationResult', () {
    test('able to get InitilizationResult from initilize', () async {
      final InitilizationResult? result = await irisMethodChannel.initilize([]);
      expect(result, isNotNull);

      expect(result!.irisApiEngineNativeHandle, 100);
      expect(result.extraData, {'extra_handle': 1000});

      await irisMethodChannel.dispose();
    });

    test('get null InitilizationResult if initilize multiple times', () async {
      await irisMethodChannel.initilize([]);

      final InitilizationResult? result = await irisMethodChannel.initilize([]);
      expect(result, isNull);

      await irisMethodChannel.dispose();
    });
  });

  test(
      'able to initilize/dispose multiple times for same IrisMethodChannel object',
      () async {
    await irisMethodChannel.initilize([]);
    final callApiResult1 = await irisMethodChannel
        .invokeMethod(const IrisMethodCall('a_func_name', 'params'));
    expect(callApiResult1.irisReturnCode, 0);
    expect(callApiResult1.data, {});

    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name');
    expect(callRecord1.length, 1);

    await irisMethodChannel.dispose();

    await irisMethodChannel.initilize([]);
    final callApiResult2 = await irisMethodChannel
        .invokeMethod(const IrisMethodCall('a_func_name2', 'params'));
    expect(callApiResult2.irisReturnCode, 0);
    expect(callApiResult2.data, {});

    final callRecord2 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name2');
    expect(callRecord2.length, 1);

    await irisMethodChannel.dispose();
  });

  test('invokeMethod', () async {
    await irisMethodChannel.initilize([]);
    final callApiResult = await irisMethodChannel
        .invokeMethod(const IrisMethodCall('a_func_name', 'params'));
    expect(callApiResult.irisReturnCode, 0);
    expect(callApiResult.data, {});

    await irisMethodChannel.dispose();
  });

  test('invokeMethodList', () async {
    await irisMethodChannel.initilize([]);
    const methodCalls = [
      IrisMethodCall('a_func_name', 'params'),
      IrisMethodCall('a_func_name2', 'params')
    ];
    final callApiResult = await irisMethodChannel.invokeMethodList(methodCalls);

    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name');
    expect(callRecord1.length, 1);

    final callRecord2 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name2');
    expect(callRecord2.length, 1);

    expect(callApiResult[0].irisReturnCode, 0);
    expect(callApiResult[0].data, {});

    expect(callApiResult[1].irisReturnCode, 0);
    expect(callApiResult[1].data, {});

    await irisMethodChannel.dispose();
  });

  test('registerEventHandler', () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));

    final DisposableScopedObjects subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key)!;
    expect(subScopedObjects.keys.length, 1);

    final holder = subScopedObjects.values.elementAt(0) as EventHandlerHolder;

    expect(holder.nativeEventHandlerIntPtr, 123456);

    expect(holder.getEventHandlers().length, 1);
    expect(holder.getEventHandlers().elementAt(0), eventHandler);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'registerEventHandler');
    expect(registerEventHandlerCallRecord.length, 1);

    await irisMethodChannel.dispose();
  });

  test('unregisterEventHandler', () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));
    await irisMethodChannel.unregisterEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));

    final DisposableScopedObjects subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key)!;
    expect(subScopedObjects.keys.length, 1);

    final EventHandlerHolder holder =
        subScopedObjects.values.elementAt(0) as EventHandlerHolder;
    expect(holder.getEventHandlers().length, 0);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(registerEventHandlerCallRecord.length, 1);

    await irisMethodChannel.dispose();
  });

  test('unregisterEventHandlers', () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));
    await irisMethodChannel.unregisterEventHandlers(key);

    final DisposableScopedObjects? subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key);
    expect(subScopedObjects, isNull);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(registerEventHandlerCallRecord.length, 1);

    await irisMethodChannel.dispose();
  });

  test('disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    // Wait for `dispose` completed.
    await Future.delayed(const Duration(milliseconds: 500));
    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'destroyNativeApiEngine');
    expect(callRecord1.length, 1);

    final callRecord2 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'destroyIrisEventHandler');
    expect(callRecord2.length, 1);
  });

  test('disposed multiple times', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    await irisMethodChannel.dispose();
    // Wait for `dispose` completed.
    await Future.delayed(const Duration(milliseconds: 500));
    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'destroyNativeApiEngine');
    expect(callRecord1.length, 1);

    final callRecord2 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'destroyIrisEventHandler');
    expect(callRecord2.length, 1);
  });

  test('disposed after receive onDetachedFromEngine_fromPlatform', () async {
    await irisMethodChannel.initilize([]);

    // Simulate the `MethodChannel` call from native side
    const StandardMethodCodec codec = StandardMethodCodec();
    final ByteData data = codec.encodeMethodCall(const MethodCall(
      'onDetachedFromEngine_fromPlatform',
    ));
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'iris_method_channel',
      data,
      (ByteData? data) {},
    );

    // Wait for the `iris_method_channel` method channel call completed.
    await Future.delayed(const Duration(milliseconds: 1000));

    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'destroyNativeApiEngine');
    expect(callRecord1.length, 1);

    final callRecord2 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'destroyIrisEventHandler');
    expect(callRecord2.length, 1);
  });

  test('invokeMethod after disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    final callApiResult = await irisMethodChannel
        .invokeMethod(const IrisMethodCall('a_func_name', 'params'));
    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name');
    expect(callRecord1.length, 0);

    expect(callApiResult.irisReturnCode, kDisposedIrisMethodCallReturnCode);
    expect(callApiResult.data, kDisposedIrisMethodCallData);
  });

  test('invokeMethodList after disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    const methodCalls = [
      IrisMethodCall('a_func_name', 'params'),
      IrisMethodCall('a_func_name2', 'params')
    ];

    final callApiResult = await irisMethodChannel.invokeMethodList(methodCalls);

    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name');
    expect(callRecord1.length, 0);

    final callRecord2 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name2');
    expect(callRecord2.length, 0);

    expect(callApiResult[0].irisReturnCode, kDisposedIrisMethodCallReturnCode);
    expect(callApiResult[0].data, kDisposedIrisMethodCallData);

    expect(callApiResult[1].irisReturnCode, kDisposedIrisMethodCallReturnCode);
    expect(callApiResult[1].data, kDisposedIrisMethodCallData);
  });

  test('registerEventHandler after disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));

    final DisposableScopedObjects? subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key);
    expect(subScopedObjects, isNull);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'registerEventHandler');
    expect(registerEventHandlerCallRecord.length, 0);
  });

  test('unregisterEventHandler after disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));
    await irisMethodChannel.unregisterEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));

    final DisposableScopedObjects? subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key);
    expect(subScopedObjects, isNull);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(registerEventHandlerCallRecord.length, 0);
  });

  test('unregisterEventHandlers after disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));
    await irisMethodChannel.unregisterEventHandlers(key);

    final DisposableScopedObjects? subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key);
    expect(subScopedObjects, isNull);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(registerEventHandlerCallRecord.length, 0);
  });

  test('registerEventHandler 2 times', () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler1 = _TestEventLoopEventHandler();
    final eventHandler2 = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler1),
        jsonEncode({}));
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler2),
        jsonEncode({}));

    final DisposableScopedObjects subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key)!;
    expect(subScopedObjects.keys.length, 1);

    final holder = subScopedObjects.values.elementAt(0) as EventHandlerHolder;

    expect(holder.nativeEventHandlerIntPtr, 123456);

    expect(holder.getEventHandlers().length, 2);
    expect(holder.getEventHandlers().elementAt(0), eventHandler1);
    expect(holder.getEventHandlers().elementAt(1), eventHandler2);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'registerEventHandler');
    expect(registerEventHandlerCallRecord.length, 1);

    await irisMethodChannel.dispose();
  });

  test('registerEventHandler 2 times with different registerName', () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler1 = _TestEventLoopEventHandler();
    final eventHandler2 = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler1),
        jsonEncode({}));
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler1',
            unregisterName: 'unregisterEventHandler1',
            handler: eventHandler2),
        jsonEncode({}));

    final DisposableScopedObjects subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key)!;
    expect(subScopedObjects.keys.length, 2);

    final holder = subScopedObjects.values.elementAt(0) as EventHandlerHolder;
    expect(holder.nativeEventHandlerIntPtr, 123456);

    expect(holder.getEventHandlers().length, 1);
    expect(holder.getEventHandlers().elementAt(0), eventHandler1);

    final holder2 = subScopedObjects.values.elementAt(1) as EventHandlerHolder;
    expect(holder2.nativeEventHandlerIntPtr, 123456);

    expect(holder2.getEventHandlers().length, 1);
    expect(holder2.getEventHandlers().elementAt(0), eventHandler2);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'registerEventHandler');
    expect(registerEventHandlerCallRecord.length, 1);

    final registerEventHandlerCallRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'registerEventHandler1');
    expect(registerEventHandlerCallRecord1.length, 1);

    await irisMethodChannel.dispose();
  });

  test('registerEventHandler 2 times, then unregisterEventHandler', () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler1 = _TestEventLoopEventHandler();
    final eventHandler2 = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler1),
        jsonEncode({}));
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler2),
        jsonEncode({}));

    await irisMethodChannel.unregisterEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler2),
        jsonEncode({}));

    final DisposableScopedObjects subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key)!;
    expect(subScopedObjects.keys.length, 1);

    final holder = subScopedObjects.values.elementAt(0) as EventHandlerHolder;

    expect(holder.nativeEventHandlerIntPtr, 123456);

    expect(holder.getEventHandlers().length, 1);
    expect(holder.getEventHandlers().elementAt(0), eventHandler1);

    final unregisterEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(unregisterEventHandlerCallRecord.length, 0);

    await irisMethodChannel.dispose();
  });

  test(
      'registerEventHandler 2 times with different registerName, then unregisterEventHandler',
      () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler1 = _TestEventLoopEventHandler();
    final eventHandler2 = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler1),
        jsonEncode({}));
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler1',
            unregisterName: 'unregisterEventHandler1',
            handler: eventHandler2),
        jsonEncode({}));

    await irisMethodChannel.unregisterEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler1',
            unregisterName: 'unregisterEventHandler1',
            handler: eventHandler2),
        jsonEncode({}));

    final DisposableScopedObjects subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key)!;
    expect(subScopedObjects.keys.length, 2);

    final holder = subScopedObjects.values.elementAt(0) as EventHandlerHolder;

    expect(holder.nativeEventHandlerIntPtr, 123456);

    expect(holder.getEventHandlers().length, 1);
    expect(holder.getEventHandlers().elementAt(0), eventHandler1);

    final holder2 = subScopedObjects.values.elementAt(1) as EventHandlerHolder;

    expect(holder2.getEventHandlers().length, 0);

    final unregisterEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler1');
    expect(unregisterEventHandlerCallRecord.length, 1);

    await irisMethodChannel.dispose();
  });

  test(
      'registerEventHandler 2 times with different registerName, then unregisterEventHandler, then unregisterEventHandlers',
      () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler1 = _TestEventLoopEventHandler();
    final eventHandler2 = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler1),
        jsonEncode({}));
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler1',
            unregisterName: 'unregisterEventHandler1',
            handler: eventHandler2),
        jsonEncode({}));

    await irisMethodChannel.unregisterEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler1',
            unregisterName: 'unregisterEventHandler1',
            handler: eventHandler2),
        jsonEncode({}));

    await irisMethodChannel.unregisterEventHandlers(key);

    final DisposableScopedObjects? subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key);
    expect(subScopedObjects, isNull);

    final unregisterEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(unregisterEventHandlerCallRecord.length, 1);

    final unregisterEventHandlerCallRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler1');
    expect(unregisterEventHandlerCallRecord1.length, 1);

    await irisMethodChannel.dispose();
  });

  test(
      'registerEventHandler 2 times with different registerName, then unregisterEventHandler without await, then unregisterEventHandlers',
      () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler1 = _TestEventLoopEventHandler();
    final eventHandler2 = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler1),
        jsonEncode({}));
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler1',
            unregisterName: 'unregisterEventHandler1',
            handler: eventHandler2),
        jsonEncode({}));

    irisMethodChannel.unregisterEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler1',
            unregisterName: 'unregisterEventHandler1',
            handler: eventHandler2),
        jsonEncode({}));

    await irisMethodChannel.unregisterEventHandlers(key);

    final DisposableScopedObjects? subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key);
    expect(subScopedObjects, isNull);

    final unregisterEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(unregisterEventHandlerCallRecord.length, 1);

    final unregisterEventHandlerCallRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler1');
    expect(unregisterEventHandlerCallRecord1.length, 1);

    await irisMethodChannel.dispose();
  });

  test(
      'registerEventHandler 2 times with different registerName, then unregisterEventHandler without await, then unregisterEventHandlers without await',
      () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler1 = _TestEventLoopEventHandler();
    final eventHandler2 = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler1),
        jsonEncode({}));
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler1',
            unregisterName: 'unregisterEventHandler1',
            handler: eventHandler2),
        jsonEncode({}));

    irisMethodChannel.unregisterEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler1',
            unregisterName: 'unregisterEventHandler1',
            handler: eventHandler2),
        jsonEncode({}));

    irisMethodChannel.unregisterEventHandlers(key);

    // Wait for `unregisterEventHandler/unregisterEventHandlers` completed.
    await Future.delayed(const Duration(milliseconds: 500));

    final unregisterEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(unregisterEventHandlerCallRecord.length, 1);

    final unregisterEventHandlerCallRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler1');
    expect(unregisterEventHandlerCallRecord1.length, 1);

    await irisMethodChannel.dispose();
  });

  test('registerEventHandler 2 times, then unregisterEventHandlers', () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler1 = _TestEventLoopEventHandler();
    final eventHandler2 = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler1),
        jsonEncode({}));
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler2),
        jsonEncode({}));

    await irisMethodChannel.unregisterEventHandlers(key);

    final DisposableScopedObjects? subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key);
    expect(subScopedObjects, isNull);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(registerEventHandlerCallRecord.length, 2);

    await irisMethodChannel.dispose();
  });

  test(
      'registerEventHandler 2 times with different registerName, then unregisterEventHandlers',
      () async {
    await irisMethodChannel.initilize([]);

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler1 = _TestEventLoopEventHandler();
    final eventHandler2 = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler1),
        jsonEncode({}));
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler1',
            unregisterName: 'unregisterEventHandler1',
            handler: eventHandler2),
        jsonEncode({}));

    await irisMethodChannel.unregisterEventHandlers(key);

    final DisposableScopedObjects? subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key);
    expect(subScopedObjects, isNull);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(registerEventHandlerCallRecord.length, 1);

    final registerEventHandlerCallRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler1');
    expect(registerEventHandlerCallRecord1.length, 1);

    await irisMethodChannel.dispose();
  });

  test('Should clean native resources when hot restart happen', () async {
    await irisMethodChannel.initilize([]);

    irisMethodChannel.workerIsolate.kill(priority: Isolate.immediate);
    // Delayed 1 second to ensure `irisMethodChannel.workerIsolate.kill` done
    await Future.delayed(const Duration(seconds: 1));

    final destroyNativeApiEngineCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'destroyNativeApiEngine');
    expect(destroyNativeApiEngineCallRecord.length, 1);

    final destroyIrisEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'destroyIrisEventHandler');
    expect(destroyIrisEventHandlerCallRecord.length, 1);

    final irisEventDisposeCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'IrisEvent_dispose');
    expect(irisEventDisposeCallRecord.length, 1);
  });

  test('addHotRestartListener', () async {
    await irisMethodChannel.initilize([]);

    bool hotRestartListenerCalled = false;
    irisMethodChannel.addHotRestartListener((message) {
      hotRestartListenerCalled = true;
    });
    irisMethodChannel.workerIsolate.kill(priority: Isolate.immediate);

    // Delayed 1 second to ensure `irisMethodChannel.workerIsolate.kill` done
    await Future.delayed(const Duration(seconds: 1));

    expect(hotRestartListenerCalled, true);
  });

  test('removeHotRestartListener', () async {
    await irisMethodChannel.initilize([]);

    bool hotRestartListenerCalled = false;
    // ignore: prefer_function_declarations_over_variables
    final listener = (message) {
      hotRestartListenerCalled = true;
    };
    irisMethodChannel.addHotRestartListener(listener);
    irisMethodChannel.removeHotRestartListener(listener);
    irisMethodChannel.workerIsolate.kill(priority: Isolate.immediate);

    // Delayed 1 second to ensure `irisMethodChannel.workerIsolate.kill` done
    await Future.delayed(const Duration(seconds: 1));

    expect(hotRestartListenerCalled, false);
  });

  test('removeHotRestartListener through returned VoidCallback', () async {
    await irisMethodChannel.initilize([]);

    bool hotRestartListenerCalled = false;
    // ignore: prefer_function_declarations_over_variables
    final listener = (message) {
      hotRestartListenerCalled = true;
    };
    final removeListener = irisMethodChannel.addHotRestartListener(listener);
    removeListener();
    irisMethodChannel.workerIsolate.kill(priority: Isolate.immediate);

    // Delayed 1 second to ensure `irisMethodChannel.workerIsolate.kill` done
    await Future.delayed(const Duration(seconds: 1));

    expect(hotRestartListenerCalled, false);
  });
}

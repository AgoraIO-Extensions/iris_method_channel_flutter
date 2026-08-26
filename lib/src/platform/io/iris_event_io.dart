import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'package:iris_method_channel/src/platform/io/bindings/native_iris_event_bindings.dart';
import 'package:iris_method_channel/src/platform/io/bindings/native_iris_session_bindings.dart';
import 'package:iris_method_channel/src/platform/iris_event_interface.dart';

const _libName = 'iris_method_channel';

ffi.DynamicLibrary _loadLib() {
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$_libName.dll');
  }

  if (Platform.isAndroid) {
    return ffi.DynamicLibrary.open('lib$_libName.so');
  }

  return ffi.DynamicLibrary.process();
}

/// [IrisEvent] implementation of `dart:io`
class IrisEventIO implements IrisEvent, NativeSessionLifecycle {
  /// Construct [IrisEventIO]
  IrisEventIO() {
    final dynamicLibrary = _loadLib();
    _nativeIrisEventBinding = NativeIrisEventBinding(dynamicLibrary);
    _nativeIrisSessionBinding = NativeIrisSessionBinding(dynamicLibrary);
  }

  late final NativeIrisEventBinding _nativeIrisEventBinding;
  late final NativeIrisSessionBinding _nativeIrisSessionBinding;
  SendPort? _eventSendPort;

  /// Initialize the [IrisEvent], which call `InitDartApiDL` directly
  void initialize() {
    _nativeIrisEventBinding.InitDartApiDL(ffi.NativeApi.initializeApiDLData);
  }

  /// Register dart [SendPort] to send the message from native
  void registerEventHandler(SendPort sendPort) {
    _nativeIrisEventBinding.RegisterDartPort(sendPort.nativePort);
    _eventSendPort = sendPort;
  }

  /// Unregister dart [SendPort] which used to send the message from native
  void unregisterEventHandler(SendPort sendPort) {
    _nativeIrisEventBinding.UnregisterDartPort(sendPort.nativePort);
    if (_eventSendPort == sendPort) {
      _eventSendPort = null;
    }
  }

  /// Clean up native resources
  void dispose() {
    _nativeIrisEventBinding.Dispose();
  }

  @override
  int createNativeSession({
    required int nativeSessionId,
    required int irisApiEngineAddress,
    required int irisEventHandlerAddress,
    required int irisCEventHandlerAddress,
    required int destroyNativeApiEngineAddress,
    required int destroyIrisEventHandlerAddress,
  }) {
    final eventSendPort = _eventSendPort;
    if (!Platform.isAndroid || nativeSessionId == 0 || eventSendPort == null) {
      return 0;
    }

    return _nativeIrisSessionBinding.createNativeSession(
      nativeSessionId: nativeSessionId,
      irisApiEngine: ffi.Pointer<ffi.Void>.fromAddress(irisApiEngineAddress),
      irisEventHandler:
          ffi.Pointer<ffi.Void>.fromAddress(irisEventHandlerAddress),
      irisCEventHandler:
          ffi.Pointer<ffi.Void>.fromAddress(irisCEventHandlerAddress),
      dartPort: eventSendPort.nativePort,
      destroyNativeApiEngineAddress: destroyNativeApiEngineAddress,
      destroyIrisEventHandlerAddress: destroyIrisEventHandlerAddress,
    );
  }

  @override
  bool acquireNativeSession(int sessionId) {
    return _nativeIrisSessionBinding.acquireNativeSession(sessionId);
  }

  @override
  void releaseNativeSession(int sessionId) {
    _nativeIrisSessionBinding.releaseNativeSession(sessionId);
  }

  @override
  void destroyNativeSession(int sessionId) {
    final result = _nativeIrisSessionBinding.destroyNativeSession(sessionId);
    if (result != 0) {
      throw StateError(
          'Failed to destroy Android native Iris session $sessionId: $result');
    }
    _eventSendPort = null;
  }

  @override
  void forceDestroyNativeSession(int sessionId) {
    final result =
        _nativeIrisSessionBinding.forceDestroyNativeSession(sessionId);
    if (result != 0) {
      throw StateError(
          'Failed to force destroy Android native Iris session $sessionId: $result');
    }
    _eventSendPort = null;
  }

  /// Get the onEvent function pointer from C
  ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<EventParam>)>>
      get onEventPtr => _nativeIrisEventBinding.addresses.OnEvent;
}

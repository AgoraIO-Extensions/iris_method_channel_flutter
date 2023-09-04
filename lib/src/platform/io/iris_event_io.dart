import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'package:iris_method_channel/src/platform/io/bindings/native_iris_event_bindings.dart';
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
class IrisEventIO implements IrisEvent {
  /// Construct [IrisEventIO]
  IrisEventIO() {
    _nativeIrisEventBinding = NativeIrisEventBinding(_loadLib());
  }

  late final NativeIrisEventBinding _nativeIrisEventBinding;

  /// Initialize the [IrisEvent], which call `InitDartApiDL` directly
  void initialize() {
    _nativeIrisEventBinding.InitDartApiDL(ffi.NativeApi.initializeApiDLData);
  }

  /// Register dart [SendPort] to send the message from native
  void registerEventHandler(SendPort sendPort) {
    _nativeIrisEventBinding.RegisterDartPort(sendPort.nativePort);
  }

  /// Unregister dart [SendPort] which used to send the message from native
  void unregisterEventHandler(SendPort sendPort) {
    _nativeIrisEventBinding.UnregisterDartPort(sendPort.nativePort);
  }

  /// Clean up native resources
  void dispose() {
    _nativeIrisEventBinding.Dispose();
  }

  /// Get the onEvent function pointer from C
  ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<EventParam>)>>
      get onEventPtr => _nativeIrisEventBinding.addresses.OnEvent;
}

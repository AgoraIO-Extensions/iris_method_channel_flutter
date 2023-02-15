import 'dart:ffi' as ffi;
import 'package:iris_method_channel/src/iris_event.dart';

import 'bindings/native_iris_api_common_bindings.dart' as iris;
import 'iris_method_channel.dart';

// ignore_for_file: public_member_api_docs

/// Unified interface for iris API engine.
/// The [NativeBindingDelegate] is running inside a seperate isolate which is
/// spawned by the main isolate, so you should not share any objects in this class.
abstract class NativeBindingDelegate {
  void initialize();

  ffi.Pointer<ffi.Void> createNativeApiEngine(List<ffi.Pointer<ffi.Void>> args);

  int callApi(
    IrisMethodCall methodCall,
    ffi.Pointer<ffi.Void> apiEnginePtr,
    ffi.Pointer<iris.ApiParam> param,
  );

  ffi.Pointer<ffi.Void> createIrisEventHandler(
    ffi.Pointer<iris.IrisCEventHandler> eventHandler,
  );

  void destroyIrisEventHandler(
    ffi.Pointer<ffi.Void> handler,
  );

  void destroyNativeApiEngine(ffi.Pointer<ffi.Void> apiEnginePtr);
}

/// A provider for provide the ffi bindings of native implementation(such like
/// [NativeBindingDelegate], [IrisEvent]), which is passed to the isolate, you
/// should not sotre any objects with type that [SendPort] not allowed.
abstract class NativeBindingsProvider {
  /// Provide the implementation of [NativeBindingDelegate].
  NativeBindingDelegate provideNativeBindingDelegate();

  /// Provide the implementation of [IrisEvent].
  IrisEvent provideIrisEvent() {
    return IrisEvent();
  }
}

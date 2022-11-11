import 'bindings/native_iris_api_rtm_engine_bindings.dart';
import 'dart:ffi' as ffi;

// ignore_for_file: public_member_api_docs

abstract class NativeBindingDelegate {
  void initialize();

  ffi.Pointer<ffi.Void> createNativeApiEngine(List<ffi.Pointer<ffi.Void>> args);

  int callApi(
    ffi.Pointer<ffi.Void> apiEnginePtr,
    ffi.Pointer<ApiParam> param,
  );

  ffi.Pointer<ffi.Void> createIrisEventHandler(
    ffi.Pointer<IrisCEventHandler> eventHandler,
  );

  void destroyIrisEventHandler(
    ffi.Pointer<ffi.Void> handler,
  );

  void destroyNativeApiEngine(ffi.Pointer<ffi.Void> apiEnginePtr);
}

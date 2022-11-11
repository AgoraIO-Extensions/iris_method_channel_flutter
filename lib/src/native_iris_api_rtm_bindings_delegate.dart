import 'dart:io';

import 'package:iris_method_channel/src/bindings/native_iris_api_rtm_engine_bindings.dart';

import 'dart:ffi' as ffi;

import 'native_bindings_delegate.dart';

// ignore_for_file: public_member_api_docs

const _libName = 'AgoraRtmWrapper';

ffi.DynamicLibrary _loadLib() {
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('AgoraRtmWrapper.dll');
  }

  if (Platform.isAndroid) {
    return ffi.DynamicLibrary.open("libAgoraRtmWrapper.so");
  }

  return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
}

class NativeIrisApiRtmBindingsDelegate extends NativeBindingDelegate {
  late final NativeIrisApiRtmEngineBinding _binding;

  @override
  void initialize() {
    _binding = NativeIrisApiRtmEngineBinding(_loadLib());
  }

  @override
  ffi.Pointer<ffi.Void> createNativeApiEngine(
      List<ffi.Pointer<ffi.Void>>? args) {
    ffi.Pointer<ffi.Void> enginePtr = ffi.nullptr;
    assert(() {
      if (args != null && args.isNotEmpty) {
        assert(args.length == 1);
        enginePtr = args[0];
      }
      return true;
    }());

    return _binding.CreateIrisRtmEngine(enginePtr);
  }

  @override
  int callApi(
    ffi.Pointer<ffi.Void> apiEnginePtr,
    ffi.Pointer<ApiParam> param,
  ) {
    return _binding.CallIrisRtmApi(apiEnginePtr, param);
  }

  @override
  ffi.Pointer<ffi.Void> createIrisEventHandler(
    ffi.Pointer<IrisCEventHandler> eventHandler,
  ) {
    return _binding.CreateIrisEventHandler(eventHandler);
  }

  @override
  void destroyIrisEventHandler(
    ffi.Pointer<ffi.Void> handler,
  ) {
    _binding.DestroyIrisEventHandler(handler);
  }

  @override
  void destroyNativeApiEngine(ffi.Pointer<ffi.Void> apiEnginePtr) {
    _binding.DestroyIrisRtmEngine(apiEnginePtr);
  }
}

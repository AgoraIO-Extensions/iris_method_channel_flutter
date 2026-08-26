import 'dart:ffi' as ffi;

// ignore_for_file: public_member_api_docs

class NativeIrisSessionBinding {
  NativeIrisSessionBinding(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  int createNativeSession({
    required int nativeSessionId,
    required ffi.Pointer<ffi.Void> irisApiEngine,
    required ffi.Pointer<ffi.Void> irisEventHandler,
    required ffi.Pointer<ffi.Void> irisCEventHandler,
    required int dartPort,
    required int destroyNativeApiEngineAddress,
    required int destroyIrisEventHandlerAddress,
  }) {
    return _createNativeSession(
      nativeSessionId,
      irisApiEngine,
      irisEventHandler,
      irisCEventHandler,
      dartPort,
      destroyNativeApiEngineAddress,
      destroyIrisEventHandlerAddress,
    );
  }

  late final _createNativeSessionPtr = _lookup<
      ffi.NativeFunction<
          ffi.Uint64 Function(
              ffi.Uint64,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Int64,
              ffi.IntPtr,
              ffi.IntPtr)>>('Iris_CreateNativeSession');
  late final _createNativeSession = _createNativeSessionPtr.asFunction<
      int Function(int, ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Void>, int, int, int)>();

  bool acquireNativeSession(int sessionId) {
    return _acquireNativeSession(sessionId) == 0;
  }

  late final _acquireNativeSessionPtr =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Uint64)>>(
          'Iris_AcquireNativeSession');
  late final _acquireNativeSession =
      _acquireNativeSessionPtr.asFunction<int Function(int)>();

  void releaseNativeSession(int sessionId) {
    final result = _releaseNativeSession(sessionId);
    if (result != 0) {
      throw StateError('Failed to release native Iris session $sessionId');
    }
  }

  late final _releaseNativeSessionPtr =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Uint64)>>(
          'Iris_ReleaseNativeSession');
  late final _releaseNativeSession =
      _releaseNativeSessionPtr.asFunction<int Function(int)>();

  int destroyNativeSession(int sessionId) {
    return _destroyNativeSession(sessionId);
  }

  late final _destroyNativeSessionPtr =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Uint64)>>(
          'Iris_DestroyNativeSession');
  late final _destroyNativeSession =
      _destroyNativeSessionPtr.asFunction<int Function(int)>();

  int forceDestroyNativeSession(int sessionId) {
    return _forceDestroyNativeSession(sessionId);
  }

  late final _forceDestroyNativeSessionPtr =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Uint64)>>(
          'Iris_ForceDestroyNativeSession');
  late final _forceDestroyNativeSession =
      _forceDestroyNativeSessionPtr.asFunction<int Function(int)>();
}

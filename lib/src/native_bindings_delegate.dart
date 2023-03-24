import 'dart:convert';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:iris_method_channel/src/iris_event.dart';

import 'bindings/native_iris_api_common_bindings.dart' as iris;
import 'iris_method_channel.dart';

// ignore_for_file: public_member_api_docs

class CreateNativeApiEngineResult {
  const CreateNativeApiEngineResult(this.apiEnginePtr,
      {this.extraData = const {}});
  final ffi.Pointer<ffi.Void> apiEnginePtr;
  final Map<String, Object> extraData;
}

/// Unified interface for iris API engine.
/// The [NativeBindingDelegate] is running inside a seperate isolate which is
/// spawned by the main isolate, so you should not share any objects in this class.
abstract class NativeBindingDelegate {
  void initialize();

  CreateNativeApiEngineResult createNativeApiEngine(List<ffi.Pointer<ffi.Void>> args);

  CallApiResult invokeMethod(
    ffi.Pointer<ffi.Void> irisApiEnginePtr,
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
            bufferParamList.add(const BufferParam(0, 0));
            continue;
          }
          final ffi.Pointer<ffi.Uint8> bufferData =
              arena.allocate<ffi.Uint8>(buffer.length);

          final pointerList = bufferData.asTypedList(buffer.length);
          pointerList.setAll(0, buffer);

          bufferParamList.add(BufferParam(bufferData.address, buffer.length));
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
          bufferListPtr[i] = ffi.Pointer.fromAddress(bufferParam.intPtr);
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
          apiParam,
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
        debugPrint(
            '[_ApiCallExecutor] $funcName, params: $params\nerror: ${e.toString()}');
        return CallApiResult(irisReturnCode: -1, data: const {});
      }
    });
  }

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

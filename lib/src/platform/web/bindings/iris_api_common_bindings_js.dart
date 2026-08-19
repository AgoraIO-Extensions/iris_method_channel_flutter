import 'dart:convert';
import 'dart:js_interop';

import 'package:iris_method_channel/src/platform/iris_event_interface.dart';
import 'package:iris_method_channel/src/platform/iris_method_channel_interface.dart';

// ignore_for_file: public_member_api_docs, non_constant_identifier_names

// NOTE:
// These bindings use `dart:js_interop` (instead of the legacy `package:js`)
// so that they work under both dart2js and dart2wasm. Under dart2wasm the
// legacy `dart.library.js` conditional imports are false and Dart `List`s are
// not JS arrays, so all array-typed members are `JSArray` here and callers
// must convert with `.toJS` / `.toDart`.

@JS('IrisCore.EventParam')
extension type EventParam._(JSObject _) implements JSObject {
  // An external factory with only named arguments creates a JS object
  // literal (the `dart:js_interop` equivalent of `@anonymous`).
  external factory EventParam({
    String event,
    String data,
    int data_size,
    String result,
    JSArray<JSAny?> buffer,
    JSArray<JSNumber> length,
    int buffer_count,
  });

  external String get event;
  external String get data;
  external int get data_size;
  external String get result;
  external JSArray<JSAny?> get buffer;
  external JSArray<JSNumber> get length;
  external int get buffer_count;
}

IrisEventMessage toIrisEventMessage(EventParam param) {
  final buffers = param.buffer.toDart
      .map((e) => (e! as JSUint8Array).toDart)
      .toList(growable: false);
  return IrisEventMessage(param.event, param.data, buffers);
}

typedef ApiParam = EventParam;

@JS('IrisCore.CallIrisApiResult')
extension type CallIrisApiResult._(JSObject _) implements JSObject {
  external factory CallIrisApiResult({
    int code,
    String data,
  });

  external int get code;
  external String get data;
}

extension CallIrisApiResultExt on CallIrisApiResult {
  CallApiResult toCallApiResult() {
    return CallApiResult(
        irisReturnCode: code, data: jsonDecode(data), rawData: data);
  }
}

@JS('IrisCore.IrisEventHandler')
extension type IrisEventHandler._(JSObject _) implements JSObject {}

@JS('IrisCore.IrisApiEngine')
extension type IrisApiEngine._(JSObject _) implements JSObject {}

@JS('IrisCore.createIrisApiEngine')
external IrisApiEngine createIrisApiEngine();

@JS('IrisCore.disposeIrisApiEngine')
external int disposeIrisApiEngine(IrisApiEngine engine_ptr);

/// `IrisCore.callIrisApi` returns a `Promise<CallIrisApiResult>` on web.
@JS('IrisCore.callIrisApi')
external JSPromise<CallIrisApiResult> callIrisApi(
    IrisApiEngine engine_ptr, ApiParam apiParam);

typedef IrisEventHandlerFuncJS = JSFunction;
typedef IrisCEventHandler = IrisEventHandlerFuncJS;

@JS('IrisCore.createIrisEventHandler')
external IrisEventHandler createIrisEventHandler(
    IrisCEventHandler event_handler);

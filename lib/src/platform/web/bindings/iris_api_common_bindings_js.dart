@JS('IrisCore')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:iris_method_channel/src/platform/iris_event_interface.dart';
import 'package:iris_method_channel/src/platform/iris_method_channel_interface.dart';

// ignore_for_file: public_member_api_docs, non_constant_identifier_names

@JS('EventParam')
@anonymous
@staticInterop
class EventParam {
  factory EventParam({
    String event = '',
    String data = '',
    int data_size = 0,
    String result = '',
    List<Uint8List> buffer = const [],
    List<int> length = const [],
    int buffer_count = 0,
  }) => EventParam._(
    event: event,
    data: data,
    data_size: data_size,
    result: result,
    buffer: buffer.map((value) => value.toJS).toList().toJS,
    length: length.map((value) => value.toJS).toList().toJS,
    buffer_count: buffer_count,
  );

  external factory EventParam._({
    String event,
    String data,
    int data_size,
    String result,
    JSArray<JSUint8Array> buffer,
    JSArray<JSNumber> length,
    int buffer_count,
  });
}

extension EventParamExt on EventParam {
  external String get event;
  external String get data;
  external int get data_size;
  external String get result;
  @JS('buffer')
  external JSArray<JSUint8Array> get _buffer;
  @JS('length')
  external JSArray<JSNumber> get _length;
  external int get buffer_count;

  List<Uint8List> get buffer =>
      _buffer.toDart.map((value) => value.toDart).toList(growable: false);

  List<int> get length =>
      _length.toDart.map((value) => value.toDartInt).toList(growable: false);
}

IrisEventMessage toIrisEventMessage(EventParam param) {
  return IrisEventMessage(
      param.event, param.data, List<Uint8List>.from(param.buffer));
}

typedef ApiParam = EventParam;

@JS('CallIrisApiResult')
@anonymous
@staticInterop
class CallIrisApiResult {
  external factory CallIrisApiResult({
    int code,
    String data,
  });
}

extension CallIrisApiResultInteropExt on CallIrisApiResult {
  external int get code;
  external String get data;
}

extension CallIrisApiResultExt on CallIrisApiResult {
  CallApiResult toCallApiResult() {
    return CallApiResult(
        irisReturnCode: code, data: jsonDecode(data), rawData: data);
  }
}

@JS('IrisEventHandler')
@staticInterop
class IrisEventHandler {}

@JS('IrisApiEngine')
@staticInterop
class IrisApiEngine {}

@JS('createIrisApiEngine')
external IrisApiEngine createIrisApiEngine();

@JS('disposeIrisApiEngine')
external int disposeIrisApiEngine(IrisApiEngine engine_ptr);

@JS('callIrisApi')
external int callIrisApi(IrisApiEngine engine_ptr, ApiParam apiParam);

typedef IrisEventHandlerFuncJS = void Function(EventParam param);
typedef IrisCEventHandler = JSExportedDartFunction;

@JS('createIrisEventHandler')
external IrisEventHandler createIrisEventHandler(
    IrisCEventHandler event_handler);

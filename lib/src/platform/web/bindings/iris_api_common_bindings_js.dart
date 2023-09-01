@JS()
library iris_web;

import 'dart:convert';

import 'package:iris_method_channel/src/platform/iris_event_interface.dart';
import 'package:iris_method_channel/src/platform/iris_method_channel_interface.dart';
import 'package:js/js.dart';

// ignore_for_file: public_member_api_docs, non_constant_identifier_names

// NOTE:
// For compatibility to dart sdk >= 2.12, we only use the feature that are 
// supported in `js: 0.6.3` at this time

@JS('AgoraWrapper.EventParam')
@anonymous
class EventParam {
  // Must have an unnamed factory constructor with named arguments.
  external factory EventParam({
    String event,
    String data,
    int data_size,
    String result,
    List<Object> buffer,
    List<int> length,
    int buffer_count,
  });

  external String get event;
  external String get data;
  external int get data_size;
  external String get result;
  external List<Object> get buffer;
  external List<int> get length;
  external int get buffer_count;
}

IrisEventMessage toIrisEventMessage(EventParam param) {
  return IrisEventMessage(param.event, param.data, []);
}

typedef ApiParam = EventParam;

@JS('AgoraWrapper.CallIrisApiResult')
@anonymous
class CallIrisApiResult {
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

typedef IrisCEventHandler = void Function(EventParam param);

@JS('AgoraWrapper.IrisEventHandlerHandle')
@anonymous
class IrisEventHandlerHandle {}

@JS('AgoraWrapper.IrisApiEngine')
@anonymous
class IrisApiEngine {}

@JS('AgoraWrapper.CreateIrisApiEngine')
external IrisApiEngine CreateIrisApiEngine();

@JS('AgoraWrapper.DestroyIrisApiEngine')
external int DestroyIrisApiEngine(IrisApiEngine engine_ptr);

@JS('AgoraWrapper.CallIrisApi')
external int CallIrisApi(IrisApiEngine engine_ptr, ApiParam apiParam);

@JS('AgoraWrapper.CallIrisApiAsync')
external Future<CallIrisApiResult> CallIrisApiAsync(
    IrisApiEngine engine_ptr, ApiParam apiParam);

typedef IrisCEventHandlerDartCallback = void Function(EventParam param);

@JS('AgoraWrapper.CreateIrisEventHandler')
external IrisEventHandlerHandle CreateIrisEventHandler(
    IrisCEventHandler event_handler);

@JS('AgoraWrapper.SetIrisRtcEngineEventHandler')
external IrisEventHandlerHandle SetIrisRtcEngineEventHandler(
    IrisApiEngine engine_ptr, IrisEventHandlerHandle event_handler);

@JS('AgoraWrapper.UnsetIrisRtcEngineEventHandler')
external IrisEventHandlerHandle UnsetIrisRtcEngineEventHandler(
    IrisApiEngine engine_ptr, IrisEventHandlerHandle event_handler);

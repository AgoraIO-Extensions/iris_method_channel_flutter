@JS()
library iris_web;

import 'dart:convert';

import 'package:iris_method_channel/src/platform/iris_event_interface.dart';
import 'package:iris_method_channel/src/platform/iris_method_channel_interface.dart';
import 'package:js/js.dart';

// ignore_for_file: public_member_api_docs, non_constant_identifier_names

@JS('AgoraWrapper.EventParam')
@staticInterop
class EventParam {
  external factory EventParam(
    String event,
    String data,
    int data_size,
    String result,
    List<Object> buffer,
    List<int> length,
    int buffer_count,
  );
}

extension on EventParam {
  external String event;
  external String data;
  external int data_size;
  external String result;
  external List<Object> buffer;
  external List<int> length;
  external int buffer_count;
}

IrisEventMessage toIrisEventMessage(EventParam param) {
  return IrisEventMessage(param.event, param.data, []);
}

typedef ApiParam = EventParam;

@JS('AgoraWrapper.CallIrisApiResult')
@staticInterop
class CallIrisApiResult {
  external factory CallIrisApiResult(
    int code,
    String data,
  );
}

extension on CallIrisApiResult {
  external int code;
  external String data;
}

extension CallIrisApiResultExt on CallIrisApiResult {
  CallApiResult toCallApiResult() {
    return CallApiResult(
        irisReturnCode: code, data: jsonDecode(data), rawData: data);
  }
}

@JS('AgoraWrapper.IrisCEventHandler')
@staticInterop
class IrisCEventHandler {}

@JS('AgoraWrapper.IrisEventHandlerHandle')
@staticInterop
class IrisEventHandlerHandle {}

@JS('AgoraWrapper.IrisApiEngine')
@staticInterop
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

@JSExport()
class IrisCEventHandlerDartExport {
  IrisCEventHandlerDartExport(this._callback);

  final IrisCEventHandlerDartCallback _callback;

  @JSExport('onEvent')
  void onEvent(EventParam param) {
    _callback(param);
  }
}

@JS('AgoraWrapper.CreateIrisEventHandler')
external IrisEventHandlerHandle CreateIrisEventHandler(
    IrisCEventHandler event_handler);

@JS('AgoraWrapper.SetIrisRtcEngineEventHandler')
external IrisEventHandlerHandle SetIrisRtcEngineEventHandler(
    IrisApiEngine engine_ptr, IrisEventHandlerHandle event_handler);

@JS('AgoraWrapper.UnsetIrisRtcEngineEventHandler')
external IrisEventHandlerHandle UnsetIrisRtcEngineEventHandler(
    IrisApiEngine engine_ptr, IrisEventHandlerHandle event_handler);

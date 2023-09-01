import 'dart:js_util';

import 'package:iris_method_channel/src/iris_handles.dart';
import 'package:iris_method_channel/src/platform/iris_event_interface.dart';
import 'package:iris_method_channel/src/platform/web/bindings/iris_api_common_bindings_js.dart'
    as js;

// ignore_for_file: public_member_api_docs

class IrisEventWeb implements IrisEvent {
  IrisEventWeb(this._irisApiEngine);

  final IrisApiEngineHandle _irisApiEngine;

  IrisEventMessageListener? _irisEventMessageListener;

  js.IrisEventHandlerHandle? _irisEventHandlerJS;

  void initialize() {
    final irisCEventHandlerJS = allowInterop(_onEventFromJS);

    _irisEventHandlerJS = js.CreateIrisEventHandler(irisCEventHandlerJS);
    js.SetIrisRtcEngineEventHandler(
        _irisApiEngine() as js.IrisApiEngine, _irisEventHandlerJS!);
  }

  void setIrisEventMessageListener(IrisEventMessageListener? listener) {
    _irisEventMessageListener = listener;
  }

  void _onEventFromJS(js.EventParam param) {
    if (_irisEventMessageListener != null) {
      _irisEventMessageListener?.call(js.toIrisEventMessage(param));
    }
  }

  /// Clean up native resources
  void dispose() {
    js.UnsetIrisRtcEngineEventHandler(
        _irisApiEngine() as js.IrisApiEngine, _irisEventHandlerJS!);
    _irisEventHandlerJS = null;

    _irisEventMessageListener = null;
  }
}

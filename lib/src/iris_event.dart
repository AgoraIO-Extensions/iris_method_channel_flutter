import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'bindings/native_iris_event_bindings.dart';

const _libName = 'iris_method_channel';

/// Iris event handler interface
abstract class EventLoopEventHandler {
  /// Callback when received events
  bool handleEvent(
      String eventName, String eventData, List<Uint8List> buffers) {
    return handleEventInternal(eventName, eventData, buffers);
  }

  @protected
  // ignore: public_member_api_docs
  bool handleEventInternal(
      String eventName, String eventData, List<Uint8List> buffers);
}

ffi.DynamicLibrary _loadLib() {
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$_libName.dll');
  }

  if (Platform.isAndroid) {
    return ffi.DynamicLibrary.open("lib$_libName.so");
  }

  return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
}

/// Object to hold the iris event infos
class IrisEventMessage {
  /// Construct [IrisEventMessage]
  const IrisEventMessage(this.event, this.data, this.buffers);

  /// The event name
  final String event;

  /// The json data
  final String data;

  /// Byte buffers
  final List<Uint8List> buffers;
}

/// Iris event handler which forward events to dart side.
/// See native implementation src/iris_event.cc
class IrisEvent {
  /// Construct [IrisEvent]
  IrisEvent() {
    _nativeIrisEventBinding = NativeIrisEventBinding(_loadLib());
    _nativeIrisEventBinding.InitDartApiDL(ffi.NativeApi.initializeApiDLData);
  }

  /// Parse message to [IrisEventMessage] object
  static IrisEventMessage parseMessage(dynamic message) {
    final dataList = List.from(message);
    String event = dataList[0];
    String data = dataList[1] as String;
    if (data.isEmpty) {
      data = "{}";
    }

    String res = dataList[1] as String;
    if (res.isEmpty) {
      res = "{}";
    }
    List<Uint8List> buffers = dataList.length == 3
        ? List<Uint8List>.from(dataList[2])
        : <Uint8List>[];

    return IrisEventMessage(event, data, buffers);
  }

  late final NativeIrisEventBinding _nativeIrisEventBinding;

  /// Register dart [SendPort] to send the message from native
  void registerEventHandler(SendPort sendPort) {
    _nativeIrisEventBinding.RegisterDartPort(sendPort.nativePort);
  }

  /// Unregister dart [SendPort] which used to send the message from native
  void unregisterEventHandler(SendPort sendPort) {
    _nativeIrisEventBinding.UnregisterDartPort(sendPort.nativePort);
  }

  /// Clean up native resources
  void dispose() {
    _nativeIrisEventBinding.Dispose();
  }

  /// Get the onEvent function pointer from C
  ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<EventParam>)>>
      get onEventPtr => _nativeIrisEventBinding.addresses.OnEvent;
}

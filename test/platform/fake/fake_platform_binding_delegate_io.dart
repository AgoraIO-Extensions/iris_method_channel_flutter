import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:iris_method_channel/iris_method_channel.dart';
import 'package:iris_method_channel/src/platform/io/bindings/native_iris_api_common_bindings.dart'
    as iris;
import 'package:iris_method_channel/src/platform/io/bindings/native_iris_event_bindings.dart'
    as iris_event;
import 'package:iris_method_channel/src/platform/io/iris_event_io.dart';

import 'platform_tester_interface.dart';

class _FakeNativeBindingDelegateMessenger implements CallApiRecorderInterface {
  _FakeNativeBindingDelegateMessenger() {
    apiCallPort.listen((message) {
      assert(message is CallApiRecord);
      callApiRecords.add(message);
    });
  }
  final apiCallPort = ReceivePort();
  final _callApiRecords = <CallApiRecord>[];

  SendPort getSendPort() => apiCallPort.sendPort;

  @override
  List<CallApiRecord> get callApiRecords {
    return _callApiRecords;
  }
}

class FakeNativeBindingDelegate extends PlatformBindingsDelegateInterface {
  FakeNativeBindingDelegate(this.apiCallPortSendPort);

  final SendPort apiCallPortSendPort;

  void _response(ffi.Pointer<iris.ApiParam> param, Map<String, Object> result) {
    using<void>((Arena arena) {
      final ffi.Pointer<Utf8> resultMapPointerUtf8 =
          jsonEncode(result).toNativeUtf8(allocator: arena);
      final ffi.Pointer<ffi.Int8> resultMapPointerInt8 =
          resultMapPointerUtf8.cast();

      for (int i = 0; i < kBasicResultLength; i++) {
        if (i >= resultMapPointerUtf8.length) {
          break;
        }

        param.ref.result[i] = resultMapPointerInt8[i];
      }
    });
  }

  @override
  int callApi(
    IrisMethodCall methodCall,
    IrisApiEngineHandle apiEnginePtr,
    IrisApiParamHandle param,
  ) {
    final theParam = param() as ffi.Pointer<iris.ApiParam>;
    final record = CallApiRecord(
      methodCall,
      CallApiRecordApiParam(
        theParam.ref.event.cast<Utf8>().toDartString(),
        theParam.ref.data.cast<Utf8>().toDartString(),
      ),
    );
    apiCallPortSendPort.send(record);

    _response(theParam, {});

    return 0;
  }

  @override
  IrisEventHandlerHandle createIrisEventHandler(
    IrisCEventHandlerHandle eventHandler,
  ) {
    final record = CallApiRecord(
      const IrisMethodCall('createIrisEventHandler', '{}'),
      CallApiRecordApiParam(
        'createIrisEventHandler',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
    return IrisEventHandlerHandle(ffi.Pointer<ffi.Void>.fromAddress(123456));
  }

  @override
  CreateApiEngineResult createApiEngine(List<InitilizationArgProvider> args) {
    final engineHandle =
        IrisApiEngineHandle(ffi.Pointer<ffi.Void>.fromAddress(100));
    if (args.isNotEmpty) {
      final value = args[0].provide(engineHandle)();
      final record = CallApiRecord(
        const IrisMethodCall('createApiEngine', '{}'),
        CallApiRecordApiParam(
          'createApiEngine',
          jsonEncode({'args': value}),
        ),
      );
      apiCallPortSendPort.send(record);
    } else {
      final record = CallApiRecord(
        const IrisMethodCall('createApiEngine', '{}'),
        CallApiRecordApiParam(
          'createApiEngine',
          '{}',
        ),
      );
      apiCallPortSendPort.send(record);
    }
    return CreateApiEngineResult(
      engineHandle,
      extraData: <String, Object>{'extra_handle': 1000},
    );
  }

  @override
  void destroyIrisEventHandler(
    IrisEventHandlerHandle handler,
  ) {
    final record = CallApiRecord(
      const IrisMethodCall('destroyIrisEventHandler', '{}'),
      CallApiRecordApiParam(
        'destroyIrisEventHandler',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  void destroyNativeApiEngine(IrisApiEngineHandle apiEnginePtr) {
    final record = CallApiRecord(
      const IrisMethodCall('destroyNativeApiEngine', '{}'),
      CallApiRecordApiParam(
        'destroyNativeApiEngine',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  void initialize() {
    final record = CallApiRecord(
      const IrisMethodCall('initialize', '{}'),
      CallApiRecordApiParam(
        'initialize',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  Future<CallApiResult> callApiAsync(IrisMethodCall methodCall,
      IrisApiEngineHandle apiEnginePtr, IrisApiParamHandle param) async {
    return CallApiResult(irisReturnCode: 0, data: {});
  }
}

class _FakeIrisEvent implements IrisEventIO {
  _FakeIrisEvent(this.apiCallPortSendPort);

  final SendPort apiCallPortSendPort;

  @override
  void initialize() {
    final record = CallApiRecord(
      const IrisMethodCall('IrisEvent_initialize', '{}'),
      CallApiRecordApiParam(
        'IrisEvent_initialize',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  void registerEventHandler(SendPort sendPort) {
    final record = CallApiRecord(
      const IrisMethodCall('IrisEvent_registerEventHandler', '{}'),
      CallApiRecordApiParam(
        'IrisEvent_registerEventHandler',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  void unregisterEventHandler(SendPort sendPort) {
    final record = CallApiRecord(
      const IrisMethodCall('IrisEvent_unregisterEventHandler', '{}'),
      CallApiRecordApiParam(
        'IrisEvent_unregisterEventHandler',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  void dispose() {
    final record = CallApiRecord(
      const IrisMethodCall('IrisEvent_dispose', '{}'),
      CallApiRecordApiParam(
        'IrisEvent_dispose',
        '{}',
      ),
    );
    apiCallPortSendPort.send(record);
  }

  @override
  ffi.Pointer<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Pointer<iris_event.EventParam> p1)>>
      get onEventPtr => ffi.Pointer<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Pointer<iris_event.EventParam> p1)>>.fromAddress(0);
}

class FakeNativeBindingDelegateProvider extends PlatformBindingsProvider {
  FakeNativeBindingDelegateProvider(this.nativeBindingDelegate, this.irisEvent);

  final PlatformBindingsDelegateInterface nativeBindingDelegate;
  final IrisEvent irisEvent;

  @override
  PlatformBindingsDelegateInterface provideNativeBindingDelegate() {
    return nativeBindingDelegate;
  }

  @override
  IrisEvent provideIrisEvent() {
    return irisEvent;
  }
}

class PlatformTesterInterfaceIO implements PlatformTesterInterface {
  PlatformTesterInterfaceIO() {
    messenger = _FakeNativeBindingDelegateMessenger();
    final FakeNativeBindingDelegate nativeBindingDelegate =
        FakeNativeBindingDelegate(messenger.getSendPort());
    final _FakeIrisEvent irisEvent = _FakeIrisEvent(messenger.getSendPort());
    final nativeBindingsProvider =
        FakeNativeBindingDelegateProvider(nativeBindingDelegate, irisEvent);
    irisMethodChannel = IrisMethodChannel(nativeBindingsProvider);
  }

  // ignore: library_private_types_in_public_api
  late _FakeNativeBindingDelegateMessenger messenger;
  late IrisMethodChannel irisMethodChannel;

  @override
  CallApiRecorderInterface getCallApiRecorder() {
    return messenger;
  }

  @override
  IrisMethodChannel getIrisMethodChannel() {
    return irisMethodChannel;
  }
}

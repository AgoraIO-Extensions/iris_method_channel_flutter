import 'dart:convert';
import 'dart:js' as js;

import 'package:iris_method_channel/iris_method_channel.dart';

import 'platform_tester_interface.dart';

class FakeTypeWeb {}

class _FakeNativeBindingDelegateMessenger implements CallApiRecorderInterface {
  _FakeNativeBindingDelegateMessenger();
  final _callApiRecords = <CallApiRecord>[];

  @override
  List<CallApiRecord> get callApiRecords {
    return _callApiRecords;
  }

  void addCallApiRecord(CallApiRecord record) {
    _callApiRecords.add(record);
  }
}

class FakeNativeBindingDelegate extends PlatformBindingsDelegateInterface {
  FakeNativeBindingDelegate(this.messenger);

  final _FakeNativeBindingDelegateMessenger messenger;

  @override
  int callApi(
    IrisMethodCall methodCall,
    IrisApiEngineHandle apiEnginePtr,
    IrisApiParamHandle param,
  ) {
    throw UnimplementedError('Not implemented on web.');
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
    messenger.addCallApiRecord(record);

    return IrisEventHandlerHandle(FakeTypeWeb());
  }

  @override
  CreateApiEngineResult createApiEngine(List<InitilizationArgProvider> args) {
    final engineHandle = IrisApiEngineHandle(FakeTypeWeb());
    if (args.isNotEmpty) {
      final value = args[0].provide(engineHandle)();
      final record = CallApiRecord(
        const IrisMethodCall('createApiEngine', '{}'),
        CallApiRecordApiParam(
          'createApiEngine',
          jsonEncode({'args': value}),
        ),
      );
      messenger.addCallApiRecord(record);
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
    messenger.addCallApiRecord(record);
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
    messenger.addCallApiRecord(record);
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
    messenger.addCallApiRecord(record);
  }

  @override
  Future<CallApiResult> callApiAsync(IrisMethodCall methodCall,
      IrisApiEngineHandle apiEnginePtr, IrisApiParamHandle param) async {
    final record = CallApiRecord(
      methodCall,
      CallApiRecordApiParam(
        methodCall.funcName,
        methodCall.params,
      ),
    );
    messenger.addCallApiRecord(record);

    return CallApiResult(irisReturnCode: 0, data: {});
  }
}

class _FakeIrisEvent implements IrisEvent {
  _FakeIrisEvent();
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

class EventParamFake {}

class PlatformTesterInterfaceWeb implements PlatformTesterInterface {
  PlatformTesterInterfaceWeb() {
    js.context['EventParam'] = EventParamFake();

    messenger = _FakeNativeBindingDelegateMessenger();
    final FakeNativeBindingDelegate nativeBindingDelegate =
        FakeNativeBindingDelegate(messenger);
    final _FakeIrisEvent irisEvent = _FakeIrisEvent();
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

import 'dart:isolate';
import 'dart:ffi' as ffi;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iris_method_channel/iris_method_channel.dart';
import 'package:iris_method_channel/src/platform/io/iris_method_channel_internal_io.dart';

class _FakeNativeBindingDelegate extends PlatformBindingsDelegateInterface {
  _FakeNativeBindingDelegate();

  @override
  int callApi(
    IrisMethodCall methodCall,
    IrisApiEngineHandle apiEnginePtr,
    IrisApiParamHandle param,
  ) {
    return 0;
  }

  @override
  IrisEventHandlerHandle createIrisEventHandler(
    IrisCEventHandlerHandle eventHandler,
  ) {
    return IrisEventHandlerHandle(ffi.Pointer<ffi.Void>.fromAddress(123456));
  }

  @override
  CreateApiEngineResult createApiEngine(List<InitilizationArgProvider> args) {
    return CreateApiEngineResult(
      IrisApiEngineHandle(ffi.Pointer<ffi.Void>.fromAddress(100)),
      extraData: <String, Object>{'extra_handle': 1000},
    );
  }

  @override
  void destroyIrisEventHandler(
    IrisEventHandlerHandle handler,
  ) {}

  @override
  void destroyNativeApiEngine(IrisApiEngineHandle apiEnginePtr) {}

  @override
  void initialize() {}

  @override
  Future<CallApiResult> callApiAsync(IrisMethodCall methodCall,
      IrisApiEngineHandle apiEnginePtr, IrisApiParamHandle param) async {
    return CallApiResult(irisReturnCode: 0, data: {});
  }
}

class _FakeNativeBindingDelegateProvider extends PlatformBindingsProvider {
  _FakeNativeBindingDelegateProvider(this.nativeBindingDelegate);

  final PlatformBindingsDelegateInterface nativeBindingDelegate;

  @override
  PlatformBindingsDelegateInterface provideNativeBindingDelegate() {
    return nativeBindingDelegate;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'IrisMethodChannel should call hot restart listener',
    (tester) async {
      await tester.pumpWidget(Container());

      final irisMethodChannel = IrisMethodChannel(
          _FakeNativeBindingDelegateProvider(_FakeNativeBindingDelegate()));
      await irisMethodChannel.initilize([]);

      bool hotRestartListenerCalled = false;
      irisMethodChannel.addHotRestartListener((message) {
        hotRestartListenerCalled = true;
      });

      (irisMethodChannel.getIrisMethodChannelInternal()
              as IrisMethodChannelInternalIO)
          .workerIsolate
          .kill(priority: Isolate.immediate);
      // Delayed 2 seconds to ensure `irisMethodChannel.workerIsolate.kill` done
      await Future.delayed(const Duration(seconds: 2));

      expect(hotRestartListenerCalled, true);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

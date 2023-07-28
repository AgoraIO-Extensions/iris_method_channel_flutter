import 'dart:isolate';

import 'package:iris_method_channel/iris_method_channel.dart';
import 'package:iris_method_channel/src/platform/io/iris_method_channel_internal_io.dart';
import 'package:test/test.dart';

import 'platform_tester.dart';

void platformCases() {
  group('Get InitilizationResult', () {
    late CallApiRecorderInterface messenger;

    late IrisMethodChannel irisMethodChannel;

    late IrisMethodChannelInternalIO irisMethodChannelInternal;

    late PlatformTesterInterface platformTester;

    setUp(() {
      platformTester = getPlatformTester();
      irisMethodChannel = platformTester.getIrisMethodChannel();
      irisMethodChannelInternal = irisMethodChannel
          .getIrisMethodChannelInternal() as IrisMethodChannelInternalIO;
      messenger = platformTester.getCallApiRecorder();
    });

    test('able to get InitilizationResult from initilize', () async {
      final InitilizationResult? result = await irisMethodChannel.initilize([]);
      expect(result, isNotNull);

      final resultIO = result! as InitilizationResultIO;

      expect(resultIO.irisApiEngineNativeHandle, 100);
      expect(resultIO.extraData, {'extra_handle': 1000});

      await irisMethodChannel.dispose();
    });

    test('get null InitilizationResult if initilize multiple times', () async {
      await irisMethodChannel.initilize([]);

      final InitilizationResult? result = await irisMethodChannel.initilize([]);
      expect(result, isNull);

      await irisMethodChannel.dispose();
    });

    test('Should clean native resources when hot restart happen', () async {
      await irisMethodChannel.initilize([]);

      irisMethodChannelInternal.workerIsolate.kill(priority: Isolate.immediate);
      // Delayed 1 second to ensure `irisMethodChannel.workerIsolate.kill` done
      await Future.delayed(const Duration(seconds: 1));

      final destroyNativeApiEngineCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyNativeApiEngine');
      expect(destroyNativeApiEngineCallRecord.length, 1);

      final destroyIrisEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyIrisEventHandler');
      expect(destroyIrisEventHandlerCallRecord.length, 1);

      final irisEventDisposeCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'IrisEvent_dispose');
      expect(irisEventDisposeCallRecord.length, 1);
    });

    test('addHotRestartListener', () async {
      await irisMethodChannel.initilize([]);

      bool hotRestartListenerCalled = false;
      irisMethodChannel.addHotRestartListener((message) {
        hotRestartListenerCalled = true;
      });
      irisMethodChannelInternal.workerIsolate.kill(priority: Isolate.immediate);

      // Delayed 1 second to ensure `irisMethodChannel.workerIsolate.kill` done
      await Future.delayed(const Duration(seconds: 1));

      expect(hotRestartListenerCalled, true);
    });

    test('removeHotRestartListener', () async {
      await irisMethodChannel.initilize([]);

      bool hotRestartListenerCalled = false;
      // ignore: prefer_function_declarations_over_variables
      final listener = (message) {
        hotRestartListenerCalled = true;
      };
      irisMethodChannel.addHotRestartListener(listener);
      irisMethodChannel.removeHotRestartListener(listener);
      irisMethodChannelInternal.workerIsolate.kill(priority: Isolate.immediate);

      // Delayed 1 second to ensure `irisMethodChannel.workerIsolate.kill` done
      await Future.delayed(const Duration(seconds: 1));

      expect(hotRestartListenerCalled, false);
    });

    test('removeHotRestartListener through returned VoidCallback', () async {
      await irisMethodChannel.initilize([]);

      bool hotRestartListenerCalled = false;
      // ignore: prefer_function_declarations_over_variables
      final listener = (message) {
        hotRestartListenerCalled = true;
      };
      final removeListener = irisMethodChannel.addHotRestartListener(listener);
      removeListener();
      irisMethodChannelInternal.workerIsolate.kill(priority: Isolate.immediate);

      // Delayed 1 second to ensure `irisMethodChannel.workerIsolate.kill` done
      await Future.delayed(const Duration(seconds: 1));

      expect(hotRestartListenerCalled, false);
    });
  });
}

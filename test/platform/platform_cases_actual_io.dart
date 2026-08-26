import 'dart:convert';
import 'dart:isolate';

import 'package:iris_method_channel/iris_method_channel.dart';
import 'package:iris_method_channel/src/platform/io/iris_method_channel_internal_io.dart';
import 'package:test/test.dart';

import 'fake/fake_platform_binding_delegate_io.dart';
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
      expect(resultIO.nativeSessionId, 42);

      await irisMethodChannel.dispose();
    });

    test('get null InitilizationResult if initilize multiple times', () async {
      await irisMethodChannel.initilize([]);

      final InitilizationResult? result = await irisMethodChannel.initilize([]);
      expect(result, isNull);

      await irisMethodChannel.dispose();
    });

    for (final attachFailure in <String, PlatformTesterInterfaceIO>{
      'returns zero': PlatformTesterInterfaceIO(nativeSessionAttachResult: 0),
      'throws': PlatformTesterInterfaceIO(throwOnNativeSessionAttach: true),
    }.entries) {
      test(
          'rolls back native resources when session attach ${attachFailure.key}',
          () async {
        final failedTester = attachFailure.value;
        final failedChannel = failedTester.getIrisMethodChannel();
        final failedMessenger = failedTester.getCallApiRecorder();

        await expectLater(
          failedChannel.initilize([]),
          throwsA(isA<StateError>()),
        );
        await Future<void>.delayed(Duration.zero);

        final calls = failedMessenger.callApiRecords
            .map((record) => record.methodCall.funcName);
        expect(calls, contains('IrisEvent_unregisterEventHandler'));
        expect(calls, contains('destroyNativeApiEngine'));
        expect(calls, contains('destroyIrisEventHandler'));
        expect(calls, contains('IrisEvent_dispose'));
      });
    }

    test('Should clean native resources when hot restart happen', () async {
      await irisMethodChannel.initilize([]);

      irisMethodChannelInternal.workerIsolate.kill(priority: Isolate.immediate);
      // Delayed 1 second to ensure `irisMethodChannel.workerIsolate.kill` done
      await Future.delayed(const Duration(seconds: 1));

      final destroyNativeSessionCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'forceDestroyNativeSession');
      expect(destroyNativeSessionCallRecord.length, 1);
      expect(
        jsonDecode(destroyNativeSessionCallRecord.single.apiParam.data),
        {'sessionId': 42},
      );
    });

    test('can re-initialize after native session disposal fails', () async {
      final failedTester =
          PlatformTesterInterfaceIO(throwOnNativeSessionDestroy: true);
      final failedChannel = failedTester.getIrisMethodChannel();
      final failedInternal = failedChannel.getIrisMethodChannelInternal()
          as IrisMethodChannelInternalIO;
      final failedMessenger = failedTester.getCallApiRecorder();

      await failedChannel.initilize([]);
      await expectLater(
        failedChannel.dispose(),
        throwsA(isA<StateError>()),
      );

      await failedChannel.initilize([]);
      expect(
        failedMessenger.callApiRecords
            .where((record) => record.methodCall.funcName == 'createApiEngine'),
        hasLength(2),
      );

      failedInternal.workerIsolate.kill(priority: Isolate.immediate);
      await Future<void>.delayed(const Duration(seconds: 1));
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

    test('hot restart cleanup continues when a listener throws', () async {
      await irisMethodChannel.initilize([]);
      irisMethodChannel.addHotRestartListener((message) {
        throw StateError('listener failed');
      });

      irisMethodChannelInternal.workerIsolate.kill(priority: Isolate.immediate);
      await Future<void>.delayed(const Duration(seconds: 1));

      expect(
        messenger.callApiRecords.where((record) =>
            record.methodCall.funcName == 'forceDestroyNativeSession'),
        hasLength(1),
      );
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

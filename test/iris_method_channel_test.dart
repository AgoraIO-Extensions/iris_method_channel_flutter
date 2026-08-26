import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride, kIsWeb;
import 'package:flutter/services.dart'
    show MethodCall, MethodChannel, PlatformException, StandardMethodCodec;
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_method_channel/iris_method_channel.dart';

import 'platform/platform_cases.dart';
import 'platform/platform_tester.dart';

class _TestInitilizationArgProvider extends InitilizationArgProvider {
  bool called = false;
  @override
  IrisHandle provide(IrisApiEngineHandle apiEngineHandle) {
    called = true;
    return ObjectIrisHandle(called);
  }
}

class _TestEventLoopEventHandler extends EventLoopEventHandler {
  @override
  bool handleEventInternal(
      String eventName, String eventData, List<Uint8List> buffers) {
    return true;
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const platformChannel = MethodChannel('iris_method_channel');

  Future<Object?> handlePlatformCall(MethodCall call) async =>
      call.method == 'prepareInitialize' ? 42 : true;

  platformCases();

  late CallApiRecorderInterface messenger;

  late IrisMethodChannel irisMethodChannel;

  late PlatformTesterInterface platformTester;

  setUp(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      platformChannel,
      handlePlatformCall,
    );
    platformTester = getPlatformTester();
    irisMethodChannel = platformTester.getIrisMethodChannel();
    messenger = platformTester.getCallApiRecorder();
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      platformChannel,
      null,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  test(
      'able to initilize/dispose multiple times for same IrisMethodChannel object',
      () async {
    await irisMethodChannel.initilize([]);
    final callApiResult1 = await irisMethodChannel
        .invokeMethod(const IrisMethodCall('a_func_name', 'params'));
    expect(callApiResult1.irisReturnCode, 0);
    expect(callApiResult1.data, {});

    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name');
    expect(callRecord1.length, 1);

    await irisMethodChannel.dispose();

    await irisMethodChannel.initilize([]);
    final callApiResult2 = await irisMethodChannel
        .invokeMethod(const IrisMethodCall('a_func_name2', 'params'));
    expect(callApiResult2.irisReturnCode, 0);
    expect(callApiResult2.data, {});

    final callRecord2 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name2');
    expect(callRecord2.length, 1);

    await irisMethodChannel.dispose();
  });

  test('only initialize once', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.initilize([]);

    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'createApiEngine');
    expect(callRecord1.length, 1);

    await irisMethodChannel.dispose();
  });

  test('only initialize once when called simultaneously', () async {
    for (int i = 0; i < 5; ++i) {
      irisMethodChannel.initilize([]);
    }
    // Wait for the 5 times calls of `irisMethodChannel.initilize` are completed.
    await Future.delayed(const Duration(milliseconds: 1000));
    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'createApiEngine');
    expect(callRecord1.length, 1);

    await irisMethodChannel.dispose();
  });

  test('can re-initialize after dispose', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'createApiEngine');
    expect(callRecord1.length, 1);

    await irisMethodChannel.initilize([]);
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.initilize([]);
    final callRecord2 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'createApiEngine');
    expect(callRecord2.length, 2);
    await irisMethodChannel.dispose();
  });

  test('invokeMethod', () async {
    await irisMethodChannel.initilize([]);
    final callApiResult = await irisMethodChannel
        .invokeMethod(const IrisMethodCall('a_func_name', 'params'));
    expect(callApiResult.irisReturnCode, 0);
    expect(callApiResult.data, {});

    await irisMethodChannel.dispose();
  });

  test('invokeMethodList', () async {
    await irisMethodChannel.initilize([]);
    const methodCalls = [
      IrisMethodCall('a_func_name', 'params'),
      IrisMethodCall('a_func_name2', 'params')
    ];
    final callApiResult = await irisMethodChannel.invokeMethodList(methodCalls);

    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name');
    expect(callRecord1.length, 1);

    final callRecord2 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name2');
    expect(callRecord2.length, 1);

    expect(callApiResult[0].irisReturnCode, 0);
    expect(callApiResult[0].data, {});

    expect(callApiResult[1].irisReturnCode, 0);
    expect(callApiResult[1].data, {});

    await irisMethodChannel.dispose();
  });

  test(
    'registerEventHandler',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler),
          jsonEncode({}));

      final DisposableScopedObjects subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key)!;
      expect(subScopedObjects.keys.length, 1);

      final holder = subScopedObjects.values.elementAt(0) as EventHandlerHolder;

      expect(holder.eventHandlerHandle!(), 123456);

      expect(holder.getEventHandlers().length, 1);
      expect(holder.getEventHandlers().elementAt(0), eventHandler);

      final registerEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'registerEventHandler');
      expect(registerEventHandlerCallRecord.length, 1);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'unregisterEventHandler',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler),
          jsonEncode({}));
      await irisMethodChannel.unregisterEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler),
          jsonEncode({}));

      final DisposableScopedObjects subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key)!;
      expect(subScopedObjects.keys.length, 1);

      final EventHandlerHolder holder =
          subScopedObjects.values.elementAt(0) as EventHandlerHolder;
      expect(holder.getEventHandlers().length, 0);

      final registerEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
      expect(registerEventHandlerCallRecord.length, 1);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'unregisterEventHandlers',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler),
          jsonEncode({}));
      await irisMethodChannel.unregisterEventHandlers(key);

      final DisposableScopedObjects? subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key);
      expect(subScopedObjects, isNull);

      final registerEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
      expect(registerEventHandlerCallRecord.length, 1);

      await irisMethodChannel.dispose();
    },
  );

  test('disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    if (!kIsWeb) {
      final callRecords = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyNativeSession');
      expect(callRecords.length, 1);
      expect(jsonDecode(callRecords.single.apiParam.data), {'sessionId': 42});
    } else {
      final callRecords = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyNativeApiEngine');
      expect(callRecords.length, 1);
    }
  });

  test('disposed multiple times', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    await irisMethodChannel.dispose();
    if (!kIsWeb) {
      final callRecords = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyNativeSession');
      expect(callRecords.length, 1);
    } else {
      final callRecords = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyNativeApiEngine');
      expect(callRecords.length, 1);
    }
  });

  test('Android serializes native session registration and disposal', () async {
    if (kIsWeb) {
      return;
    }

    final platformCalls = <MethodCall>[];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      platformChannel,
      (call) async {
        platformCalls.add(call);
        return handlePlatformCall(call);
      },
    );

    try {
      await irisMethodChannel.initilize([]);
      await irisMethodChannel.dispose();

      expect(
        platformCalls.map((call) => call.method),
        [
          'prepareInitialize',
          'registerNativeSession',
          'unregisterNativeSession',
        ],
      );
      expect(platformCalls[1].arguments, {'sessionId': 42});
      expect(platformCalls[2].arguments, {'sessionId': 42});
    } finally {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        platformChannel,
        handlePlatformCall,
      );
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('non-Android platforms keep direct native resource ownership', () async {
    if (kIsWeb) {
      return;
    }

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await irisMethodChannel.initilize([]);
    expect(
      messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'createNativeSession'),
      isEmpty,
    );

    await irisMethodChannel.dispose();
    expect(
      messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyNativeApiEngine'),
      hasLength(1),
    );
    expect(
      messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyIrisEventHandler'),
      hasLength(1),
    );
  });

  test('Android initialization can retry after prepare fails', () async {
    if (kIsWeb) {
      return;
    }

    var prepareCalls = 0;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      platformChannel,
      (call) async {
        if (call.method == 'prepareInitialize') {
          prepareCalls++;
          return prepareCalls > 1 ? 42 : 0;
        }
        return handlePlatformCall(call);
      },
    );

    await expectLater(
      irisMethodChannel.initilize([]),
      throwsA(isA<StateError>()),
    );
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();

    expect(prepareCalls, 2);
  });

  test('Android registration failure destroys session and can retry', () async {
    if (kIsWeb) {
      return;
    }

    var registerCalls = 0;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      platformChannel,
      (call) async {
        if (call.method == 'registerNativeSession' && registerCalls++ == 0) {
          throw PlatformException(code: 'RegistrationFailed');
        }
        return handlePlatformCall(call);
      },
    );

    await expectLater(
      irisMethodChannel.initilize([]),
      throwsA(isA<PlatformException>()),
    );
    expect(
      messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyNativeSession'),
      hasLength(1),
    );

    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    expect(
      messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyNativeSession'),
      hasLength(2),
    );
  });

  test('Android initialization can retry after unregister fails', () async {
    if (kIsWeb) {
      return;
    }

    var unregisterCalls = 0;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      platformChannel,
      (call) async {
        if (call.method == 'unregisterNativeSession' &&
            unregisterCalls++ == 0) {
          throw PlatformException(code: 'UnregistrationFailed');
        }
        return handlePlatformCall(call);
      },
    );

    await irisMethodChannel.initilize([]);
    await expectLater(
      irisMethodChannel.dispose(),
      throwsA(isA<PlatformException>()),
    );

    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    expect(unregisterCalls, 2);
    expect(
      messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'destroyNativeSession'),
      hasLength(2),
    );
  });

  for (final methodName in <String>[
    'onDetachedFromEngine_fromPlatform',
    'onDetachedFromActivity_fromPlatform',
  ]) {
    test('disposed after receive $methodName', () async {
      await irisMethodChannel.initilize([]);

      // Simulate the `MethodChannel` call from native side.
      const StandardMethodCodec codec = StandardMethodCodec();
      final ByteData data = codec.encodeMethodCall(MethodCall(methodName));
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'iris_method_channel',
        data,
        (ByteData? data) {},
      );

      await Future.delayed(const Duration(milliseconds: 1000));

      if (!kIsWeb) {
        final callRecords = messenger.callApiRecords
            .where((e) => e.methodCall.funcName == 'destroyNativeSession');
        expect(callRecords.length, 1);
      } else {
        final callRecords = messenger.callApiRecords
            .where((e) => e.methodCall.funcName == 'destroyNativeApiEngine');
        expect(callRecords.length, 1);
      }
    });
  }

  test('invokeMethod after disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    final callApiResult = await irisMethodChannel
        .invokeMethod(const IrisMethodCall('a_func_name', 'params'));
    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name');
    expect(callRecord1.length, 0);

    expect(callApiResult.irisReturnCode, kDisposedIrisMethodCallReturnCode);
    expect(callApiResult.data, kDisposedIrisMethodCallData);
  });

  test('invokeMethodList after disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
    const methodCalls = [
      IrisMethodCall('a_func_name', 'params'),
      IrisMethodCall('a_func_name2', 'params')
    ];

    final callApiResult = await irisMethodChannel.invokeMethodList(methodCalls);

    final callRecord1 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name');
    expect(callRecord1.length, 0);

    final callRecord2 = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'a_func_name2');
    expect(callRecord2.length, 0);

    expect(callApiResult[0].irisReturnCode, kDisposedIrisMethodCallReturnCode);
    expect(callApiResult[0].data, kDisposedIrisMethodCallData);

    expect(callApiResult[1].irisReturnCode, kDisposedIrisMethodCallReturnCode);
    expect(callApiResult[1].data, kDisposedIrisMethodCallData);
  });

  test(
    'registerEventHandler after disposed',
    () async {
      await irisMethodChannel.initilize([]);
      await irisMethodChannel.dispose();

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler),
          jsonEncode({}));

      final DisposableScopedObjects? subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key);
      expect(subScopedObjects, isNull);

      final registerEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'registerEventHandler');
      expect(registerEventHandlerCallRecord.length, 0);
    },
  );

  test('unregisterEventHandler after disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));
    await irisMethodChannel.unregisterEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));

    final DisposableScopedObjects? subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key);
    expect(subScopedObjects, isNull);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(registerEventHandlerCallRecord.length, 0);
  });

  test('unregisterEventHandlers after disposed', () async {
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();

    const key = TypedScopedKey(_TestEventLoopEventHandler);
    final eventHandler = _TestEventLoopEventHandler();
    await irisMethodChannel.registerEventHandler(
        ScopedEvent(
            scopedKey: key,
            registerName: 'registerEventHandler',
            unregisterName: 'unregisterEventHandler',
            handler: eventHandler),
        jsonEncode({}));
    await irisMethodChannel.unregisterEventHandlers(key);

    final DisposableScopedObjects? subScopedObjects =
        irisMethodChannel.scopedEventHandlers.get(key);
    expect(subScopedObjects, isNull);

    final registerEventHandlerCallRecord = messenger.callApiRecords
        .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
    expect(registerEventHandlerCallRecord.length, 0);
  });

  test(
    'registerEventHandler 2 times',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler1 = _TestEventLoopEventHandler();
      final eventHandler2 = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler1),
          jsonEncode({}));
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler2),
          jsonEncode({}));

      final DisposableScopedObjects subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key)!;
      expect(subScopedObjects.keys.length, 1);

      final holder = subScopedObjects.values.elementAt(0) as EventHandlerHolder;

      expect(holder.eventHandlerHandle!(), 123456);

      expect(holder.getEventHandlers().length, 2);
      expect(holder.getEventHandlers().elementAt(0), eventHandler1);
      expect(holder.getEventHandlers().elementAt(1), eventHandler2);

      final registerEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'registerEventHandler');
      expect(registerEventHandlerCallRecord.length, 1);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'registerEventHandler 2 times with different registerName',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler1 = _TestEventLoopEventHandler();
      final eventHandler2 = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler1),
          jsonEncode({}));
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler1',
              unregisterName: 'unregisterEventHandler1',
              handler: eventHandler2),
          jsonEncode({}));

      final DisposableScopedObjects subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key)!;
      expect(subScopedObjects.keys.length, 2);

      final holder = subScopedObjects.values.elementAt(0) as EventHandlerHolder;
      expect(holder.eventHandlerHandle!(), 123456);

      expect(holder.getEventHandlers().length, 1);
      expect(holder.getEventHandlers().elementAt(0), eventHandler1);

      final holder2 =
          subScopedObjects.values.elementAt(1) as EventHandlerHolder;
      expect(holder2.eventHandlerHandle!(), 123456);

      expect(holder2.getEventHandlers().length, 1);
      expect(holder2.getEventHandlers().elementAt(0), eventHandler2);

      final registerEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'registerEventHandler');
      expect(registerEventHandlerCallRecord.length, 1);

      final registerEventHandlerCallRecord1 = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'registerEventHandler1');
      expect(registerEventHandlerCallRecord1.length, 1);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'registerEventHandler 2 times, then unregisterEventHandler',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler1 = _TestEventLoopEventHandler();
      final eventHandler2 = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler1),
          jsonEncode({}));
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler2),
          jsonEncode({}));

      await irisMethodChannel.unregisterEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler2),
          jsonEncode({}));

      final DisposableScopedObjects subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key)!;
      expect(subScopedObjects.keys.length, 1);

      final holder = subScopedObjects.values.elementAt(0) as EventHandlerHolder;

      expect(holder.eventHandlerHandle!(), 123456);

      expect(holder.getEventHandlers().length, 1);
      expect(holder.getEventHandlers().elementAt(0), eventHandler1);

      final unregisterEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
      expect(unregisterEventHandlerCallRecord.length, 0);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'registerEventHandler 2 times with different registerName, then unregisterEventHandler',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler1 = _TestEventLoopEventHandler();
      final eventHandler2 = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler1),
          jsonEncode({}));
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler1',
              unregisterName: 'unregisterEventHandler1',
              handler: eventHandler2),
          jsonEncode({}));

      await irisMethodChannel.unregisterEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler1',
              unregisterName: 'unregisterEventHandler1',
              handler: eventHandler2),
          jsonEncode({}));

      final DisposableScopedObjects subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key)!;
      expect(subScopedObjects.keys.length, 2);

      final holder = subScopedObjects.values.elementAt(0) as EventHandlerHolder;

      expect(holder.eventHandlerHandle!(), 123456);

      expect(holder.getEventHandlers().length, 1);
      expect(holder.getEventHandlers().elementAt(0), eventHandler1);

      final holder2 =
          subScopedObjects.values.elementAt(1) as EventHandlerHolder;

      expect(holder2.getEventHandlers().length, 0);

      final unregisterEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler1');
      expect(unregisterEventHandlerCallRecord.length, 1);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'registerEventHandler 2 times with different registerName, then unregisterEventHandler, then unregisterEventHandlers',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler1 = _TestEventLoopEventHandler();
      final eventHandler2 = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler1),
          jsonEncode({}));
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler1',
              unregisterName: 'unregisterEventHandler1',
              handler: eventHandler2),
          jsonEncode({}));

      await irisMethodChannel.unregisterEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler1',
              unregisterName: 'unregisterEventHandler1',
              handler: eventHandler2),
          jsonEncode({}));

      await irisMethodChannel.unregisterEventHandlers(key);

      final DisposableScopedObjects? subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key);
      expect(subScopedObjects, isNull);

      final unregisterEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
      expect(unregisterEventHandlerCallRecord.length, 1);

      final unregisterEventHandlerCallRecord1 = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler1');
      expect(unregisterEventHandlerCallRecord1.length, 1);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'registerEventHandler 2 times with different registerName, then unregisterEventHandler without await, then unregisterEventHandlers',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler1 = _TestEventLoopEventHandler();
      final eventHandler2 = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler1),
          jsonEncode({}));
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler1',
              unregisterName: 'unregisterEventHandler1',
              handler: eventHandler2),
          jsonEncode({}));

      irisMethodChannel.unregisterEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler1',
              unregisterName: 'unregisterEventHandler1',
              handler: eventHandler2),
          jsonEncode({}));

      await irisMethodChannel.unregisterEventHandlers(key);

      final DisposableScopedObjects? subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key);
      expect(subScopedObjects, isNull);

      final unregisterEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
      expect(unregisterEventHandlerCallRecord.length, 1);

      final unregisterEventHandlerCallRecord1 = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler1');
      expect(unregisterEventHandlerCallRecord1.length, 1);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'registerEventHandler 2 times with different registerName, then unregisterEventHandler without await, then unregisterEventHandlers without await',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler1 = _TestEventLoopEventHandler();
      final eventHandler2 = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler1),
          jsonEncode({}));
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler1',
              unregisterName: 'unregisterEventHandler1',
              handler: eventHandler2),
          jsonEncode({}));

      irisMethodChannel.unregisterEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler1',
              unregisterName: 'unregisterEventHandler1',
              handler: eventHandler2),
          jsonEncode({}));

      irisMethodChannel.unregisterEventHandlers(key);

      // Wait for `unregisterEventHandler/unregisterEventHandlers` completed.
      await Future.delayed(const Duration(milliseconds: 500));

      final unregisterEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
      expect(unregisterEventHandlerCallRecord.length, 1);

      final unregisterEventHandlerCallRecord1 = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler1');
      expect(unregisterEventHandlerCallRecord1.length, 1);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'registerEventHandler 2 times, then unregisterEventHandlers',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler1 = _TestEventLoopEventHandler();
      final eventHandler2 = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler1),
          jsonEncode({}));
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler2),
          jsonEncode({}));

      await irisMethodChannel.unregisterEventHandlers(key);

      final DisposableScopedObjects? subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key);
      expect(subScopedObjects, isNull);

      final registerEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
      expect(registerEventHandlerCallRecord.length, 2);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'registerEventHandler 2 times with different registerName, then unregisterEventHandlers',
    () async {
      await irisMethodChannel.initilize([]);

      const key = TypedScopedKey(_TestEventLoopEventHandler);
      final eventHandler1 = _TestEventLoopEventHandler();
      final eventHandler2 = _TestEventLoopEventHandler();
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler',
              unregisterName: 'unregisterEventHandler',
              handler: eventHandler1),
          jsonEncode({}));
      await irisMethodChannel.registerEventHandler(
          ScopedEvent(
              scopedKey: key,
              registerName: 'registerEventHandler1',
              unregisterName: 'unregisterEventHandler1',
              handler: eventHandler2),
          jsonEncode({}));

      await irisMethodChannel.unregisterEventHandlers(key);

      final DisposableScopedObjects? subScopedObjects =
          irisMethodChannel.scopedEventHandlers.get(key);
      expect(subScopedObjects, isNull);

      final registerEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler');
      expect(registerEventHandlerCallRecord.length, 1);

      final registerEventHandlerCallRecord1 = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'unregisterEventHandler1');
      expect(registerEventHandlerCallRecord1.length, 1);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'Can pass InitilizationArgProvider',
    () async {
      final argProvider = _TestInitilizationArgProvider();
      await irisMethodChannel.initilize([argProvider]);

      final registerEventHandlerCallRecord = messenger.callApiRecords
          .where((e) => e.methodCall.funcName == 'createApiEngine')
          .toList();
      final resData = registerEventHandlerCallRecord[0].apiParam.data;

      expect(Map.from(jsonDecode(resData))['args'], true);

      await irisMethodChannel.dispose();
    },
  );

  test(
    'throwExceptionHandler throw Exception by default',
    () async {
      final currentThrowExceptionHandler = throwExceptionHandler;

      expect(() => throwExceptionHandler(code: 1, message: 'message'),
          throwsA(isA<Exception>()));

      throwExceptionHandler = currentThrowExceptionHandler;
    },
  );

  test(
    'Can override throwExceptionHandler',
    () async {
      final currentThrowExceptionHandler = throwExceptionHandler;

      throwExceptionHandler = ({required int code, String? message}) {
        throw StateError('message');
      };

      expect(() => throwExceptionHandler(code: 1, message: 'message'),
          throwsA(isA<StateError>()));

      throwExceptionHandler = currentThrowExceptionHandler;
    },
  );
}

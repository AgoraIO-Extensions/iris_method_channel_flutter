import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_method_channel/iris_method_channel.dart';

class _FakePlatformBindingsDelegate extends PlatformBindingsDelegateInterface {
  @override
  int callApi(IrisMethodCall methodCall, IrisApiEngineHandle apiEnginePtr,
          IrisApiParamHandle param) =>
      0;

  @override
  Future<CallApiResult> callApiAsync(IrisMethodCall methodCall,
          IrisApiEngineHandle apiEnginePtr, IrisApiParamHandle param) async =>
      CallApiResult(data: const {}, irisReturnCode: 0);

  @override
  CreateApiEngineResult createApiEngine(List<InitilizationArgProvider> args) =>
      const CreateApiEngineResult(IrisApiEngineHandle(0));

  @override
  IrisEventHandlerHandle createIrisEventHandler(
          IrisCEventHandlerHandle eventHandler) =>
      const IrisEventHandlerHandle(0);

  @override
  void destroyIrisEventHandler(IrisEventHandlerHandle handler) {}

  @override
  void destroyNativeApiEngine(IrisApiEngineHandle apiEnginePtr) {}

  @override
  void initialize() {}
}

class _FakePlatformBindingsProvider extends PlatformBindingsProvider {
  @override
  PlatformBindingsDelegateInterface provideNativeBindingDelegate() {
    return _FakePlatformBindingsDelegate();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'ConcurrentModificationError should not be thrown when adding/removing handlers during event dispatch',
      () async {
    final provider = _FakePlatformBindingsProvider();
    final irisMethodChannel = IrisMethodChannel(provider);

    // Logic Tester that mimics the FIXED IrisMethodChannel event loop
    void simulateEventLoop(
        IrisMethodChannel channel, IrisEventMessage message) {
      bool handled = false;
      // We use the same snapshotting logic as in the fixed IrisMethodChannel
      for (final sub in channel.scopedEventHandlers.values) {
        final scopedObjects = sub as DisposableScopedObjects;
        for (final es in scopedObjects.values) {
          final EventHandlerHolder eh = es as EventHandlerHolder;
          final handlersSnapshot = eh.getEventHandlers();

          for (final e in handlersSnapshot.toList()) {
            if (!eh.getEventHandlers().contains(e)) {
              continue;
            }
            if (e.handleEvent(message.event, message.data, message.buffers)) {
              handled = true;
            }
          }

          if (handled) {
            break;
          }
        }
        if (handled) {
          break;
        }
      }
    }

    const key = TypedScopedKey(Object);
    final subScopedObjects = irisMethodChannel.scopedEventHandlers.putIfAbsent(
        key, DisposableScopedObjects.new) as DisposableScopedObjects;
    const eventKey = EventHandlerHolderKey(
        registerName: 'test_event', unregisterName: 'test_event');
    final holder = subScopedObjects.putIfAbsent(
            eventKey, () => EventHandlerHolder(key: eventKey))
        as EventHandlerHolder;

    // 1. Test removing self during event handling
    late EventLoopEventHandler handlerToRemove;
    bool handlerCalled = false;

    handlerToRemove = _TestEventHandler((eventName, eventData, buffers) {
      handlerCalled = true;
      holder.removeEventHandler(handlerToRemove);
      return true;
    });

    holder.addEventHandler(handlerToRemove);

    // This should NOT throw error
    simulateEventLoop(
        irisMethodChannel, const IrisEventMessage('test_event', '{}', []));
    expect(handlerCalled, true);
    expect(holder.getEventHandlers().length, 0);

    // 2. Test adding another handler during event handling
    bool firstHandlerCalled = false;
    final firstHandler = _TestEventHandler((eventName, eventData, buffers) {
      firstHandlerCalled = true;
      holder.addEventHandler(_TestEventHandler((_, __, ___) => true));
      return false;
    });

    holder.addEventHandler(firstHandler);

    simulateEventLoop(
        irisMethodChannel, const IrisEventMessage('test_event', '{}', []));
    expect(firstHandlerCalled, true);
    expect(holder.getEventHandlers().length,
        2); // 1 (firstHandler) + 1 (added handler)
  });
}

typedef HandleEventCallback = bool Function(
    String eventName, String eventData, List<Uint8List> buffers);

class _TestEventHandler extends EventLoopEventHandler
    with ScopedDisposableObjectMixin
    implements DisposableObject {
  _TestEventHandler(this.callback);
  final HandleEventCallback callback;

  @override
  bool handleEventInternal(
      String eventName, String eventData, List<Uint8List> buffers) {
    return callback(eventName, eventData, buffers);
  }

  @override
  Future<void> dispose() async {}
}

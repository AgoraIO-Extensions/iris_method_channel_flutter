import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iris_method_channel/src/platform/io/iris_event_io.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'IrisEvent smoke test',
    (tester) async {
      await tester.pumpWidget(Container());

      IrisEventIO irisEvent = IrisEventIO();
      irisEvent.initialize();
      final testPort = ReceivePort();
      irisEvent.registerEventHandler(testPort.sendPort);
      irisEvent.unregisterEventHandler(testPort.sendPort);
      irisEvent.onEventPtr;
      irisEvent.dispose();
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

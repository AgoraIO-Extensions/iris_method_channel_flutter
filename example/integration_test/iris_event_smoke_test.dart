
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iris_method_channel/iris_method_channel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    testWidgets('IrisEvent smoke test',
        (tester) async {
      await tester.pumpAndSettle();



      IrisEvent irisEvent = IrisEvent();
      irisEvent.initialize();
      final testPort = ReceivePort();
      irisEvent.registerEventHandler(testPort.sendPort);
      irisEvent.unregisterEventHandler(testPort.sendPort);
      irisEvent.onEventPtr;
      irisEvent.dispose();
    });
}
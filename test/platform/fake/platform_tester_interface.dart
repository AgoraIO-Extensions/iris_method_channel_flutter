import 'package:iris_method_channel/iris_method_channel.dart';

class CallApiRecordApiParam {
  CallApiRecordApiParam(this.event, this.data);
  final String event;
  final String data;
}

class CallApiRecord {
  CallApiRecord(this.methodCall, this.apiParam);
  final IrisMethodCall methodCall;
  final CallApiRecordApiParam apiParam;
}

abstract class CallApiRecorderInterface {
  List<CallApiRecord> get callApiRecords;
}

abstract class PlatformTesterInterface {
  IrisMethodChannel getIrisMethodChannel();

  CallApiRecorderInterface getCallApiRecorder();
}

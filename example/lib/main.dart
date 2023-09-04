import 'package:flutter/material.dart';
import 'package:iris_method_channel/iris_method_channel.dart';

void main() {
  runApp(const MyApp());
}

class _FakePlatformBindingsDelegateInterface
    implements PlatformBindingsDelegateInterface {
  @override
  int callApi(IrisMethodCall methodCall, IrisApiEngineHandle apiEnginePtr,
      IrisApiParamHandle param) {
    return 0;
  }

  @override
  Future<CallApiResult> callApiAsync(IrisMethodCall methodCall,
      IrisApiEngineHandle apiEnginePtr, IrisApiParamHandle param) async {
    return CallApiResult(irisReturnCode: 0, data: {});
  }

  @override
  CreateApiEngineResult createApiEngine(List<Object> args) {
    return const CreateApiEngineResult(IrisApiEngineHandle(0));
  }

  @override
  IrisEventHandlerHandle createIrisEventHandler(
      IrisCEventHandlerHandle eventHandler) {
    return const IrisEventHandlerHandle(0);
  }

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
    return _FakePlatformBindingsDelegateInterface();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    IrisMethodChannel irisMethodChannel =
        IrisMethodChannel(_FakePlatformBindingsProvider());
    await irisMethodChannel.initilize([]);
    await irisMethodChannel.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}

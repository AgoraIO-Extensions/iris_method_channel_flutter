import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';

/** IrisMethodChannelPlugin **/
export default class IrisMethodChannelPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "IrisMethodChannelPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "iris_method_channel");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      // Notify the dart side to call the `IrisMethodChannel.dispose` to clear the resources.
      this.channel.invokeMethod("onDetachedFromEngine_fromPlatform",  null);
      this.channel.setMethodCallHandler(null);
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
  }
}
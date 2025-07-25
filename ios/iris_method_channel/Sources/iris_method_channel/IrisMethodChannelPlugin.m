#import "./include/iris_method_channel/IrisMethodChannelPlugin.h"
#include "../../../../src/iris_event.h"

@implementation IrisMethodChannelPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"iris_method_channel"
            binaryMessenger:[registrar messenger]];
  IrisMethodChannelPlugin* instance = [[IrisMethodChannelPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

/// dummy function to avoid symbols striping when building static library.
+ (void)_irisMethodChannelDummyFunc {
  EventParam p;
	Iris_InitDartApiDL(NULL);
  Iris_Dispose();
  Iris_OnEvent(NULL);
  Iris_RegisterDartPort(0);
  Iris_UnregisterDartPort(0);
}

@end

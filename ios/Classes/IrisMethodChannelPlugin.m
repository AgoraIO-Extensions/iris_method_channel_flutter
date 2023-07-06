#import "IrisMethodChannelPlugin.h"
#include "../../src/iris_event.h"

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
	InitDartApiDL(NULL);
  Dispose();
  OnEvent(NULL);
  RegisterDartPort(0);
  UnregisterDartPort(0);
}

@end

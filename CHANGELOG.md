# Changelog

## [1.1.0-rc.5](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.1.0-rc.4...1.1.0-rc.5) (2023-03-16)


### Features

* allow initilize/dispose multiple times for same IrisMethodChannel object ([00d1388](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/00d13889fa39383af86703be1011579dfcc97486))


### Bug Fixes

* fix memeory leak if Dart_PostCObject_DL failed to send the message ([55f322f](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/55f322fd202c361b4cc78c1fb060109518e918aa))

## [1.1.0-rc.4](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.1.0-rc.3...1.1.0-rc.4) (2023-03-11)


### Features

* implement invokeMethodList ([15c6e38](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/15c6e3855c1a3bdfbd51101bcbda5a1b36a2c98b))

## [1.1.0-rc.3](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.1.0-rc.2...1.1.0-rc.3) (2023-02-23)


### Bug Fixes

* [windows] fix warning C4068: unknown pragma 'clang' ([f26cdba](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/f26cdba2bfebcce9f2ed5ce25468aa6427ea400f))
* fix _HotRestartFinalizer._onExitPort not be initialized in release build ([ea5f4cb](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/ea5f4cbd925e79c229d7f4013cce5d649d256990))

## [1.1.0-rc.2](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.1.0-rc.1...1.1.0-rc.2) (2023-02-16)


### Bug Fixes

* fix ConcurrentModificationError when  and  are called ynchronously but without  keyword ([4f5058d](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/4f5058d70224c8072cc8706adb4761b28cebd8fc))

## [1.1.0-rc.1](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/compare/1.0.0...1.1.0-rc.1) (2023-02-16)


### Bug Fixes

* fix registerEventHandler with same ScopedEvent.scopedKey but different registerName/unregisterName not work ([268d74b](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/268d74b1f1326dd68bc12723859159f43f5b79e6))
* fix the native API engine not be destroyed when hot restarted ([bdda662](https://github.com/AgoraIO-Extensions/iris_method_channel_flutter/commit/bdda6626de1434f5e26d12369d0fc570d7d582a6))

## 1.0.0

* Introduce `NativeBindingDelegateProvider` to allow pass custom `NativeBindingDelegate` from outside.

## 0.1.0

* Initial release.
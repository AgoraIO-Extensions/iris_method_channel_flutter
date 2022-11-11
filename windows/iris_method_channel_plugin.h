#ifndef FLUTTER_PLUGIN_IRIS_METHOD_CHANNEL_PLUGIN_H_
#define FLUTTER_PLUGIN_IRIS_METHOD_CHANNEL_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace iris_method_channel {

class IrisMethodChannelPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  IrisMethodChannelPlugin();

  virtual ~IrisMethodChannelPlugin();

  // Disallow copy and assign.
  IrisMethodChannelPlugin(const IrisMethodChannelPlugin&) = delete;
  IrisMethodChannelPlugin& operator=(const IrisMethodChannelPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace iris_method_channel

#endif  // FLUTTER_PLUGIN_IRIS_METHOD_CHANNEL_PLUGIN_H_

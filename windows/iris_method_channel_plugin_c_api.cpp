#include "include/iris_method_channel/iris_method_channel_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "iris_method_channel_plugin.h"

void IrisMethodChannelPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  iris_method_channel::IrisMethodChannelPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

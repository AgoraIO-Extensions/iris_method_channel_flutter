#ifndef __IRIS_RTC_CXX_API_H__
#define __IRIS_RTC_CXX_API_H__

#include "iris_module.h"
#include "iris_rtc_base.h"
#include "iris_video_processor_c.h"
namespace agora {
namespace iris {

namespace rtc {
class IIrisRtcEngine;
}// namespace rtc

}// namespace iris
}// namespace agora

using namespace agora::iris;

class IRIS_CPP_API IrisApiEngine {
 public:
  virtual int CallIrisApi(ApiParam *apiParam);
  /// IrisRtcEngine
  IrisApiEngine(void *rtcEngine = nullptr, const char *dir = NULL,
                int maxSize = 1048576 * 5, IrisLogLevel level = levelDebug);

  ~IrisApiEngine();

  agora::iris::rtc::IIrisRtcEngine *GetIrisRtcEngine();

  /// IrisRtcRawData
  void Attach(IrisVideoFrameBufferManagerPtr manager_ptr);

  void Detach(IrisVideoFrameBufferManagerPtr manager_ptr);

 private:
  agora::iris::rtc::IIrisRtcEngine *engine_ptr;
};

#endif

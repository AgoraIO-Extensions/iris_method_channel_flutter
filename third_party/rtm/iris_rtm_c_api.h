#ifndef __IRIS_RTM_C_API_H__
#define __IRIS_RTM_C_API_H__

#include "iris_base.h"

typedef void *IrisApiRtmEnginePtr;

IRIS_API IrisApiRtmEnginePtr IRIS_CALL CreateIrisRtmEngine(void *engine);

IRIS_API void IRIS_CALL DestroyIrisRtmEngine(IrisApiRtmEnginePtr engine);

IRIS_API int IRIS_CALL CallIrisRtmApi(IrisApiRtmEnginePtr engine_ptr,
                                      ApiParam *param);

IRIS_API IrisEventHandlerHandle IRIS_CALL
CreateIrisEventHandler(IrisCEventHandler *event_handler);

IRIS_API void IRIS_CALL DestroyIrisEventHandler(IrisEventHandlerHandle handler);

#endif
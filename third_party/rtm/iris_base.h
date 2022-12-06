//
// Created by LXH on 2021/5/10.
//

#ifndef IRIS_BASE_H_
#define IRIS_BASE_H_

#include "iris_platform.h"

EXTERN_C_ENTER

const int kBasicResultLength = 64 * 1024;
const int kEventResultLenght = 1024;
const int kBasicStringLength = 512;

typedef enum IrisAppType {
  kAppTypeNative = 0,
  kAppTypeCocos = 1,
  kAppTypeUnity = 2,
  kAppTypeElectron = 3,
  kAppTypeFlutter = 4,
  kAppTypeUnreal = 5,
  kAppTypeXamarin = 6,
  kAppTypeApiCloud = 7,
  kAppTypeReactNative = 8,
  kAppTypePython = 9,
  kAppTypeCocosCreator = 10,
  kAppTypeRust = 11,
  kAppTypeCSharp = 12,
  kAppTypeCef = 13,
  kAppTypeUniApp = 14,
} IrisAppType;

typedef enum IrisLogLevel {
  levelTrace,
  levelDebug,
  levelInfo,
  levelWarn,
  levelErr,
} IrisLogLevel;

IRIS_API void enableUseJsonArray(bool enable);

typedef struct EventParam {
  const char *event;
  const char *data;
  unsigned int data_size;
  char *result;
  void **buffer;
  unsigned int *length;
  unsigned int buffer_count;
} EventParam;

typedef struct ApiParam {
  const char *event;
  const char *data;
  unsigned int data_size;
  char *result;
  void **buffer;
  unsigned int *length;
  unsigned int buffer_count;
} ApiParam;

typedef void(IRIS_CALL *Func_Event)(EventParam *param);

typedef struct IrisCEventHandler {
  Func_Event OnEvent;
} IrisCEventHandler;

typedef void *IrisEventHandlerHandle;
typedef void *IrisVideoFrameBufferDelegateHandle;

typedef void *IrisVideoFrameBufferManagerPtr;

EXTERN_C_LEAVE

#endif//IRIS_BASE_H_

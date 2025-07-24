#ifndef IRIIS_EVENT_H_
#define IRIIS_EVENT_H_

#include "dart-sdk/include/dart_api_dl.h"

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))  __attribute__((used))
#endif

#define kBasicResultLength 64 * 1024

#ifdef __cplusplus
extern "C"
{
#endif
    typedef struct EventParam
    {
        const char *event;
        const char *data;
        unsigned int data_size;
        char *result;
        const void **buffer;
        const unsigned int *length;
        const unsigned int buffer_count;
    } EventParam;

    // Initialize `dart_api_dl.h`
    EXPORT intptr_t Iris_InitDartApiDL(void *data);

    EXPORT void Iris_Dispose();

    EXPORT void Iris_OnEvent(EventParam *param);

    EXPORT void Iris_RegisterDartPort(Dart_Port send_port);

    EXPORT void Iris_UnregisterDartPort(Dart_Port send_port);

#ifdef __cplusplus
}
#endif

#endif // IRIS_EVENT_H_

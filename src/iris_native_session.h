#pragma once

#include <cstdint>

#include "iris_event.h"

#ifdef __cplusplus
extern "C" {
#endif

EXPORT uint64_t Iris_ReserveNativeSession();

EXPORT uint64_t Iris_CreateNativeSession(
    uint64_t session_id, void *api_engine, void *event_handler,
    void *c_event_handler, Dart_Port dart_port, intptr_t destroy_api_engine,
    intptr_t destroy_event_handler);

EXPORT int Iris_AcquireNativeSession(uint64_t session_id);

EXPORT int Iris_ReleaseNativeSession(uint64_t session_id);

EXPORT int Iris_DeactivateNativeSession(uint64_t session_id);

EXPORT int Iris_DestroyNativeSession(uint64_t session_id);

EXPORT int Iris_TryDestroyNativeSession(uint64_t session_id);

EXPORT int Iris_ForceDestroyNativeSession(uint64_t session_id);

#ifdef __cplusplus
}
#endif

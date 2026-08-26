#include "iris_native_session.h"

#include <atomic>
#include <condition_variable>
#include <cstdlib>
#include <memory>
#include <mutex>
#include <unordered_map>

#if defined(__ANDROID__)
#include <jni.h>
#endif

namespace {

using DestroyResource = void (*)(void *);

enum class SessionState {
  kReserved,
  kActive,
  kDeactivated,
  kDestroying,
  kDestroyed,
};

enum class DestroyMode {
  kWait,
  kTry,
  kForce,
};

constexpr int kNativeSessionBusy = 1;

struct NativeSession {
  uint64_t id;
  void *api_engine = nullptr;
  void *event_handler = nullptr;
  void *c_event_handler = nullptr;
  Dart_Port dart_port = 0;
  DestroyResource destroy_api_engine = nullptr;
  DestroyResource destroy_event_handler = nullptr;
  bool dart_port_registered = false;
  bool destroy_when_idle = false;
  size_t active_calls = 0;
  SessionState state = SessionState::kReserved;
  int destroy_result = 0;
  std::mutex mutex;
  std::condition_variable destroyed;
};

std::atomic<uint64_t> next_session_id{1};
std::mutex sessions_mutex;
std::unordered_map<uint64_t, std::shared_ptr<NativeSession>> sessions;

std::shared_ptr<NativeSession> FindSession(uint64_t session_id) {
  std::lock_guard<std::mutex> lock(sessions_mutex);
  const auto it = sessions.find(session_id);
  return it == sessions.end() ? nullptr : it->second;
}

void RemoveSession(const std::shared_ptr<NativeSession> &session) {
  std::lock_guard<std::mutex> lock(sessions_mutex);
  const auto it = sessions.find(session->id);
  if (it != sessions.end() && it->second == session) {
    sessions.erase(it);
  }
}

int DestroyNativeSession(uint64_t session_id, DestroyMode mode) {
  const auto session = FindSession(session_id);
  if (!session) {
    return 0;
  }

  void *api_engine = nullptr;
  void *event_handler = nullptr;
  void *c_event_handler = nullptr;
  DestroyResource destroy_api_engine = nullptr;
  DestroyResource destroy_event_handler = nullptr;

  {
    std::unique_lock<std::mutex> lock(session->mutex);
    if (session->state == SessionState::kDestroying) {
      if (mode == DestroyMode::kTry) {
        return kNativeSessionBusy;
      }
      if (mode == DestroyMode::kForce) {
        session->active_calls = 0;
        session->destroyed.notify_all();
      }
      session->destroyed.wait(
          lock, [&]() { return session->state == SessionState::kDestroyed; });
      return session->destroy_result;
    }
    if (session->state == SessionState::kDestroyed) {
      return session->destroy_result;
    }

    if (session->dart_port_registered) {
      Iris_UnregisterDartPort(session->dart_port);
      session->dart_port_registered = false;
    }

    if (mode == DestroyMode::kTry && session->active_calls != 0) {
      session->destroy_when_idle = true;
      session->state = SessionState::kDeactivated;
      return kNativeSessionBusy;
    }

    session->destroy_when_idle = false;
    session->state = SessionState::kDestroying;
    if (mode == DestroyMode::kForce) {
      session->active_calls = 0;
    } else {
      session->destroyed.wait(
          lock, [&]() { return session->active_calls == 0; });
    }

    api_engine = session->api_engine;
    event_handler = session->event_handler;
    c_event_handler = session->c_event_handler;
    destroy_api_engine = session->destroy_api_engine;
    destroy_event_handler = session->destroy_event_handler;
    session->api_engine = nullptr;
    session->event_handler = nullptr;
    session->c_event_handler = nullptr;
  }

  if (api_engine != nullptr) {
    destroy_api_engine(api_engine);
    destroy_event_handler(event_handler);
    free(c_event_handler);
    Iris_Dispose();
  }

  {
    std::lock_guard<std::mutex> lock(session->mutex);
    session->state = SessionState::kDestroyed;
  }
  session->destroyed.notify_all();
  RemoveSession(session);
  return session->destroy_result;
}

}  // namespace

uint64_t Iris_ReserveNativeSession() {
  auto session = std::make_shared<NativeSession>();
  session->id = next_session_id.fetch_add(1);
  if (session->id == 0) {
    return 0;
  }

  std::lock_guard<std::mutex> lock(sessions_mutex);
  return sessions.emplace(session->id, session).second ? session->id : 0;
}

uint64_t Iris_CreateNativeSession(
    uint64_t session_id, void *api_engine, void *event_handler,
    void *c_event_handler, Dart_Port dart_port, intptr_t destroy_api_engine,
    intptr_t destroy_event_handler) {
  if (session_id == 0 || !api_engine || !event_handler || !c_event_handler ||
      dart_port == 0 || destroy_api_engine == 0 ||
      destroy_event_handler == 0) {
    return 0;
  }

  const auto session = FindSession(session_id);
  if (!session) {
    return 0;
  }

  std::lock_guard<std::mutex> lock(session->mutex);
  if (session->state != SessionState::kReserved) {
    return 0;
  }

  session->api_engine = api_engine;
  session->event_handler = event_handler;
  session->c_event_handler = c_event_handler;
  session->dart_port = dart_port;
  session->destroy_api_engine =
      reinterpret_cast<DestroyResource>(destroy_api_engine);
  session->destroy_event_handler =
      reinterpret_cast<DestroyResource>(destroy_event_handler);
  session->dart_port_registered = true;
  session->state = SessionState::kActive;
  return session_id;
}

int Iris_AcquireNativeSession(uint64_t session_id) {
  const auto session = FindSession(session_id);
  if (!session) {
    return -1;
  }

  std::lock_guard<std::mutex> lock(session->mutex);
  if (session->state != SessionState::kActive) {
    return -1;
  }
  ++session->active_calls;
  return 0;
}

int Iris_ReleaseNativeSession(uint64_t session_id) {
  const auto session = FindSession(session_id);
  if (!session) {
    return -1;
  }

  bool destroy_when_idle = false;
  {
    std::lock_guard<std::mutex> lock(session->mutex);
    if (session->active_calls == 0) {
      return -1;
    }
    --session->active_calls;
    if (session->active_calls == 0) {
      destroy_when_idle = session->destroy_when_idle;
      session->destroyed.notify_all();
    }
  }

  if (destroy_when_idle) {
    DestroyNativeSession(session_id, DestroyMode::kTry);
  }
  return 0;
}

int Iris_DeactivateNativeSession(uint64_t session_id) {
  const auto session = FindSession(session_id);
  if (!session) {
    return 0;
  }

  std::unique_lock<std::mutex> lock(session->mutex);
  if (session->state == SessionState::kDestroying) {
    return 0;
  }
  if (session->state == SessionState::kDestroyed ||
      session->state == SessionState::kDeactivated) {
    return session->destroy_result;
  }

  if (session->dart_port_registered) {
    Iris_UnregisterDartPort(session->dart_port);
    session->dart_port_registered = false;
  }
  session->state = SessionState::kDeactivated;
  return 0;
}

int Iris_DestroyNativeSession(uint64_t session_id) {
  return DestroyNativeSession(session_id, DestroyMode::kWait);
}

int Iris_TryDestroyNativeSession(uint64_t session_id) {
  return DestroyNativeSession(session_id, DestroyMode::kTry);
}

int Iris_ForceDestroyNativeSession(uint64_t session_id) {
  return DestroyNativeSession(session_id, DestroyMode::kForce);
}

#if defined(__ANDROID__)
extern "C" JNIEXPORT jlong JNICALL
Java_com_agora_iris_1method_1channel_IrisMethodChannelPlugin_nativeReserveSession(
    JNIEnv *, jclass) {
  return static_cast<jlong>(Iris_ReserveNativeSession());
}

extern "C" JNIEXPORT jint JNICALL
Java_com_agora_iris_1method_1channel_IrisMethodChannelPlugin_nativeDeactivateSession(
    JNIEnv *, jclass, jlong session_id) {
  return Iris_DeactivateNativeSession(static_cast<uint64_t>(session_id));
}

extern "C" JNIEXPORT jint JNICALL
Java_com_agora_iris_1method_1channel_IrisMethodChannelPlugin_nativeTryDestroySession(
    JNIEnv *, jclass, jlong session_id) {
  return Iris_TryDestroyNativeSession(static_cast<uint64_t>(session_id));
}

extern "C" JNIEXPORT jint JNICALL
Java_com_agora_iris_1method_1channel_IrisMethodChannelPlugin_nativeForceDestroySession(
    JNIEnv *, jclass, jlong session_id) {
  return Iris_ForceDestroyNativeSession(static_cast<uint64_t>(session_id));
}
#endif

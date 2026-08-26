#include "iris_native_session.h"

#include <cassert>
#include <chrono>
#include <condition_variable>
#include <cstdlib>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace {

std::mutex events_mutex;
std::vector<std::string> events;
std::mutex destroy_mutex;
std::condition_variable destroy_condition;
bool block_api_destroy = false;
bool api_destroy_started = false;

void Record(const char *event) {
  std::lock_guard<std::mutex> lock(events_mutex);
  events.emplace_back(event);
}

void DestroyApiEngine(void *) {
  Record("destroyApiEngine");
  std::unique_lock<std::mutex> lock(destroy_mutex);
  api_destroy_started = true;
  destroy_condition.notify_all();
  destroy_condition.wait(lock, []() { return !block_api_destroy; });
}

void DestroyEventHandler(void *) { Record("destroyEventHandler"); }

}  // namespace

extern "C" void Iris_UnregisterDartPort(Dart_Port) { Record("unregisterPort"); }

extern "C" void Iris_Dispose() { Record("disposeIrisEvent"); }

int main() {
  void *api_engine = malloc(1);
  void *event_handler = malloc(1);
  void *c_event_handler = calloc(1, 1);

  const uint64_t session_id = Iris_ReserveNativeSession();
  assert(session_id != 0);
  assert(Iris_CreateNativeSession(
      session_id, api_engine, event_handler, c_event_handler, 123,
      reinterpret_cast<intptr_t>(&DestroyApiEngine),
      reinterpret_cast<intptr_t>(&DestroyEventHandler)) == session_id);

  assert(Iris_AcquireNativeSession(session_id) == 0);
  assert(Iris_ReleaseNativeSession(session_id) == 0);

  assert(Iris_DeactivateNativeSession(session_id) == 0);
  assert(Iris_DeactivateNativeSession(session_id) == 0);
  assert(Iris_AcquireNativeSession(session_id) != 0);

  std::thread first([&]() { assert(Iris_DestroyNativeSession(session_id) == 0); });
  std::thread second([&]() { assert(Iris_DestroyNativeSession(session_id) == 0); });
  first.join();
  second.join();

  assert(Iris_DestroyNativeSession(session_id) == 0);

  const std::vector<std::string> expected = {
      "unregisterPort",
      "destroyApiEngine",
      "destroyEventHandler",
      "disposeIrisEvent",
  };
  assert(events == expected);

  free(api_engine);
  free(event_handler);

  events.clear();
  api_engine = malloc(1);
  event_handler = malloc(1);
  c_event_handler = calloc(1, 1);
  const uint64_t blocking_session_id = Iris_ReserveNativeSession();
  assert(Iris_CreateNativeSession(
      blocking_session_id, api_engine, event_handler, c_event_handler, 456,
      reinterpret_cast<intptr_t>(&DestroyApiEngine),
      reinterpret_cast<intptr_t>(&DestroyEventHandler)) ==
      blocking_session_id);
  assert(Iris_AcquireNativeSession(blocking_session_id) == 0);

  {
    std::lock_guard<std::mutex> lock(destroy_mutex);
    block_api_destroy = true;
    api_destroy_started = false;
  }

  std::thread blocking_destroy([&]() {
    assert(Iris_DestroyNativeSession(blocking_session_id) == 0);
  });

  while (Iris_AcquireNativeSession(blocking_session_id) == 0) {
    assert(Iris_ReleaseNativeSession(blocking_session_id) == 0);
    std::this_thread::yield();
  }
  assert(Iris_ReleaseNativeSession(blocking_session_id) == 0);

  {
    std::unique_lock<std::mutex> lock(destroy_mutex);
    destroy_condition.wait(lock, []() { return api_destroy_started; });
  }

  std::mutex deactivate_mutex;
  std::condition_variable deactivate_condition;
  bool deactivate_completed = false;
  std::thread deactivate([&]() {
    assert(Iris_DeactivateNativeSession(blocking_session_id) == 0);
    {
      std::lock_guard<std::mutex> lock(deactivate_mutex);
      deactivate_completed = true;
    }
    deactivate_condition.notify_all();
  });
  {
    std::unique_lock<std::mutex> lock(deactivate_mutex);
    assert(deactivate_condition.wait_for(
        lock, std::chrono::seconds(1), [&]() { return deactivate_completed; }));
  }

  {
    std::lock_guard<std::mutex> lock(destroy_mutex);
    block_api_destroy = false;
  }
  destroy_condition.notify_all();
  deactivate.join();
  blocking_destroy.join();

  free(api_engine);
  free(event_handler);

  api_engine = malloc(1);
  event_handler = malloc(1);
  c_event_handler = calloc(1, 1);
  const uint64_t forced_session_id = Iris_ReserveNativeSession();
  assert(Iris_CreateNativeSession(
      forced_session_id, api_engine, event_handler, c_event_handler, 654,
      reinterpret_cast<intptr_t>(&DestroyApiEngine),
      reinterpret_cast<intptr_t>(&DestroyEventHandler)) == forced_session_id);
  assert(Iris_AcquireNativeSession(forced_session_id) == 0);
  assert(Iris_ForceDestroyNativeSession(forced_session_id) == 0);
  assert(Iris_ReleaseNativeSession(forced_session_id) != 0);
  assert(Iris_ForceDestroyNativeSession(forced_session_id) == 0);
  free(api_engine);
  free(event_handler);

  api_engine = malloc(1);
  event_handler = malloc(1);
  c_event_handler = calloc(1, 1);
  const uint64_t idle_cleanup_session_id = Iris_ReserveNativeSession();
  assert(Iris_CreateNativeSession(
      idle_cleanup_session_id, api_engine, event_handler, c_event_handler, 987,
      reinterpret_cast<intptr_t>(&DestroyApiEngine),
      reinterpret_cast<intptr_t>(&DestroyEventHandler)) ==
      idle_cleanup_session_id);
  assert(Iris_AcquireNativeSession(idle_cleanup_session_id) == 0);
  assert(Iris_TryDestroyNativeSession(idle_cleanup_session_id) != 0);
  assert(Iris_ReleaseNativeSession(idle_cleanup_session_id) == 0);
  assert(Iris_AcquireNativeSession(idle_cleanup_session_id) != 0);
  assert(Iris_DestroyNativeSession(idle_cleanup_session_id) == 0);
  free(api_engine);
  free(event_handler);

  const uint64_t cancelled_session_id = Iris_ReserveNativeSession();
  assert(cancelled_session_id != 0);
  assert(Iris_DestroyNativeSession(cancelled_session_id) == 0);
  assert(Iris_CreateNativeSession(
      cancelled_session_id, api_engine, event_handler, c_event_handler, 789,
      reinterpret_cast<intptr_t>(&DestroyApiEngine),
      reinterpret_cast<intptr_t>(&DestroyEventHandler)) == 0);
  return 0;
}

package com.agora.iris_method_channel;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** IrisMethodChannelPlugin */
public class IrisMethodChannelPlugin
    implements FlutterPlugin, MethodCallHandler, ActivityAware {
  private static final String TAG = "IrisMethodChannel";
  private static final ExecutorService NATIVE_CLEANUP_EXECUTOR =
      Executors.newSingleThreadExecutor();
  private static final Object PENDING_CLEANUP_LOCK = new Object();
  private static final Map<Long, Boolean> PENDING_CLEANUP_SESSIONS = new HashMap<>();

  private static native long nativeReserveSession();
  private static native int nativeDeactivateSession(long sessionId);
  private static native int nativeTryDestroySession(long sessionId);
  private static native int nativeForceDestroySession(long sessionId);

  private static int deactivateNativeSession(long sessionId) {
    if (sessionId == 0L) {
      return 0;
    }

    final int deactivateResult = nativeDeactivateSession(sessionId);
    if (deactivateResult != 0) {
      Log.e(TAG, "Failed to deactivate native session " + sessionId
          + ": " + deactivateResult);
    }
    return deactivateResult;
  }

  private static void addPendingCleanup(long sessionId, boolean force) {
    if (sessionId == 0L) {
      return;
    }
    synchronized (PENDING_CLEANUP_LOCK) {
      final boolean current = Boolean.TRUE.equals(PENDING_CLEANUP_SESSIONS.get(sessionId));
      PENDING_CLEANUP_SESSIONS.put(sessionId, current || force);
    }
  }

  private static int cleanupPendingNativeSessions() {
    final Map<Long, Boolean> pendingSessions;
    synchronized (PENDING_CLEANUP_LOCK) {
      pendingSessions = new HashMap<>(PENDING_CLEANUP_SESSIONS);
    }

    int cleanupResult = 0;
    for (Map.Entry<Long, Boolean> pendingSession : pendingSessions.entrySet()) {
      final long sessionId = pendingSession.getKey();
      final boolean force = pendingSession.getValue();
      final int destroyResult = force
          ? nativeForceDestroySession(sessionId)
          : nativeTryDestroySession(sessionId);
      if (destroyResult != 0) {
        Log.e(TAG, "Failed to destroy native session " + sessionId
            + ": " + destroyResult);
        if (cleanupResult == 0) {
          cleanupResult = destroyResult;
        }
      } else {
        synchronized (PENDING_CLEANUP_LOCK) {
          PENDING_CLEANUP_SESSIONS.remove(sessionId);
        }
      }
    }
    return cleanupResult;
  }

  private static void enqueuePendingNativeSessionCleanup() {
    NATIVE_CLEANUP_EXECUTOR.execute(IrisMethodChannelPlugin::cleanupPendingNativeSessions);
  }

  private static void scheduleNativeSessionCleanup(long sessionId) {
    if (sessionId == 0L) {
      return;
    }

    deactivateNativeSession(sessionId);
    addPendingCleanup(sessionId, false);
    enqueuePendingNativeSessionCleanup();
  }

  private static void scheduleNativeSessionCleanupAfterEngineDetach(
      long sessionId, boolean force) {
    deactivateNativeSession(sessionId);
    addPendingCleanup(sessionId, false);
    new Handler(Looper.getMainLooper()).post(() -> {
      if (force) {
        addPendingCleanup(sessionId, true);
      }
      enqueuePendingNativeSessionCleanup();
    });
  }

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private long nativeSessionId;
  private long initializationGeneration;
  private boolean attachedToEngine;
  private boolean flutterEngineWillDestroy;
  private FlutterEngine flutterEngine;
  private Activity activity;
  private final FlutterEngine.EngineLifecycleListener engineLifecycleListener =
      new FlutterEngine.EngineLifecycleListener() {
        @Override
        public void onPreEngineRestart() {}

        @Override
        public void onEngineWillDestroy() {
          flutterEngineWillDestroy = true;
        }
      };

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    System.loadLibrary("iris_method_channel");
    attachedToEngine = true;
    flutterEngineWillDestroy = false;
    flutterEngine = flutterPluginBinding.getFlutterEngine();
    flutterEngine.addEngineLifecycleListener(engineLifecycleListener);
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "iris_method_channel");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if ("prepareInitialize".equals(call.method)) {
      final long previousSessionId = nativeSessionId;
      nativeSessionId = 0L;
      final long requestGeneration = ++initializationGeneration;
      final int deactivateResult = deactivateNativeSession(previousSessionId);
      addPendingCleanup(previousSessionId, false);

      final Handler mainHandler = new Handler(Looper.getMainLooper());
      NATIVE_CLEANUP_EXECUTOR.execute(() -> {
        final int destroyResult = cleanupPendingNativeSessions();
        final int cleanupResult = deactivateResult != 0
            ? deactivateResult
            : destroyResult;
        mainHandler.post(() -> {
          if (!attachedToEngine) {
            return;
          }
          if (initializationGeneration != requestGeneration) {
            result.error(
                "NativeSessionInitializationSuperseded",
                "A newer Android Iris initialization has started",
                null);
            return;
          }
          if (cleanupResult == 0) {
            final long reservedSessionId = nativeReserveSession();
            if (reservedSessionId == 0L) {
              result.error(
                  "NativeSessionReservationFailed",
                  "Failed to reserve an Android Iris session",
                  null);
            } else {
              nativeSessionId = reservedSessionId;
              result.success(reservedSessionId);
            }
          } else {
            result.error(
                "NativeSessionCleanupFailed",
                "Previous Android Iris session cleanup failed",
                cleanupResult);
          }
        });
      });
      return;
    }

    if ("registerNativeSession".equals(call.method)) {
      final Number sessionId = call.argument("sessionId");
      if (sessionId == null || sessionId.longValue() == 0L) {
        result.error("InvalidSessionId", "sessionId must be non-zero", null);
        return;
      }
      if (nativeSessionId != sessionId.longValue()) {
        result.error(
            "SessionReservationMismatch",
            "The native Iris session does not match this FlutterEngine reservation",
            nativeSessionId);
        return;
      }
      nativeSessionId = sessionId.longValue();
      result.success(true);
      return;
    }

    if ("unregisterNativeSession".equals(call.method)) {
      final Number sessionId = call.argument("sessionId");
      if (sessionId != null && nativeSessionId == sessionId.longValue()) {
        nativeSessionId = 0L;
        scheduleNativeSessionCleanup(sessionId.longValue());
      }
      result.success(true);
      return;
    }

    result.notImplemented();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    attachedToEngine = false;
    initializationGeneration++;
    final boolean forceCleanup = flutterEngineWillDestroy;
    if (flutterEngine != null) {
      flutterEngine.removeEngineLifecycleListener(engineLifecycleListener);
      flutterEngine = null;
    }
    final long detachedSessionId = nativeSessionId;
    nativeSessionId = 0L;
    if (detachedSessionId != 0L) {
      // The posted force cleanup runs after FlutterEngine.destroy has released
      // the Dart isolate. Manual plugin removal uses non-blocking cleanup.
      scheduleNativeSessionCleanupAfterEngineDetach(detachedSessionId, forceCleanup);
    } else {
      // Compatibility fallback for providers that do not support native sessions.
      channel.invokeMethod("onDetachedFromEngine_fromPlatform", null);
    }
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(
      @NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    final boolean activityFinishing = activity != null && activity.isFinishing();
    activity = null;
    if (!activityFinishing || nativeSessionId == 0L) {
      return;
    }

    final long sessionId = nativeSessionId;
    nativeSessionId = 0L;
    Log.i(TAG, "Activity finished; clean native session " + sessionId);
    scheduleNativeSessionCleanup(sessionId);
    channel.invokeMethod("onDetachedFromActivity_fromPlatform", null);
  }
}

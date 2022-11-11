import 'package:flutter/foundation.dart'
    show SynchronousFuture, visibleForTesting;

/// Disposable [ScopedObjects] which will clear all the objects from [ScopedObjects]
/// in [dispose]
class DisposableScopedObjects extends ScopedObjects
    with ScopedDisposableObjectMixin {
  @override
  Future<void> dispose() async {
    await clear();
  }
}

/// Interface to indicate the object is disposable.
abstract class DisposableObject {
  /// Dispose the object.
  Future<void> dispose();
}

/// Mixin for [DisposableObject], to let the [DisposableObject] work with
/// the [ScopedObjects]
mixin ScopedDisposableObjectMixin implements DisposableObject {
  ScopedObjects? _scopedObjects;
  ScopedKey? _scopedKey;
  bool _isDisposed = false;

  void _setScopedKey(ScopedKey scopedKey) {
    _scopedKey = scopedKey;
  }

  void _setOwner(ScopedObjects scopedObjects) {
    _scopedObjects = scopedObjects;
  }

  /// Explicitly mark the object to disposed, which will remove the object from
  /// the [ScopedObjects].
  ///
  /// NOTE that this function will not trigger the [DisposableObject.dispose].
  void markDisposed() {
    assert(_scopedKey != null);
    assert(_scopedObjects != null);

    _scopedObjects!._markDisposed(_scopedKey!);

    _isDisposed = true;
  }

  Future<void> _disposeInternal() async {
    if (_isDisposed) return SynchronousFuture(null);

    await dispose();

    markDisposed();
  }
}

/// Provider function for [DisposableObject]
typedef DisposableObjectProvider = ScopedDisposableObjectMixin Function();

/// A key object which used with [ScopedObjects]
abstract class ScopedKey {}

/// A [ScopedKey] assosiate with [Type]
class TypedScopedKey implements ScopedKey {
  /// Construct [TypedScopedKey]
  const TypedScopedKey(this.type);

  /// A [Type]
  final Type type;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TypedScopedKey && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;
}

/// Scope the objects which mixin with the [ScopedDisposableObjectMixin], all objects
/// will be disposed after [clear]
class ScopedObjects {
  @visibleForTesting
  // ignore: public_member_api_docs
  final Map<ScopedKey, ScopedDisposableObjectMixin> pool = {};
  final Set<ScopedKey> _disposedKeys = {};
  bool _isClearing = false;

  void _markDisposed(ScopedKey scopedKey) {
    if (_isClearing) {
      _disposedKeys.add(scopedKey);
    } else {
      pool.remove(scopedKey);
    }
  }

  /// Put an [ScopedDisposableObjectMixin] object if absent
  T putIfAbsent<T extends ScopedDisposableObjectMixin>(
      ScopedKey key, DisposableObjectProvider provider) {
    return pool.putIfAbsent(key, () {
      final o = provider();
      o._setOwner(this);
      o._setScopedKey(key);
      return o;
    }) as T;
  }

  /// Remove the [ScopedDisposableObjectMixin] object by key
  T? remove<T extends ScopedDisposableObjectMixin>(ScopedKey key) {
    return pool.remove(key) as T?;
  }

  /// Get the [ScopedDisposableObjectMixin] object by key
  T? get<T extends ScopedDisposableObjectMixin>(ScopedKey key) {
    return pool[key] as T?;
  }

  /// Get all the [ScopedKey]s
  Iterable<ScopedKey> get keys => pool.keys;

  /// Get all the [ScopedDisposableObjectMixin] objects
  Iterable<ScopedDisposableObjectMixin> get values => pool.values;

  /// Clear all the [ScopedDisposableObjectMixin] objects, which will trigger the
  /// [DisposableObject.dispose]
  Future<void> clear() async {
    _isClearing = true;
    final values = pool.values;
    for (final v in values) {
      await v._disposeInternal();
    }

    pool.clear();
    _isClearing = false;
  }
}

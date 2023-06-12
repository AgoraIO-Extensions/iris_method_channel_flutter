import 'package:iris_method_channel/src/scoped_objects.dart';
import 'package:test/test.dart';

class TestDisposableObject with ScopedDisposableObjectMixin {
  @override
  Future<void> dispose() async {}
}

class TestLongTimeDisposableObject with ScopedDisposableObjectMixin {
  @override
  Future<void> dispose() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

class MarkDisposeOnDisposeDisposableObject with ScopedDisposableObjectMixin {
  @override
  Future<void> dispose() async {
    markDisposed();
  }
}

void main() {
  group('ScopedObjects ', () {
    test('putIfAbsent', () {
      ScopedObjects scopedObjects = ScopedObjects();
      const key = TypedScopedKey(TestDisposableObject);
      final obj = TestDisposableObject();
      scopedObjects.putIfAbsent(key, () => obj);

      expect(scopedObjects.pool[key] == obj, isTrue);
    });

    test('remove', () {
      ScopedObjects scopedObjects = ScopedObjects();
      const key = TypedScopedKey(TestDisposableObject);
      final obj = TestDisposableObject();
      scopedObjects.putIfAbsent(key, () => obj);

      scopedObjects.remove(key);

      expect(scopedObjects.pool.isEmpty, isTrue);
    });

    test('remove when clearing, should set the value of key to null', () {
      ScopedObjects scopedObjects = ScopedObjects();
      const key = TypedScopedKey(TestDisposableObject);
      final obj = TestLongTimeDisposableObject();
      scopedObjects.putIfAbsent(key, () => obj);

      // Do not add `await` here to simulate the simultaneously calls of `clear` and `remove`
      scopedObjects.clear();

      scopedObjects.remove(key);

      final thePool = scopedObjects.pool;
      // Call remove only set the value of key to null
      expect(thePool.length, 1);
      expect(thePool[key], isNull);
    });

    test('remove when clearing, and then get, should clear the value of key',
        () async {
      ScopedObjects scopedObjects = ScopedObjects();
      const key = TypedScopedKey(TestDisposableObject);
      final obj = TestLongTimeDisposableObject();
      scopedObjects.putIfAbsent(key, () => obj);

      // Do not add `await` here to simulate the simultaneously calls of `clear` and `remove`
      scopedObjects.clear();

      scopedObjects.remove(key);

      // Wait 1000ms to ensure the `scopedObjects.clear()` is completed.
      await Future.delayed(const Duration(milliseconds: 1000));

      final getValue = scopedObjects.get(key);

      final thePool = scopedObjects.pool;
      // Call remove only set the value of key to null
      expect(thePool.length, 0);
      expect(getValue, isNull);
    });

    test('get', () {
      ScopedObjects scopedObjects = ScopedObjects();
      const key = TypedScopedKey(TestDisposableObject);
      final obj = TestDisposableObject();
      scopedObjects.putIfAbsent(key, () => obj);

      final getObj = scopedObjects.get(key);

      expect(getObj == obj, isTrue);
    });

    test('clear', () async {
      ScopedObjects scopedObjects = ScopedObjects();
      const key = TypedScopedKey(TestDisposableObject);
      final obj = TestDisposableObject();
      scopedObjects.putIfAbsent(key, () => obj);

      await scopedObjects.clear();

      expect(scopedObjects.pool.isEmpty, isTrue);
    });
  });

  group('ScopedDisposableObjectMixin ', () {
    test('markDisposed', () async {
      ScopedObjects scopedObjects = ScopedObjects();
      const key = TypedScopedKey(TestDisposableObject);
      final obj = TestDisposableObject();
      scopedObjects.putIfAbsent(key, () => obj);

      obj.markDisposed();

      expect(scopedObjects.pool.isEmpty, isTrue);
    });

    test('markDisposed inside dispose', () async {
      ScopedObjects scopedObjects = ScopedObjects();
      const key = TypedScopedKey(TestDisposableObject);
      final obj = MarkDisposeOnDisposeDisposableObject();
      scopedObjects.putIfAbsent(key, () => obj);

      await scopedObjects.clear();

      expect(scopedObjects.pool.isEmpty, isTrue);
    });
  });

  group('DisposableScopedObjects ', () {
    test('dispose', () async {
      DisposableScopedObjects disposableScopedObjects =
          DisposableScopedObjects();
      const key = TypedScopedKey(TestDisposableObject);
      final obj = TestDisposableObject();
      disposableScopedObjects.putIfAbsent(key, () => obj);

      await disposableScopedObjects.dispose();

      expect(disposableScopedObjects.pool.isEmpty, isTrue);
    });

    test('dispose in ScopedObjects.clear', () async {
      ScopedObjects scopedObjects = ScopedObjects();
      DisposableScopedObjects disposableScopedObjects =
          DisposableScopedObjects();
      const key = TypedScopedKey(TestDisposableObject);
      final obj = TestDisposableObject();
      disposableScopedObjects.putIfAbsent(key, () => obj);
      scopedObjects.putIfAbsent(const TypedScopedKey(TestDisposableObject),
          () => disposableScopedObjects);

      await scopedObjects.clear();

      expect(scopedObjects.pool.isEmpty, isTrue);
      expect(disposableScopedObjects.pool.isEmpty, isTrue);
    });
  });
}

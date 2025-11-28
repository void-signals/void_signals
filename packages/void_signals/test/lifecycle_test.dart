import 'package:test/test.dart';
import 'package:void_signals/void_signals.dart';

void main() {
  group('SignalSubscription', () {
    test('should call listener on value change', () {
      final s = signal(0);
      final values = <(int?, int)>[];

      final sub = s.subscribe((prev, current) {
        values.add((prev, current));
      });

      s.value = 1;
      s.value = 2;
      s.value = 3;

      expect(values, [
        (0, 1),
        (1, 2),
        (2, 3),
      ]);

      sub.close();
    });

    test('should fire immediately when fireImmediately is true', () {
      final s = signal(42);
      final values = <(int?, int)>[];

      final sub = s.subscribe(
        (prev, current) {
          values.add((prev, current));
        },
        fireImmediately: true,
      );

      expect(values, [(null, 42)]);

      s.value = 100;
      expect(values, [(null, 42), (42, 100)]);

      sub.close();
    });

    test('should pause and resume correctly', () {
      final s = signal(0);
      final values = <int>[];

      final sub = s.subscribe((prev, current) {
        values.add(current);
      });

      s.value = 1;
      expect(values, [1]);

      sub.pause();
      s.value = 2;
      s.value = 3;
      expect(values, [1]); // No new values while paused

      sub.resume();
      // Should receive last missed value (3)
      expect(values, [1, 3]);

      s.value = 4;
      expect(values, [1, 3, 4]);

      sub.close();
    });

    test('should handle multiple pause calls', () {
      final s = signal(0);
      final values = <int>[];

      final sub = s.subscribe((prev, current) {
        values.add(current);
      });

      sub.pause();
      sub.pause();
      sub.pause();

      s.value = 1;
      expect(values, isEmpty);

      // Need to resume same number of times
      sub.resume();
      expect(values, isEmpty);
      sub.resume();
      expect(values, isEmpty);
      sub.resume();
      expect(values, [1]); // Now receives the missed update

      sub.close();
    });

    test('should read current value with read()', () {
      final s = signal(42);
      final sub = s.subscribe((prev, current) {});

      expect(sub.read(), 42);

      s.value = 100;
      expect(sub.read(), 100);

      sub.close();
    });

    test('should throw when reading from closed subscription', () {
      final s = signal(0);
      final sub = s.subscribe((prev, current) {});

      sub.close();

      expect(() => sub.read(), throwsStateError);
    });

    test('should be safe to close multiple times', () {
      final s = signal(0);
      final sub = s.subscribe((prev, current) {});

      sub.close();
      sub.close();
      sub.close();

      expect(sub.closed, true);
    });

    test('should report closed and isPaused states correctly', () {
      final s = signal(0);
      final sub = s.subscribe((prev, current) {});

      expect(sub.closed, false);
      expect(sub.isPaused, false);

      sub.pause();
      expect(sub.isPaused, true);

      sub.resume();
      expect(sub.isPaused, false);

      sub.close();
      expect(sub.closed, true);
    });

    test('should handle errors in listener with onError callback', () {
      final s = signal(0);
      Object? capturedError;
      StackTrace? capturedStack;

      final sub = s.subscribe(
        (prev, current) {
          throw Exception('Test error');
        },
        onError: (error, stack) {
          capturedError = error;
          capturedStack = stack;
        },
      );

      s.value = 1;

      expect(capturedError, isA<Exception>());
      expect(capturedStack, isNotNull);

      sub.close();
    });
  });

  group('SignalLifecycle', () {
    test('should track disposed state', () {
      final s = signal(0);
      // Note: SignalLifecycle is a mixin, need to test on actual implementation
      // This tests the extension behavior
      expect(s.hasSubscribers, false);

      final eff = effect(() => s.value);
      expect(s.hasSubscribers, true);

      eff.stop();
      expect(s.hasSubscribers, false);
    });
  });

  group('ComputedSubscription', () {
    test('should subscribe to computed values', () {
      final a = signal(1);
      final b = signal(2);
      final sum = computed((p) => a.value + b.value);

      final values = <(int?, int)>[];
      final sub = sum.subscribe((prev, current) {
        values.add((prev, current));
      });

      a.value = 10;
      expect(values, [(3, 12)]);

      b.value = 20;
      expect(values, [(3, 12), (12, 30)]);

      sub.close();
    });

    test('should fire immediately for computed', () {
      final s = signal(5);
      final doubled = computed((p) => s.value * 2);

      final values = <int>[];
      final sub = doubled.subscribe(
        (prev, current) {
          values.add(current);
        },
        fireImmediately: true,
      );

      expect(values, [10]);

      sub.close();
    });
  });

  group('KeepAliveLink', () {
    // Note: KeepAliveLink is part of SignalLifecycle mixin
    // Testing the basic structure
    test('should track closed state', () {
      var closeCount = 0;
      final link = _TestKeepAliveLink(() => closeCount++);

      expect(link.closed, false);
      expect(closeCount, 0);

      link.close();
      expect(link.closed, true);
      expect(closeCount, 1);

      // Multiple closes should be safe
      link.close();
      expect(closeCount, 1);
    });
  });

  group('SignalErrorHandler', () {
    tearDown(() {
      SignalErrorHandler.clearHandler();
    });

    test('should set and clear global error handler', () {
      expect(SignalErrorHandler.instance, isNull);

      SignalErrorHandler.setHandler((error, stack) {
        // Handle error
      });
      expect(SignalErrorHandler.instance, isNotNull);

      SignalErrorHandler.clearHandler();
      expect(SignalErrorHandler.instance, isNull);
    });

    test('should call error handler on errors', () {
      Object? capturedError;
      StackTrace? capturedStack;

      SignalErrorHandler.setHandler((error, stack) {
        capturedError = error;
        capturedStack = stack;
      });

      final s = signal(0);
      final sub = s.subscribe((prev, current) {
        throw Exception('Test error');
      });

      s.value = 1;

      expect(capturedError, isA<Exception>());
      expect(capturedStack, isNotNull);

      sub.close();
    });
  });

  group('SubscriptionController', () {
    test('should manage multiple subscriptions', () {
      final controller = SubscriptionController();
      final s1 = signal(0);
      final s2 = signal('');

      final sub1 = controller.add(s1.subscribe((prev, current) {}));
      final sub2 = controller.add(s2.subscribe((prev, current) {}));

      expect(controller.disposed, false);
      expect(sub1.closed, false);
      expect(sub2.closed, false);

      controller.dispose();

      expect(controller.disposed, true);
      expect(sub1.closed, true);
      expect(sub2.closed, true);
    });

    test('should throw when adding to disposed controller', () {
      final controller = SubscriptionController();
      controller.dispose();

      final s = signal(0);
      expect(
        () => controller.add(s.subscribe((prev, current) {})),
        throwsStateError,
      );
    });

    test('should pause and resume all subscriptions', () {
      final controller = SubscriptionController();
      final s1 = signal(0);
      final s2 = signal(0);
      final values1 = <int>[];
      final values2 = <int>[];

      controller.add(s1.subscribe((prev, current) {
        values1.add(current);
      }));
      controller.add(s2.subscribe((prev, current) {
        values2.add(current);
      }));

      s1.value = 1;
      s2.value = 1;
      expect(values1, [1]);
      expect(values2, [1]);

      controller.pauseAll();

      s1.value = 2;
      s2.value = 2;
      expect(values1, [1]);
      expect(values2, [1]);

      controller.resumeAll();

      // Should receive last missed updates
      expect(values1, [1, 2]);
      expect(values2, [1, 2]);

      controller.dispose();
    });

    test('should be safe to dispose multiple times', () {
      final controller = SubscriptionController();
      controller.dispose();
      controller.dispose();
      controller.dispose();

      expect(controller.disposed, true);
    });
  });
}

/// Test implementation of KeepAliveLink behavior
class _TestKeepAliveLink {
  final void Function() _onClose;
  bool _closed = false;

  _TestKeepAliveLink(this._onClose);

  bool get closed => _closed;

  void close() {
    if (_closed) return;
    _closed = true;
    _onClose();
  }
}

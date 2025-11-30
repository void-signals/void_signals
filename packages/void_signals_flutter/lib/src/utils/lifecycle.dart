import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:void_signals/void_signals.dart' as signals;
import 'package:void_signals/void_signals.dart' show Signal, untrack;

// =============================================================================
// Lifecycle and Timer Signals
//
// Reactive patterns for app lifecycle, timers, intervals, and countdowns.
// =============================================================================

/// Creates a signal that tracks the app lifecycle state.
///
/// The signal updates whenever the app transitions between states like
/// resumed, inactive, paused, hidden, or detached.
///
/// **Important:** Call [AppLifecycleSignal.dispose] when no longer needed.
///
/// Example:
/// ```dart
/// final lifecycle = appLifecycleSignal();
///
/// effect(() {
///   switch (lifecycle.value) {
///     case AppLifecycleState.resumed:
///       // App is visible and responding to user input
///       analytics.trackScreenView();
///       break;
///     case AppLifecycleState.paused:
///       // App is not visible, save state
///       saveState();
///       break;
///     default:
///       break;
///   }
/// });
///
/// // Don't forget to dispose
/// lifecycle.dispose();
/// ```
AppLifecycleSignal appLifecycleSignal() => AppLifecycleSignal._();

/// A signal that tracks the app lifecycle state.
class AppLifecycleSignal with WidgetsBindingObserver {
  final Signal<AppLifecycleState> _state;
  bool _isDisposed = false;

  AppLifecycleSignal._()
      : _state = signals.signal(
          WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
        ) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// The current app lifecycle state.
  Signal<AppLifecycleState> get state => _state;

  /// The current value (convenience getter).
  AppLifecycleState get value => _state.value;

  /// Whether the app is currently resumed (visible and interactive).
  bool get isResumed => _state.value == AppLifecycleState.resumed;

  /// Whether the app is currently paused (not visible).
  bool get isPaused => _state.value == AppLifecycleState.paused;

  /// Whether the app is currently inactive.
  bool get isInactive => _state.value == AppLifecycleState.inactive;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    _state.value = state;
  }

  /// Disposes the lifecycle observer.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Creates an interval signal that updates periodically.
///
/// The signal value is the number of times the interval has fired.
///
/// **Important:** Call [IntervalSignal.dispose] when no longer needed.
///
/// Example:
/// ```dart
/// // Update every second
/// final seconds = intervalSignal(Duration(seconds: 1));
///
/// effect(() {
///   print('Tick: ${seconds.value}');
/// });
///
/// // Don't forget to dispose
/// seconds.dispose();
/// ```
IntervalSignal intervalSignal(
  Duration duration, {
  bool startImmediately = true,
}) =>
    IntervalSignal._(duration, startImmediately: startImmediately);

/// A signal that fires periodically.
class IntervalSignal {
  final Signal<int> _count;
  Timer? _timer;
  final Duration _duration;
  bool _isDisposed = false;
  bool _isPaused = false;

  IntervalSignal._(
    this._duration, {
    bool startImmediately = true,
  }) : _count = signals.signal(0) {
    if (startImmediately) {
      start();
    }
  }

  /// The number of times the interval has fired.
  Signal<int> get count => _count;

  /// The current value (convenience getter).
  int get value => _count.value;

  /// Whether the interval is currently running.
  bool get isRunning => _timer?.isActive ?? false;

  /// Whether the interval is paused.
  bool get isPaused => _isPaused;

  /// Starts the interval.
  void start() {
    if (_isDisposed) return;
    _isPaused = false;
    _timer?.cancel();
    _timer = Timer.periodic(_duration, (_) {
      if (!_isDisposed && !_isPaused) {
        _count.value++;
      }
    });
  }

  /// Pauses the interval.
  void pause() {
    _isPaused = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Resumes the interval after pausing.
  void resume() {
    if (_isDisposed || !_isPaused) return;
    start();
  }

  /// Resets the count to zero.
  void reset() {
    _count.value = 0;
  }

  /// Restarts the interval from zero.
  void restart() {
    reset();
    start();
  }

  /// Disposes the interval.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
  }
}

/// Creates a countdown signal that counts down from a starting value.
///
/// The signal value is the remaining time in the specified unit.
///
/// **Important:** Call [CountdownSignal.dispose] when no longer needed.
///
/// Example:
/// ```dart
/// // 5 minute countdown
/// final countdown = countdownSignal(
///   Duration(minutes: 5),
///   interval: Duration(seconds: 1),
/// );
///
/// // Start the countdown
/// countdown.start();
///
/// // Watch the remaining time
/// Watch(builder: (context, _) {
///   final remaining = countdown.remaining.value;
///   final minutes = remaining.inMinutes;
///   final seconds = remaining.inSeconds % 60;
///   return Text('$minutes:${seconds.toString().padLeft(2, '0')}');
/// });
///
/// // Check if finished
/// if (countdown.isFinished.value) {
///   showAlert('Time is up!');
/// }
///
/// // Don't forget to dispose
/// countdown.dispose();
/// ```
CountdownSignal countdownSignal(
  Duration duration, {
  Duration interval = const Duration(seconds: 1),
  bool startImmediately = false,
  VoidCallback? onFinished,
}) =>
    CountdownSignal._(
      duration,
      interval: interval,
      startImmediately: startImmediately,
      onFinished: onFinished,
    );

/// A signal that counts down from a starting value.
class CountdownSignal {
  final Signal<Duration> _remaining;
  final Signal<bool> _isFinished;
  final Signal<bool> _isRunning;
  final Duration _initial;
  final Duration _interval;
  final VoidCallback? _onFinished;
  Timer? _timer;
  bool _isDisposed = false;

  CountdownSignal._(
    this._initial, {
    Duration interval = const Duration(seconds: 1),
    bool startImmediately = false,
    VoidCallback? onFinished,
  })  : _remaining = signals.signal(_initial),
        _isFinished = signals.signal(false),
        _isRunning = signals.signal(false),
        _interval = interval,
        _onFinished = onFinished {
    if (startImmediately) {
      start();
    }
  }

  /// The remaining time.
  Signal<Duration> get remaining => _remaining;

  /// Whether the countdown has finished.
  Signal<bool> get isFinished => _isFinished;

  /// Whether the countdown is currently running.
  Signal<bool> get isRunning => _isRunning;

  /// The remaining seconds.
  int get remainingSeconds => _remaining.value.inSeconds;

  /// The progress from 0.0 (just started) to 1.0 (finished).
  double get progress {
    if (_initial.inMilliseconds == 0) return 1.0;
    final elapsed = _initial - _remaining.value;
    return (elapsed.inMilliseconds / _initial.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Starts the countdown.
  void start() {
    if (_isDisposed || _isRunning.value) return;

    _isRunning.value = true;
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (_isDisposed) return;

      final current = untrack(() => _remaining.value);
      final newRemaining = current - _interval;

      if (newRemaining <= Duration.zero) {
        _remaining.value = Duration.zero;
        _isFinished.value = true;
        _isRunning.value = false;
        _timer?.cancel();
        _timer = null;
        _onFinished?.call();
      } else {
        _remaining.value = newRemaining;
      }
    });
  }

  /// Pauses the countdown.
  void pause() {
    if (_isDisposed) return;
    _timer?.cancel();
    _timer = null;
    _isRunning.value = false;
  }

  /// Resumes the countdown.
  void resume() {
    if (_isDisposed || _isFinished.value) return;
    start();
  }

  /// Resets the countdown to the initial duration.
  void reset() {
    if (_isDisposed) return;
    _timer?.cancel();
    _timer = null;
    _remaining.value = _initial;
    _isFinished.value = false;
    _isRunning.value = false;
  }

  /// Restarts the countdown.
  void restart() {
    reset();
    start();
  }

  /// Adds time to the countdown.
  void addTime(Duration duration) {
    if (_isDisposed) return;
    _remaining.value = _remaining.value + duration;
    if (_isFinished.value && _remaining.value > Duration.zero) {
      _isFinished.value = false;
    }
  }

  /// Disposes the countdown.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
  }
}

/// Creates a stopwatch signal for measuring elapsed time.
///
/// **Important:** Call [StopwatchSignal.dispose] when no longer needed.
///
/// Example:
/// ```dart
/// final stopwatch = stopwatchSignal();
///
/// stopwatch.start();
///
/// Watch(builder: (context, _) {
///   final elapsed = stopwatch.elapsed.value;
///   return Text('${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}');
/// });
///
/// // Don't forget to dispose
/// stopwatch.dispose();
/// ```
StopwatchSignal stopwatchSignal({
  Duration updateInterval = const Duration(milliseconds: 100),
}) =>
    StopwatchSignal._(updateInterval: updateInterval);

/// A signal that tracks elapsed time like a stopwatch.
class StopwatchSignal {
  final Signal<Duration> _elapsed;
  final Signal<bool> _isRunning;
  final Stopwatch _stopwatch;
  final Duration _updateInterval;
  Timer? _timer;
  bool _isDisposed = false;

  StopwatchSignal._({
    Duration updateInterval = const Duration(milliseconds: 100),
  })  : _elapsed = signals.signal(Duration.zero),
        _isRunning = signals.signal(false),
        _stopwatch = Stopwatch(),
        _updateInterval = updateInterval;

  /// The elapsed time.
  Signal<Duration> get elapsed => _elapsed;

  /// Whether the stopwatch is running.
  Signal<bool> get isRunning => _isRunning;

  /// Starts the stopwatch.
  void start() {
    if (_isDisposed || _isRunning.value) return;

    _stopwatch.start();
    _isRunning.value = true;
    _timer = Timer.periodic(_updateInterval, (_) {
      if (!_isDisposed) {
        _elapsed.value = _stopwatch.elapsed;
      }
    });
  }

  /// Stops the stopwatch.
  void stop() {
    if (_isDisposed) return;
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
    _isRunning.value = false;
    _elapsed.value = _stopwatch.elapsed;
  }

  /// Resets the stopwatch to zero.
  void reset() {
    if (_isDisposed) return;
    _stopwatch.reset();
    _elapsed.value = Duration.zero;
  }

  /// Restarts the stopwatch from zero.
  void restart() {
    reset();
    start();
  }

  /// Records a lap time (returns the current elapsed time).
  Duration lap() {
    return _stopwatch.elapsed;
  }

  /// Disposes the stopwatch.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
  }
}

/// Creates a signal that updates on each frame (for animations).
///
/// **Important:** Call [FrameSignal.dispose] when no longer needed.
/// Use sparingly as this updates on every frame.
///
/// Example:
/// ```dart
/// final frame = frameSignal();
///
/// Watch(builder: (context, _) {
///   // This rebuilds on every frame - use with caution!
///   return Transform.rotate(
///     angle: frame.elapsed.value.inMilliseconds / 1000 * 2 * pi,
///     child: Icon(Icons.refresh),
///   );
/// });
///
/// // Don't forget to dispose
/// frame.dispose();
/// ```
FrameSignal frameSignal() => FrameSignal._();

/// A signal that updates on each frame.
class FrameSignal {
  final Signal<Duration> _elapsed;
  final Signal<int> _frameCount;
  final Stopwatch _stopwatch;
  Ticker? _ticker;
  bool _isDisposed = false;

  FrameSignal._()
      : _elapsed = signals.signal(Duration.zero),
        _frameCount = signals.signal(0),
        _stopwatch = Stopwatch() {
    _start();
  }

  void _start() {
    _stopwatch.start();
    _ticker = Ticker(_onTick);
    _ticker!.start();
  }

  void _onTick(Duration elapsed) {
    if (_isDisposed) return;
    _elapsed.value = _stopwatch.elapsed;
    _frameCount.value++;
  }

  /// The elapsed time since the signal was created.
  Signal<Duration> get elapsed => _elapsed;

  /// The number of frames that have elapsed.
  Signal<int> get frameCount => _frameCount;

  /// Disposes the frame signal.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _ticker?.dispose();
    _ticker = null;
    _stopwatch.stop();
  }
}

/// Creates a signal that tracks the current time, updating at the specified interval.
///
/// **Important:** Call [ClockSignal.dispose] when no longer needed.
///
/// Example:
/// ```dart
/// final clock = clockSignal();
///
/// Watch(builder: (context, _) {
///   final now = clock.now.value;
///   return Text('${now.hour}:${now.minute}:${now.second}');
/// });
///
/// // Don't forget to dispose
/// clock.dispose();
/// ```
ClockSignal clockSignal({
  Duration updateInterval = const Duration(seconds: 1),
}) =>
    ClockSignal._(updateInterval: updateInterval);

/// A signal that tracks the current time.
class ClockSignal {
  final Signal<DateTime> _now;
  Timer? _timer;
  bool _isDisposed = false;

  ClockSignal._({
    Duration updateInterval = const Duration(seconds: 1),
  }) : _now = signals.signal(DateTime.now()) {
    _timer = Timer.periodic(updateInterval, (_) {
      if (!_isDisposed) {
        _now.value = DateTime.now();
      }
    });
  }

  /// The current time.
  Signal<DateTime> get now => _now;

  /// Disposes the clock signal.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
  }
}

/// A mixin that provides lifecycle-aware signal management for StatefulWidgets.
///
/// Automatically pauses/resumes effects and timers when the app goes to background.
///
/// Example:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with LifecycleAwareSignalMixin {
///   late final CountdownSignal countdown;
///
///   @override
///   void initState() {
///     super.initState();
///     countdown = countdownSignal(Duration(minutes: 5));
///     registerTimer(countdown);
///   }
///
///   @override
///   void dispose() {
///     countdown.dispose();
///     super.dispose();
///   }
/// }
/// ```
mixin LifecycleAwareSignalMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  final List<_PausableTimer> _timers = [];
  bool _wasRunningBeforePause = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Registers a timer to be automatically paused/resumed with app lifecycle.
  void registerTimer(_PausableTimer timer) {
    _timers.add(timer);
  }

  /// Unregisters a timer from lifecycle management.
  void unregisterTimer(_PausableTimer timer) {
    _timers.remove(timer);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        for (final timer in _timers) {
          if (timer.isRunning) {
            _wasRunningBeforePause = true;
            timer.pause();
          }
        }
        break;
      case AppLifecycleState.resumed:
        if (_wasRunningBeforePause) {
          for (final timer in _timers) {
            timer.resume();
          }
          _wasRunningBeforePause = false;
        }
        break;
      default:
        break;
    }
  }

  @override
  void didChangeAccessibilityFeatures() {}

  @override
  void didChangeLocales(List<Locale>? locales) {}

  @override
  void didChangeMetrics() {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {}

  @override
  Future<bool> didPopRoute() => Future.value(false);

  @override
  Future<bool> didPushRoute(String route) => Future.value(false);

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) =>
      Future.value(false);

  @override
  Future<ui.AppExitResponse> didRequestAppExit() =>
      Future.value(ui.AppExitResponse.exit);
}

/// Interface for timers that can be paused and resumed.
abstract class _PausableTimer {
  bool get isRunning;
  void pause();
  void resume();
}

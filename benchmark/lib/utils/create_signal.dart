import '../reactive_framework.dart';

final class _Signal<T> implements Signal<T> {
  const _Signal(this._getter, this._setter);

  final T Function() _getter;
  final void Function(T _) _setter;

  @override
  @pragma('vm:prefer-inline')
  T read() => _getter();

  @override
  @pragma('vm:prefer-inline')
  void write(T value) => _setter(value);
}

@pragma('vm:prefer-inline')
Signal<T> createSignal<T>(T Function() getter, void Function(T) setter) {
  return _Signal(getter, setter);
}

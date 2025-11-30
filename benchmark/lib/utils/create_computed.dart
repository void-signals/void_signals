import '../reactive_framework.dart';

final class _Computed<T> implements Computed<T> {
  const _Computed(this._getter);

  final T Function() _getter;

  @override
  @pragma('vm:prefer-inline')
  T read() => _getter();
}

@pragma('vm:prefer-inline')
Computed<T> createComputed<T>(T Function() getter) {
  return _Computed(getter);
}

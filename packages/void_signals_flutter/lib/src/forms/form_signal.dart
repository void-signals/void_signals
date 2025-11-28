import 'package:void_signals/void_signals.dart';

import 'form_field.dart';

/// A reactive form that manages multiple [SignalField]s.
///
/// Example:
/// ```dart
/// final form = FormSignal({
///   'email': SignalField<String>(
///     initialValue: '',
///     validators: [requiredValidator(), emailValidator()],
///   ),
///   'password': SignalField<String>(
///     initialValue: '',
///     validators: [requiredValidator(), minLengthValidator(8)],
///   ),
/// });
///
/// // Check if entire form is valid
/// if (form.isValid) {
///   final data = form.values;
///   // Submit form...
/// }
/// ```
class FormSignal<K> {
  final Map<K, SignalField<dynamic>> _fields;

  /// Computed for overall form validity.
  late final Computed<bool> _isValid;

  /// Computed for form dirty state.
  late final Computed<bool> _isDirty;

  /// Computed for any field touched.
  late final Computed<bool> _isTouched;

  FormSignal(this._fields) {
    _isValid = computed((_) {
      for (final field in _fields.values) {
        if (!field.isValid) return false;
      }
      return true;
    });

    _isDirty = computed((_) {
      for (final field in _fields.values) {
        if (field.dirty) return true;
      }
      return false;
    });

    _isTouched = computed((_) {
      for (final field in _fields.values) {
        if (field.touched) return true;
      }
      return false;
    });
  }

  /// Gets a field by key.
  SignalField<T>? field<T>(K key) => _fields[key] as SignalField<T>?;

  /// Gets a field by key, throwing if not found.
  SignalField<T> requireField<T>(K key) {
    final f = _fields[key];
    if (f == null) {
      throw ArgumentError('Field with key "$key" not found');
    }
    return f as SignalField<T>;
  }

  /// Gets the value of a field.
  T? getValue<T>(K key) => field<T>(key)?.value;

  /// Sets the value of a field.
  void setValue<T>(K key, T value) {
    field<T>(key)?.value = value;
  }

  /// Gets all field values as a map.
  Map<K, dynamic> get values {
    return _fields.map((key, field) => MapEntry(key, field.value));
  }

  /// Whether the entire form is valid.
  bool get isValid => _isValid.value;

  /// Whether any field is dirty.
  bool get isDirty => _isDirty.value;

  /// Whether any field is touched.
  bool get isTouched => _isTouched.value;

  /// Gets the isValid computed.
  Computed<bool> get isValidComputed => _isValid;

  /// Gets the isDirty computed.
  Computed<bool> get isDirtyComputed => _isDirty;

  /// Validates all fields and returns whether the form is valid.
  bool validate() {
    bool allValid = true;
    for (final field in _fields.values) {
      if (!field.validate()) {
        allValid = false;
      }
    }
    return allValid;
  }

  /// Resets all fields to their initial values.
  void reset() {
    batch(() {
      for (final field in _fields.values) {
        field.reset();
      }
    });
  }

  /// Touches all fields.
  void touchAll() {
    batch(() {
      for (final field in _fields.values) {
        field.touch();
      }
    });
  }

  /// Gets all field errors as a map.
  Map<K, String?> get errors {
    return _fields.map((key, field) => MapEntry(key, field.errorMessage));
  }

  /// Creates an effect that runs when any field changes.
  Effect onFieldsChange(void Function(Map<K, dynamic> values) callback) {
    return effect(() {
      callback(values);
    });
  }

  /// Returns an iterable of all field keys.
  Iterable<K> get keys => _fields.keys;
}

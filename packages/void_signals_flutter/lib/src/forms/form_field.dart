import 'package:flutter/widgets.dart';
import 'package:void_signals/void_signals.dart';

import 'validators.dart';

/// A reactive signal-based form field with validation support.
///
/// This class is named [SignalField] to avoid conflicts with Flutter's
/// built-in [FormField] widget.
///
/// Example:
/// ```dart
/// final emailField = SignalField<String>(
///   initialValue: '',
///   validators: [
///     requiredValidator('Email is required'),
///     emailValidator('Invalid email format'),
///   ],
/// );
/// ```
class SignalField<T> {
  /// The signal holding the field value.
  final Signal<T> _value;

  /// The signal holding the touched state.
  final Signal<bool> _touched;

  /// The signal holding the dirty state (value changed from initial).
  final Signal<bool> _dirty;

  /// The list of validators.
  final List<FieldValidator<T>> validators;

  /// The initial value.
  final T initialValue;

  /// Computed validation result.
  late final Computed<FieldValidation> _validation;

  /// Computed for checking if the field has an error (touched + invalid).
  late final Computed<bool> _hasError;

  /// Computed error message.
  late final Computed<String?> _errorMessage;

  SignalField({
    required this.initialValue,
    this.validators = const [],
  })  : _value = signal(initialValue),
        _touched = signal(false),
        _dirty = signal(false) {
    _validation = computed((_) {
      final val = _value.value;
      for (final validator in validators) {
        final result = validator(val);
        if (!result.isValid) {
          return result;
        }
      }
      return const FieldValidation.valid();
    });

    _hasError = computed((_) {
      return _touched.value && !_validation.value.isValid;
    });

    _errorMessage = computed((_) {
      return _hasError.value ? _validation.value.errorMessage : null;
    });
  }

  /// Gets the current value.
  T get value => _value.value;

  /// Sets the current value.
  set value(T newValue) {
    _value.value = newValue;
    if (newValue != initialValue) {
      _dirty.value = true;
    }
  }

  /// Gets the value signal for building widgets.
  Signal<T> get valueSignal => _value;

  /// Whether the field has been touched.
  bool get touched => _touched.value;

  /// Marks the field as touched.
  void touch() => _touched.value = true;

  /// Whether the field value has changed from initial.
  bool get dirty => _dirty.value;

  /// Whether the field is valid.
  bool get isValid => _validation.value.isValid;

  /// Gets the validation result.
  FieldValidation get validation => _validation.value;

  /// Whether the field should show an error (touched and invalid).
  bool get hasError => _hasError.value;

  /// Gets the error message if any.
  String? get errorMessage => _errorMessage.value;

  /// Gets the computed for error state.
  Computed<bool> get hasErrorComputed => _hasError;

  /// Gets the computed for error message.
  Computed<String?> get errorMessageComputed => _errorMessage;

  /// Resets the field to its initial state.
  void reset() {
    batch(() {
      _value.value = initialValue;
      _touched.value = false;
      _dirty.value = false;
    });
  }

  /// Validates the field and marks it as touched.
  bool validate() {
    touch();
    return isValid;
  }
}

/// A widget that builds based on a [SignalField]'s state.
///
/// Example:
/// ```dart
/// SignalFieldBuilder<String>(
///   field: emailField,
///   builder: (context, value, errorMessage, field) {
///     return TextField(
///       controller: TextEditingController(text: value),
///       decoration: InputDecoration(
///         errorText: errorMessage,
///       ),
///       onChanged: (v) => field.value = v,
///       onEditingComplete: () => field.touch(),
///     );
///   },
/// )
/// ```
class SignalFieldBuilder<T> extends StatefulWidget {
  /// The signal field to build.
  final SignalField<T> field;

  /// Builder function.
  final Widget Function(
    BuildContext context,
    T value,
    String? errorMessage,
    SignalField<T> field,
  ) builder;

  const SignalFieldBuilder({
    super.key,
    required this.field,
    required this.builder,
  });

  @override
  State<SignalFieldBuilder<T>> createState() => _SignalFieldBuilderState<T>();
}

class _SignalFieldBuilderState<T> extends State<SignalFieldBuilder<T>> {
  Effect? _valueEffect;
  Effect? _errorEffect;
  late T _lastValue;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.field.value;
    _lastError = widget.field.errorMessage;
    _subscribeToField();
  }

  void _subscribeToField() {
    _valueEffect = effect(() {
      final newValue = widget.field.valueSignal.value;
      if (_lastValue != newValue) {
        _lastValue = newValue;
        if (mounted) setState(() {});
      }
    });

    _errorEffect = effect(() {
      final newError = widget.field.errorMessageComputed.value;
      if (_lastError != newError) {
        _lastError = newError;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(SignalFieldBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.field, widget.field)) {
      _valueEffect?.stop();
      _errorEffect?.stop();
      _lastValue = widget.field.value;
      _lastError = widget.field.errorMessage;
      _subscribeToField();
    }
  }

  @override
  void dispose() {
    _valueEffect?.stop();
    _errorEffect?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _lastValue, _lastError, widget.field);
  }
}

/// Validation result for a form field.
///
/// [FieldValidation] represents the outcome of validating a form field value.
/// It can be either valid or invalid with an associated error message.
///
/// Example:
/// ```dart
/// // Create a valid result
/// const valid = FieldValidation.valid();
/// print(valid.isValid);  // true
///
/// // Create an invalid result with an error message
/// final invalid = FieldValidation.invalid('Field is required');
/// print(invalid.isValid);       // false
/// print(invalid.errorMessage);  // 'Field is required'
/// ```
class FieldValidation {
  /// Whether the field is valid.
  final bool isValid;

  /// Error message if invalid, null otherwise.
  final String? errorMessage;

  /// Creates a valid validation result.
  const FieldValidation.valid()
      : isValid = true,
        errorMessage = null;

  /// Creates an invalid validation result with the given error message.
  const FieldValidation.invalid(this.errorMessage) : isValid = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldValidation &&
          isValid == other.isValid &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(isValid, errorMessage);
}

/// A validator function for form fields.
///
/// Validators take a value of type [T] and return a [FieldValidation]
/// indicating whether the value is valid.
///
/// Example:
/// ```dart
/// // Custom validator for positive numbers
/// FieldValidator<int> positiveValidator([String? message]) {
///   return (value) {
///     return value > 0
///       ? const FieldValidation.valid()
///       : FieldValidation.invalid(message ?? 'Must be positive');
///   };
/// }
/// ```
typedef FieldValidator<T> = FieldValidation Function(T value);

/// Creates a required field validator.
///
/// Returns invalid if the value is null, an empty string, or an empty iterable.
///
/// Example:
/// ```dart
/// final nameField = SignalField<String>(
///   initialValue: '',
///   validators: [requiredValidator('Name is required')],
/// );
/// ```
FieldValidator<T> requiredValidator<T>([String? message]) {
  return (value) {
    final isEmpty = value == null ||
        (value is String && value.isEmpty) ||
        (value is Iterable && value.isEmpty);
    return isEmpty
        ? FieldValidation.invalid(message ?? 'This field is required')
        : const FieldValidation.valid();
  };
}

/// Creates a minimum length validator for strings.
///
/// Example:
/// ```dart
/// final passwordField = SignalField<String>(
///   initialValue: '',
///   validators: [
///     requiredValidator('Password is required'),
///     minLengthValidator(8, 'Password must be at least 8 characters'),
///   ],
/// );
/// ```
FieldValidator<String> minLengthValidator(int minLength, [String? message]) {
  return (value) {
    return value.length < minLength
        ? FieldValidation.invalid(
            message ?? 'Must be at least $minLength characters')
        : const FieldValidation.valid();
  };
}

/// Creates a maximum length validator for strings.
///
/// Example:
/// ```dart
/// final usernameField = SignalField<String>(
///   initialValue: '',
///   validators: [
///     maxLengthValidator(20, 'Username cannot exceed 20 characters'),
///   ],
/// );
/// ```
FieldValidator<String> maxLengthValidator(int maxLength, [String? message]) {
  return (value) {
    return value.length > maxLength
        ? FieldValidation.invalid(
            message ?? 'Must be at most $maxLength characters')
        : const FieldValidation.valid();
  };
}

/// Creates an email validator.
///
/// Validates that the value matches a standard email format. Empty strings
/// are considered valid (use [requiredValidator] to enforce non-empty).
///
/// Example:
/// ```dart
/// final emailField = SignalField<String>(
///   initialValue: '',
///   validators: [
///     requiredValidator('Email is required'),
///     emailValidator('Please enter a valid email address'),
///   ],
/// );
/// ```
FieldValidator<String> emailValidator([String? message]) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return (value) {
    if (value.isEmpty) return const FieldValidation.valid();
    return emailRegex.hasMatch(value)
        ? const FieldValidation.valid()
        : FieldValidation.invalid(message ?? 'Invalid email format');
  };
}

/// Creates a pattern validator using a regular expression.
///
/// Example:
/// ```dart
/// final phoneField = SignalField<String>(
///   initialValue: '',
///   validators: [
///     patternValidator(
///       RegExp(r'^\+?[0-9]{10,14}$'),
///       'Please enter a valid phone number',
///     ),
///   ],
/// );
/// ```
FieldValidator<String> patternValidator(RegExp pattern, [String? message]) {
  return (value) {
    if (value.isEmpty) return const FieldValidation.valid();
    return pattern.hasMatch(value)
        ? const FieldValidation.valid()
        : FieldValidation.invalid(message ?? 'Invalid format');
  };
}

/// Creates a numeric range validator.
///
/// Validates that the value is between [min] and [max] (inclusive).
///
/// Example:
/// ```dart
/// final ageField = SignalField<int>(
///   initialValue: 18,
///   validators: [
///     rangeValidator(0, 120, 'Age must be between 0 and 120'),
///   ],
/// );
/// ```
FieldValidator<num> rangeValidator(num min, num max, [String? message]) {
  return (value) {
    return value >= min && value <= max
        ? const FieldValidation.valid()
        : FieldValidation.invalid(message ?? 'Must be between $min and $max');
  };
}

/// Combines multiple validators into one.
///
/// Validators are run in order, and the first invalid result is returned.
/// If all validators pass, a valid result is returned.
///
/// Example:
/// ```dart
/// final passwordValidator = composeValidators<String>([
///   requiredValidator('Password is required'),
///   minLengthValidator(8),
///   patternValidator(
///     RegExp(r'[A-Z]'),
///     'Must contain at least one uppercase letter',
///   ),
///   patternValidator(
///     RegExp(r'[0-9]'),
///     'Must contain at least one number',
///   ),
/// ]);
/// ```
FieldValidator<T> composeValidators<T>(List<FieldValidator<T>> validators) {
  return (value) {
    for (final validator in validators) {
      final result = validator(value);
      if (!result.isValid) return result;
    }
    return const FieldValidation.valid();
  };
}

import '../models/app_error.dart';

/// Comprehensive form validation utilities
class FormValidators {
  /// Validates required fields
  static ValidationError? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationError.required(fieldName);
    }
    return null;
  }

  /// Validates email format
  static ValidationError? email(String? value, [String fieldName = 'email']) {
    if (value == null || value.trim().isEmpty) {
      return null; // Use required validator separately
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return ValidationError.invalidFormat(fieldName, 'email address');
    }
    return null;
  }

  /// Validates minimum length
  static ValidationError? minLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null; // Use required validator separately
    }

    if (value.length < minLength) {
      return ValidationError(
        message: '$fieldName must be at least $minLength characters',
        userMessage: '$fieldName must be at least $minLength characters long.',
        fieldErrors: {
          fieldName: ['Minimum length is $minLength characters'],
        },
        code: 'MIN_LENGTH',
      );
    }
    return null;
  }

  /// Validates maximum length
  static ValidationError? maxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length > maxLength) {
      return ValidationError(
        message: '$fieldName must not exceed $maxLength characters',
        userMessage: '$fieldName must be $maxLength characters or less.',
        fieldErrors: {
          fieldName: ['Maximum length is $maxLength characters'],
        },
        code: 'MAX_LENGTH',
      );
    }
    return null;
  }

  /// Validates positive numbers
  static ValidationError? positiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null; // Use required validator separately
    }

    final number = double.tryParse(value.trim());
    if (number == null) {
      return ValidationError.invalidFormat(fieldName, 'number');
    }

    if (number <= 0) {
      return ValidationError(
        message: '$fieldName must be positive',
        userMessage: '$fieldName must be greater than zero.',
        fieldErrors: {
          fieldName: ['Must be a positive number'],
        },
        code: 'POSITIVE_NUMBER',
      );
    }
    return null;
  }

  /// Validates currency amounts (up to 2 decimal places)
  static ValidationError? currency(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null; // Use required validator separately
    }

    final currencyRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!currencyRegex.hasMatch(value.trim())) {
      return ValidationError(
        message: 'Invalid currency format',
        userMessage: 'Please enter a valid amount (e.g., 10.50).',
        fieldErrors: {
          fieldName: ['Invalid currency format'],
        },
        code: 'INVALID_CURRENCY',
      );
    }

    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return ValidationError(
        message: 'Amount must be positive',
        userMessage: 'Amount must be greater than zero.',
        fieldErrors: {
          fieldName: ['Must be a positive amount'],
        },
        code: 'POSITIVE_AMOUNT',
      );
    }

    return null;
  }

  /// Validates percentage (0-100)
  static ValidationError? percentage(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null; // Use required validator separately
    }

    final number = double.tryParse(value.trim());
    if (number == null) {
      return ValidationError.invalidFormat(fieldName, 'percentage');
    }

    if (number < 0 || number > 100) {
      return ValidationError.outOfRange(fieldName, '0-100');
    }
    return null;
  }

  /// Validates date is not in the future
  static ValidationError? notFutureDate(DateTime? date, String fieldName) {
    if (date == null) {
      return null; // Use required validator separately
    }

    if (date.isAfter(DateTime.now())) {
      return ValidationError(
        message: '$fieldName cannot be in the future',
        userMessage: 'Please select a date that is not in the future.',
        fieldErrors: {
          fieldName: ['Date cannot be in the future'],
        },
        code: 'FUTURE_DATE',
      );
    }
    return null;
  }

  /// Validates date is within a reasonable range (not too old)
  static ValidationError? reasonableDateRange(
    DateTime? date,
    String fieldName, {
    int maxYearsAgo = 10,
  }) {
    if (date == null) {
      return null; // Use required validator separately
    }

    final cutoffDate = DateTime.now().subtract(
      Duration(days: maxYearsAgo * 365),
    );
    if (date.isBefore(cutoffDate)) {
      return ValidationError(
        message: '$fieldName is too old',
        userMessage:
            'Please select a more recent date (within $maxYearsAgo years).',
        fieldErrors: {
          fieldName: ['Date is too old'],
        },
        code: 'DATE_TOO_OLD',
      );
    }
    return null;
  }

  /// Validates that percentages in a map sum to 100
  static ValidationError? percentageSum(
    Map<String, double> percentages,
    String fieldName,
  ) {
    if (percentages.isEmpty) {
      return ValidationError(
        message: 'No percentages provided',
        userMessage: 'Please specify percentage splits.',
        fieldErrors: {
          fieldName: ['At least one percentage is required'],
        },
        code: 'EMPTY_PERCENTAGES',
      );
    }

    final total = percentages.values.fold(0.0, (sum, value) => sum + value);
    if ((total - 100.0).abs() > 0.01) {
      return ValidationError(
        message: 'Percentages must sum to 100',
        userMessage: 'The percentages must add up to exactly 100%.',
        fieldErrors: {
          fieldName: ['Percentages must sum to 100%'],
        },
        code: 'PERCENTAGE_SUM',
      );
    }
    return null;
  }

  /// Validates that custom amounts sum to the total expense amount
  static ValidationError? customAmountSum(
    Map<String, double> amounts,
    double totalAmount,
    String fieldName,
  ) {
    if (amounts.isEmpty) {
      return ValidationError(
        message: 'No amounts provided',
        userMessage: 'Please specify custom amounts.',
        fieldErrors: {
          fieldName: ['At least one amount is required'],
        },
        code: 'EMPTY_AMOUNTS',
      );
    }

    final total = amounts.values.fold(0.0, (sum, value) => sum + value);
    if ((total - totalAmount).abs() > 0.01) {
      return ValidationError(
        message: 'Custom amounts must sum to total expense amount',
        userMessage:
            'The custom amounts must add up to the total expense amount (\$${totalAmount.toStringAsFixed(2)}).',
        fieldErrors: {
          fieldName: [
            'Amounts must sum to \$${totalAmount.toStringAsFixed(2)}',
          ],
        },
        code: 'AMOUNT_SUM',
      );
    }
    return null;
  }

  /// Validates that at least one participant is selected
  static ValidationError? hasParticipants(
    List<String> participants,
    String fieldName,
  ) {
    if (participants.isEmpty) {
      return ValidationError(
        message: 'No participants selected',
        userMessage: 'Please select at least one participant.',
        fieldErrors: {
          fieldName: ['At least one participant is required'],
        },
        code: 'NO_PARTICIPANTS',
      );
    }
    return null;
  }

  /// Validates that the payer is included in participants
  static ValidationError? payerInParticipants(
    String payer,
    List<String> participants,
    String fieldName,
  ) {
    if (!participants.contains(payer)) {
      return ValidationError(
        message: 'Payer must be included in participants',
        userMessage:
            'The person who paid must be included in the expense split.',
        fieldErrors: {
          fieldName: ['Payer must be a participant'],
        },
        code: 'PAYER_NOT_PARTICIPANT',
      );
    }
    return null;
  }

  /// Combines multiple validators for a single field
  static ValidationError? combine(
    List<ValidationError? Function()> validators,
  ) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}

/// Form validation result
class FormValidationResult {
  final bool isValid;
  final Map<String, List<String>> fieldErrors;
  final List<ValidationError> errors;

  const FormValidationResult({
    required this.isValid,
    required this.fieldErrors,
    required this.errors,
  });

  factory FormValidationResult.valid() {
    return const FormValidationResult(
      isValid: true,
      fieldErrors: {},
      errors: [],
    );
  }

  factory FormValidationResult.invalid(List<ValidationError> errors) {
    final fieldErrors = <String, List<String>>{};

    for (final error in errors) {
      if (error.fieldErrors != null) {
        error.fieldErrors!.forEach((field, messages) {
          fieldErrors[field] = [...(fieldErrors[field] ?? []), ...messages];
        });
      }
    }

    return FormValidationResult(
      isValid: false,
      fieldErrors: fieldErrors,
      errors: errors,
    );
  }

  /// Get error message for a specific field
  String? getFieldError(String fieldName) {
    final errors = fieldErrors[fieldName];
    return errors?.isNotEmpty == true ? errors!.first : null;
  }

  /// Get all error messages for a field
  List<String> getFieldErrors(String fieldName) {
    return fieldErrors[fieldName] ?? [];
  }

  /// Get the first general error message
  String? get firstError =>
      errors.isNotEmpty ? errors.first.displayMessage : null;
}

/// Utility class for validating entire forms
class FormValidator {
  final Map<String, List<ValidationError? Function()>> _fieldValidators = {};

  /// Add validators for a field
  void addField(
    String fieldName,
    List<ValidationError? Function()> validators,
  ) {
    _fieldValidators[fieldName] = validators;
  }

  /// Validate all fields
  FormValidationResult validate() {
    final errors = <ValidationError>[];

    for (final entry in _fieldValidators.entries) {
      for (final validator in entry.value) {
        final error = validator();
        if (error != null) {
          errors.add(error);
          break; // Stop at first error for this field
        }
      }
    }

    return errors.isEmpty
        ? FormValidationResult.valid()
        : FormValidationResult.invalid(errors);
  }

  /// Clear all validators
  void clear() {
    _fieldValidators.clear();
  }
}

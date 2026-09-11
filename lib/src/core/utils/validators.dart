/// Validation utilities for ARCHI DRAFT forms.
///
/// All validators return `null` on success or an error message string on failure.
/// Designed for use with Flutter's `TextFormField.validator` parameter.
class Validators {
  Validators._();

  /// Validates an email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    // Standard email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates a password.
  ///
  /// Requirements:
  /// - Minimum 8 characters
  /// - At least 1 uppercase letter
  /// - At least 1 lowercase letter
  /// - At least 1 digit
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number.';
    }
    return null;
  }

  /// Validates that the confirm password matches the original password.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  /// Validates a name field.
  ///
  /// Requirements:
  /// - Non-empty
  /// - 2–100 characters
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    if (value.trim().length > 100) {
      return 'Name must be 100 characters or fewer.';
    }
    return null;
  }

  /// Validates a mobile phone number.
  ///
  /// Accepts digits, optional leading +, spaces, and dashes.
  /// Must contain at least 7 digits.
  static String? mobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required.';
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Please enter a valid mobile number.';
    }
    return null;
  }

  /// Validates that a required field is not empty.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }
}

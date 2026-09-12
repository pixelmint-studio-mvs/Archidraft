import 'drawing_type.dart';

/// Validation utilities for project form fields.
///
/// Provides both individual field validators (for form fields) and
/// a composite validator for pre-submission checks.
///
/// Ref: docs/03_security/ERROR_HANDLING.md — Validation Error category.
class ProjectValidators {
  ProjectValidators._();

  // ── Field Length Limits ──
  static const int _minNameLength = 3;
  static const int _maxNameLength = 200;
  static const int _maxAddressLength = 500;
  static const double _maxProjectArea = 1000000;
  static const double _maxEstimatedAmount = 100000000;

  /// Validates project name.
  static String? projectName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Project name is required';
    }
    if (trimmed.length < _minNameLength) {
      return 'Project name must be at least $_minNameLength characters';
    }
    if (trimmed.length > _maxNameLength) {
      return 'Project name must be at most $_maxNameLength characters';
    }
    return null;
  }

  /// Validates project address.
  static String? projectAddress(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Project address is required';
    }
    if (trimmed.length < _minNameLength) {
      return 'Address must be at least $_minNameLength characters';
    }
    if (trimmed.length > _maxAddressLength) {
      return 'Address must be at most $_maxAddressLength characters';
    }
    return null;
  }

  /// Validates drawing name.
  static String? drawingName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Drawing name is required';
    }
    if (trimmed.length < _minNameLength) {
      return 'Drawing name must be at least $_minNameLength characters';
    }
    if (trimmed.length > _maxNameLength) {
      return 'Drawing name must be at most $_maxNameLength characters';
    }
    return null;
  }

  /// Validates drawing type selection.
  static String? drawingType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Drawing type is required';
    }
    if (DrawingType.fromString(value) == null) {
      return 'Invalid drawing type selected';
    }
    return null;
  }

  /// Validates project area.
  static String? projectArea(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Project area is required';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed <= 0) {
      return 'Project area must be greater than 0';
    }
    if (parsed > _maxProjectArea) {
      return 'Project area cannot exceed ${_maxProjectArea.toInt()} sq ft';
    }
    return null;
  }

  /// Validates estimated amount (optional field).
  static String? estimatedAmount(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null; // Optional field
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return 'Please enter a valid amount';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than 0';
    }
    if (parsed > _maxEstimatedAmount) {
      return 'Amount cannot exceed ${_maxEstimatedAmount.toInt()}';
    }
    return null;
  }

  /// Checks whether all required fields are valid for submission.
  ///
  /// Returns `true` if the project is ready to be submitted.
  static bool isReadyForSubmission({
    required String projectName,
    required String projectAddress,
    required String drawingName,
    required String drawingType,
    required double? projectArea,
  }) {
    return ProjectValidators.projectName(projectName) == null &&
        ProjectValidators.projectAddress(projectAddress) == null &&
        ProjectValidators.drawingName(drawingName) == null &&
        ProjectValidators.drawingType(drawingType) == null &&
        projectArea != null &&
        projectArea > 0;
  }
}

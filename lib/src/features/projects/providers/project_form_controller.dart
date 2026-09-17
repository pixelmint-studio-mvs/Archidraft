import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/project.dart';
import '../domain/project_validators.dart';
import 'project_providers.dart';

// ──────────────────────────────────────────
// FORM STATE
// ──────────────────────────────────────────

/// Immutable state for the multi-step project form.
class ProjectFormState {
  /// Current step index (0-based).
  final int currentStep;

  /// Total number of steps.
  final int totalSteps;

  /// Firestore project ID. Null = new draft not yet saved.
  final String? projectId;

  // ── Step 1: Project Information ──
  final String projectName;
  final String projectAddress;

  // ── Step 2: Drawing Requirements ──
  final String drawingName;
  final String drawingType;

  // ── Step 3: Dimensions & Budget ──
  final String projectArea;
  final String estimatedAmount;

  // ── UI State ──
  final bool isSaving;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;

  const ProjectFormState({
    this.currentStep = 0,
    this.totalSteps = 4,
    this.projectId,
    this.projectName = '',
    this.projectAddress = '',
    this.drawingName = '',
    this.drawingType = '',
    this.projectArea = '',
    this.estimatedAmount = '',
    this.isSaving = false,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
  });

  /// Whether step 1 fields are valid.
  bool get isStep1Valid =>
      ProjectValidators.projectName(projectName) == null &&
      ProjectValidators.projectAddress(projectAddress) == null;

  /// Whether step 2 fields are valid.
  bool get isStep2Valid =>
      ProjectValidators.drawingName(drawingName) == null &&
      ProjectValidators.drawingType(drawingType) == null;

  /// Whether step 3 fields are valid.
  bool get isStep3Valid =>
      ProjectValidators.projectArea(projectArea) == null &&
      ProjectValidators.estimatedAmount(estimatedAmount) == null;

  /// Whether all required fields across all steps are valid.
  bool get isReadyForSubmission => isStep1Valid && isStep2Valid && isStep3Valid;

  /// Validation for a specific step (0-indexed).
  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return isStep1Valid;
      case 1:
        return isStep2Valid;
      case 2:
        return isStep3Valid;
      case 3:
        return isReadyForSubmission;
      default:
        return false;
    }
  }

  /// Parsed project area as double.
  double? get parsedProjectArea => double.tryParse(projectArea);

  /// Parsed estimated amount as double (null if empty).
  double? get parsedEstimatedAmount {
    if (estimatedAmount.trim().isEmpty) return null;
    return double.tryParse(estimatedAmount);
  }

  ProjectFormState copyWith({
    int? currentStep,
    String? projectId,
    String? projectName,
    String? projectAddress,
    String? drawingName,
    String? drawingType,
    String? projectArea,
    String? estimatedAmount,
    bool? isSaving,
    bool? isSubmitting,
    bool? isSubmitted,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProjectFormState(
      currentStep: currentStep ?? this.currentStep,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      projectAddress: projectAddress ?? this.projectAddress,
      drawingName: drawingName ?? this.drawingName,
      drawingType: drawingType ?? this.drawingType,
      projectArea: projectArea ?? this.projectArea,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      isSaving: isSaving ?? this.isSaving,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ──────────────────────────────────────────
// FORM CONTROLLER
// ──────────────────────────────────────────

final projectFormControllerProvider =
    NotifierProvider<ProjectFormController, ProjectFormState>(
      ProjectFormController.new,
    );

/// Controller for the multi-step project form.
///
/// Manages form state, step navigation, draft persistence, and submission.
class ProjectFormController extends Notifier<ProjectFormState> {
  static const _uuid = Uuid();

  @override
  ProjectFormState build() {
    return const ProjectFormState();
  }

  // ── Field Updates ──

  void updateProjectName(String value) =>
      state = state.copyWith(projectName: value, clearError: true);

  void updateProjectAddress(String value) =>
      state = state.copyWith(projectAddress: value, clearError: true);

  void updateDrawingName(String value) =>
      state = state.copyWith(drawingName: value, clearError: true);

  void updateDrawingType(String value) =>
      state = state.copyWith(drawingType: value, clearError: true);

  void updateProjectArea(String value) =>
      state = state.copyWith(projectArea: value, clearError: true);

  void updateEstimatedAmount(String value) =>
      state = state.copyWith(estimatedAmount: value, clearError: true);

  // ── Step Navigation ──

  /// Advances to the next step if the current step is valid.
  /// Returns `true` if navigation succeeded.
  bool nextStep() {
    print('nextStep called. currentStep: ${state.currentStep}');
    if (state.currentStep >= state.totalSteps - 1) {
      print('Failed: currentStep >= totalSteps');
      return false;
    }
    
    final isValid = state.isStepValid(state.currentStep);
    print('isStepValid(${state.currentStep}) = $isValid');
    if (state.currentStep == 1) {
      print('isStep2Valid details:');
      print('drawingName: "${state.drawingName}" -> validator: ${ProjectValidators.drawingName(state.drawingName)}');
      print('drawingType: "${state.drawingType}" -> validator: ${ProjectValidators.drawingType(state.drawingType)}');
    }

    if (!isValid) return false;
    
    state = state.copyWith(
      currentStep: state.currentStep + 1,
      clearError: true,
    );
    print('Moved to step ${state.currentStep}');
    return true;
  }

  /// Goes back to the previous step. Always works.
  void previousStep() {
    if (state.currentStep <= 0) return;
    state = state.copyWith(
      currentStep: state.currentStep - 1,
      clearError: true,
    );
  }

  /// Jumps to a specific step (for "Edit" from review screen).
  void goToStep(int step) {
    if (step < 0 || step >= state.totalSteps) return;
    state = state.copyWith(currentStep: step, clearError: true);
  }

  // ── Draft Persistence ──

  /// Saves the current form state as a Firestore draft.
  ///
  /// If `projectId` is null, creates a new draft.
  /// If `projectId` exists, updates the existing draft.
  Future<void> saveDraft() async {
    if (state.isSaving || state.isSubmitting) return;
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final authState = ref.read(authStateChangesProvider);
      final user = authState.value;
      if (user == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Please sign in to save your project.',
        );
        return;
      }

      final repository = ref.read(projectRepositoryProvider);

      final project = Project(
        projectId: state.projectId ?? '',
        projectName: state.projectName.trim(),
        projectAddress: state.projectAddress.trim(),
        drawingName: state.drawingName.trim(),
        drawingType: state.drawingType,
        projectArea: state.parsedProjectArea,
        estimatedAmount: state.parsedEstimatedAmount,
        clientId: user.uid,
        status: 'DRAFT',
      );

      if (state.projectId == null) {
        // Create new draft
        final newId = await repository.createDraft(project);
        state = state.copyWith(projectId: newId, isSaving: false);
      } else {
        // Update existing draft
        await repository.updateDraft(project);
        state = state.copyWith(isSaving: false);
      }

      // Invalidate project list to reflect changes
      ref.invalidate(clientProjectsProvider);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save draft. Please try again.',
      );
    }
  }

  /// Loads an existing draft into the form for editing.
  void loadDraft(Project project) {
    state = ProjectFormState(
      projectId: project.projectId,
      projectName: project.projectName,
      projectAddress: project.projectAddress,
      drawingName: project.drawingName,
      drawingType: project.drawingType,
      projectArea: project.projectArea?.toString() ?? '',
      estimatedAmount: project.estimatedAmount?.toString() ?? '',
    );
  }

  // ── Submission ──

  /// Submits the project via the Cloud Function.
  ///
  /// Generates a deterministic actionId for idempotency.
  Future<void> submitProject() async {
    if (state.isSubmitting || state.isSaving) return;
    if (!state.isReadyForSubmission) {
      state = state.copyWith(
        errorMessage: 'Please complete all required fields before submitting.',
      );
      return;
    }

    // Ensure draft is saved first
    if (state.projectId == null) {
      await saveDraft();
      if (state.projectId == null) return; // Save failed
    } else {
      // Save latest changes before submitting
      await saveDraft();
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final repository = ref.read(projectRepositoryProvider);

      // Generate a deterministic actionId for this submission attempt.
      // Using v5 (name-based) ensures the same actionId on retry.
      final actionId = _uuid.v5(
        Namespace.url.value,
        'submit:${state.projectId}',
      );

      await repository.submitProject(
        projectId: state.projectId!,
        actionId: actionId,
      );

      state = state.copyWith(isSubmitting: false, isSubmitted: true);

      // Invalidate providers to reflect the new status
      ref.invalidate(clientProjectsProvider);
      ref.invalidate(projectProvider(state.projectId!));
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit project. Please try again.',
      );
    }
  }

  /// Resets the form to its initial state.
  void reset() {
    state = const ProjectFormState();
  }
}

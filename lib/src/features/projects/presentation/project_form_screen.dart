import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import '../../domain/drawing_type.dart';
import '../../domain/project_validators.dart';
import '../../providers/project_form_controller.dart';
import '../../providers/project_providers.dart';
import 'widgets/project_form_stepper.dart';
import 'widgets/project_review_section.dart';

/// Multi-step project brief form.
///
/// Steps:
/// 1. Project Information (name, address)
/// 2. Drawing Requirements (name, type)
/// 3. Dimensions & Budget (area, amount)
/// 4. Review & Submit (read-only summary)
///
/// Stitch design: outlined inputs with subtle fill, generous padding.
class ProjectFormScreen extends ConsumerStatefulWidget {
  /// Optional project ID — if provided, loads existing draft for editing.
  final String? projectId;

  const ProjectFormScreen({super.key, this.projectId});

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _autovalidate = false;

  static const _stepTitles = ['Project', 'Drawing', 'Budget', 'Review'];

  @override
  void initState() {
    super.initState();
    // If editing an existing project, load it
    if (widget.projectId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingDraft();
      });
    }
  }

  Future<void> _loadExistingDraft() async {
    final repository = ref.read(projectRepositoryProvider);
    final project = await repository.getProject(widget.projectId!);
    if (project != null && mounted) {
      ref.read(projectFormControllerProvider.notifier).loadDraft(project);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(projectFormControllerProvider);
    final controller = ref.read(projectFormControllerProvider.notifier);

    // Listen for submission success
    ref.listen(projectFormControllerProvider, (prev, next) {
      if (next.isSubmitted && !(prev?.isSubmitted ?? false)) {
        _showSuccessAndNavigate();
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(controller, formState);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          title: Text(
            formState.projectId == null ? 'New Project' : 'Edit Draft',
            style: AppTypography.buttonText.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _handleBack(controller, formState),
          ),
          actions: [
            if (formState.isSaving)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondary,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () => controller.saveDraft(),
                child: Text(
                  'Save Draft',
                  style: AppTypography.buttonText.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: ProjectFormStepper(
              currentStep: formState.currentStep,
              totalSteps: formState.totalSteps,
              stepTitles: _stepTitles,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: _autovalidate
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: _buildCurrentStep(formState, controller),
        ),
        bottomNavigationBar: _buildBottomBar(formState, controller),
      ),
    );
  }

  Widget _buildCurrentStep(
    ProjectFormState formState,
    ProjectFormController controller,
  ) {
    switch (formState.currentStep) {
      case 0:
        return _buildStep1(formState, controller);
      case 1:
        return _buildStep2(formState, controller);
      case 2:
        return _buildStep3(formState, controller);
      case 3:
        return ProjectReviewSection(
          formState: formState,
          onEditStep: (step) => controller.goToStep(step),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Project Information ──
  Widget _buildStep1(
    ProjectFormState formState,
    ProjectFormController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Information',
            style: AppTypography.headlineLgMobile.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tell us about your project. This information helps us understand the scope.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildTextField(
            label: 'Project Name',
            hint: 'e.g. Civic Center Pavilion',
            value: formState.projectName,
            onChanged: controller.updateProjectName,
            validator: ProjectValidators.projectName,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildTextField(
            label: 'Project Address',
            hint: 'Full address of the project location',
            value: formState.projectAddress,
            onChanged: controller.updateProjectAddress,
            validator: ProjectValidators.projectAddress,
            textInputAction: TextInputAction.done,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ── Step 2: Drawing Requirements ──
  Widget _buildStep2(
    ProjectFormState formState,
    ProjectFormController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drawing Requirements',
            style: AppTypography.headlineLgMobile.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Specify the type of architectural drawing you need.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildTextField(
            label: 'Drawing Name',
            hint: 'e.g. Ground Floor Layout',
            value: formState.drawingName,
            onChanged: controller.updateDrawingName,
            validator: ProjectValidators.drawingName,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildDropdown(
            label: 'Drawing Type',
            value: formState.drawingType.isEmpty
                ? null
                : formState.drawingType,
            items: DrawingType.values.map((type) {
              return DropdownMenuItem(
                value: type.toFirestoreString(),
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) controller.updateDrawingType(value);
            },
            validator: ProjectValidators.drawingType,
          ),
        ],
      ),
    );
  }

  // ── Step 3: Dimensions & Budget ──
  Widget _buildStep3(
    ProjectFormState formState,
    ProjectFormController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dimensions & Budget',
            style: AppTypography.headlineLgMobile.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Provide the project area and optionally your budget estimate.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildTextField(
            label: 'Project Area (sq ft)',
            hint: 'e.g. 2500',
            value: formState.projectArea,
            onChanged: controller.updateProjectArea,
            validator: ProjectValidators.projectArea,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildTextField(
            label: 'Estimated Budget (optional)',
            hint: 'Your budget estimate',
            value: formState.estimatedAmount,
            onChanged: controller.updateEstimatedAmount,
            validator: ProjectValidators.estimatedAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            isOptional: true,
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar ──
  Widget _buildBottomBar(
    ProjectFormState formState,
    ProjectFormController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            if (formState.currentStep > 0)
              OutlinedButton(
                onPressed: controller.previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: Text('Back', style: AppTypography.buttonText),
              ),

            const Spacer(),

            // Next / Submit button
            if (formState.currentStep < formState.totalSteps - 1)
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    controller.nextStep();
                    setState(() => _autovalidate = false);
                  } else {
                    setState(() => _autovalidate = true);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Next', style: AppTypography.buttonText.copyWith(
                      color: AppColors.onSecondary,
                    )),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              )
            else
              // Submit button on review step
              FilledButton(
                onPressed: formState.isSubmitting || !formState.isReadyForSubmission
                    ? null
                    : () => _showSubmitConfirmation(controller),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.outlineVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: formState.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Submit Project',
                            style: AppTypography.buttonText.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Shared Form Widgets ──

  Widget _buildTextField({
    required String label,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    required String? Function(String?) validator,
    TextInputAction textInputAction = TextInputAction.done,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (isOptional)
              Text(
                '  (OPTIONAL)',
                style: AppTypography.labelMono.copyWith(
                  color: AppColors.outline,
                  fontSize: 9,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          validator: validator,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMd.copyWith(
              color: AppColors.outline.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.secondary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
            errorStyle: AppTypography.bodySm.copyWith(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMono.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          dropdownColor: AppColors.surfaceContainerLowest,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: InputDecoration(
            hintText: 'Select drawing type',
            hintStyle: AppTypography.bodyMd.copyWith(
              color: AppColors.outline.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.secondary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            errorStyle: AppTypography.bodySm.copyWith(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ── Actions ──

  void _handleBack(
    ProjectFormController controller,
    ProjectFormState formState,
  ) {
    if (formState.currentStep > 0) {
      controller.previousStep();
    } else {
      // On first step, ask to save or discard
      _showExitConfirmation(controller);
    }
  }

  void _showExitConfirmation(ProjectFormController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text(
          'Save Draft?',
          style: AppTypography.headlineLgMobile.copyWith(fontSize: 20),
        ),
        content: Text(
          'Would you like to save your progress before leaving?',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.reset();
              this.context.go('/client/projects');
            },
            child: Text(
              'Discard',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.saveDraft();
              if (mounted) {
                controller.reset();
                this.context.go('/client/projects');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: Text(
              'Save & Exit',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitConfirmation(ProjectFormController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text(
          'Submit Project?',
          style: AppTypography.headlineLgMobile.copyWith(fontSize: 20),
        ),
        content: Text(
          'Once submitted, this project brief will be reviewed by our team. You will not be able to edit it after submission.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.submitProject();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              'Confirm Submit',
              style: AppTypography.buttonText.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Project submitted successfully!',
              style: AppTypography.bodyMd.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
    ref.read(projectFormControllerProvider.notifier).reset();
    context.go('/client/projects');
  }
}



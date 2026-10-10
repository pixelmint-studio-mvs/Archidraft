import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';

import 'package:archi_draft/src/features/projects/domain/drawing_type.dart';
import 'package:archi_draft/src/features/projects/domain/project_validators.dart';
import 'package:archi_draft/src/features/projects/providers/project_form_controller.dart';
import 'package:archi_draft/src/features/projects/providers/project_providers.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/profile/providers/profile_providers.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/file_upload_button.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/file_attachment_card.dart';

/// Single-page project brief form.
///
/// Stitch design: outlined inputs with left-accent focus, generous padding, blueprint background.
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

  @override
  void initState() {
    super.initState();
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
    final role = ref.watch(currentUserRoleProvider);

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
        _showExitConfirmation(controller);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ColorFilter.mode(Colors.white.withValues(alpha: 0.6), BlendMode.srcOver),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.architecture, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                role?.name.toUpperCase() ?? 'ENGINEER',
                style: AppTypography.headlineLgMobile.copyWith(
                  color: AppColors.primary,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
            onPressed: () => _showExitConfirmation(controller),
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
                onPressed: (formState.isSaving || formState.isSubmitting)
                    ? null
                    : () async {
                        final success = await controller.saveDraft();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Draft saved successfully.'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      },
                child: Text(
                  'Save Draft',
                  style: AppTypography.buttonText.copyWith(
                    color: (formState.isSaving || formState.isSubmitting)
                        ? AppColors.outline
                        : AppColors.secondary,
                  ),
                ),
              ),
          ],
        ),
        body: CustomPaint(
          painter: BlueprintGridPainter(
            lineColor: AppColors.outlineVariant.withValues(alpha: 0.3),
            spacing: 40.0,
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidate
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 896),
                  child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Initiate Project',
                    style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    'SUBMISSION_PORTAL_V1.2',
                    style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  _StitchFormField(
                    label: 'PROJECT_TITLE',
                    hint: 'e.g., Commercial HVAC Layout Phase 2',
                    value: formState.projectName,
                    onChanged: controller.updateProjectName,
                    validator: ProjectValidators.projectName,
                    textInputAction: TextInputAction.next,
                  ),
                  
                  _StitchFormField(
                    label: 'PROJECT_ADDRESS',
                    hint: 'Full address of the project location',
                    value: formState.projectAddress,
                    onChanged: controller.updateProjectAddress,
                    validator: ProjectValidators.projectAddress,
                    textInputAction: TextInputAction.next,
                    maxLines: 2,
                  ),

                  _StitchFormField(
                    label: 'DRAWING_NAME',
                    hint: 'e.g., Ground Floor Layout',
                    value: formState.drawingName,
                    onChanged: controller.updateDrawingName,
                    validator: ProjectValidators.drawingName,
                    textInputAction: TextInputAction.next,
                  ),

                  _StitchDropdownField(
                    label: 'TECHNICAL_CATEGORY',
                    value: formState.drawingType.isEmpty ? null : formState.drawingType,
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

                  _StitchFormField(
                    label: 'PROJECT_AREA_SQFT',
                    hint: 'e.g., 2500',
                    value: formState.projectArea,
                    onChanged: controller.updateProjectArea,
                    validator: ProjectValidators.projectArea,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                  ),

                  _StitchFormField(
                    label: 'ESTIMATED_BUDGET',
                    hint: 'Your budget estimate',
                    value: formState.estimatedAmount,
                    onChanged: controller.updateEstimatedAmount,
                    validator: ProjectValidators.estimatedAmount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    isOptional: true,
                  ),

                  _buildUploadArea(formState, controller),

                  _buildEstimateCard(formState),

                  FilledButton(
                    onPressed: (formState.isSubmitting || formState.isSaving)
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _showSubmitConfirmation(controller);
                            } else {
                              setState(() => _autovalidate = true);
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.outlineVariant,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    ),
                    child: formState.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'INITIATE DRAFTING',
                                style: AppTypography.buttonText.copyWith(color: AppColors.onPrimary),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Text(
                      'UI/UX Design & Product Experience crafted by PixelMint Studio MVS',
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 11,
                        color: AppColors.outline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea(ProjectFormState formState, ProjectFormController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOURCE_FILES (CAD/PDF)',
            style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (formState.projectId == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.save_outlined, color: AppColors.secondary, size: 40),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Save your draft first to upload files.',
                    style: AppTypography.buttonText.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonal(
                    onPressed: (formState.isSaving || formState.isSubmitting)
                        ? null
                        : () async {
                            final success = await controller.saveDraft();
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Draft saved successfully.'),
                                  backgroundColor: AppColors.secondary,
                                ),
                              );
                            }
                          },
                    child: const Text('Save Draft Now'),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: FileUploadButton(
                projectId: formState.projectId!,
                category: 'client_upload',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ref.watch(projectFilesProvider(formState.projectId!)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading files: $err', style: TextStyle(color: AppColors.error)),
              data: (files) {
                final clientFiles = files.where((f) => f.category == 'client_upload' && f.status != 'FAILED').toList();
                if (clientFiles.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      'No source files uploaded yet. Upload reference files to provide context for your request.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                return Column(
                  children: clientFiles.map((f) => FileAttachmentCard(file: f)).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstimateCard(ProjectFormState formState) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 4,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(color: AppColors.secondary),
                ),
                Expanded(
                  flex: 2,
                  child: Container(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'PRELIMINARY_ESTIMATE',
            style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EST. COST',
                      style: AppTypography.labelMono.copyWith(color: AppColors.outline, fontSize: 10),
                    ),
                    Text(
                      '--',
                      style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary, letterSpacing: -1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIMELINE',
                      style: AppTypography.labelMono.copyWith(color: AppColors.outline, fontSize: 10),
                    ),
                    Text(
                      '--',
                      style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary, letterSpacing: -1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '*Automated estimates are not currently available. Estimates will be shown here when calculation data is available.',
            style: AppTypography.labelMono.copyWith(color: AppColors.outline, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(ProjectFormController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        title: Text('Save Draft?', style: AppTypography.headlineLgMobile.copyWith(fontSize: 20)),
        content: Text(
          'Would you like to save your progress before leaving?',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.reset();
              this.context.go('/engineer/projects');
            },
            child: Text('Discard', style: AppTypography.buttonText.copyWith(color: AppColors.error)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.saveDraft();
              if (mounted) {
                controller.reset();
                this.context.go('/engineer/projects');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            child: Text('Save & Exit', style: AppTypography.buttonText.copyWith(color: AppColors.onSecondary)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        title: Text('Submit Project?', style: AppTypography.headlineLgMobile.copyWith(fontSize: 20)),
        content: Text(
          'Once submitted, this project brief will be reviewed by our team. You will not be able to edit it after submission.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTypography.buttonText.copyWith(color: AppColors.onSurface)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.submitProject();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: Text('Confirm Submit', style: AppTypography.buttonText.copyWith(color: Colors.white)),
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
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text('Project submitted successfully!', style: AppTypography.bodyMd.copyWith(color: Colors.white)),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
    ref.read(projectFormControllerProvider.notifier).reset();
    context.go('/engineer/projects');
  }
}

class _StitchFormField extends StatefulWidget {
  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final String? Function(String?) validator;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final int maxLines;
  final bool isOptional;

  const _StitchFormField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    required this.validator,
    this.textInputAction = TextInputAction.done,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.isOptional = false,
  });

  @override
  State<_StitchFormField> createState() => _StitchFormFieldState();
}

class _StitchFormFieldState extends State<_StitchFormField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: _isFocused ? AppColors.secondary : Colors.transparent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.label,
                      style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    if (!widget.isOptional)
                      Text(
                        ' *',
                        style: AppTypography.labelMono.copyWith(color: AppColors.error),
                      )
                    else
                      Text(
                        '  (OPTIONAL)',
                        style: AppTypography.labelMono.copyWith(color: AppColors.outline, fontSize: 9),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Focus(
                  onFocusChange: (focused) => setState(() => _isFocused = focused),
                  child: TextFormField(
                    initialValue: widget.value,
                    onChanged: widget.onChanged,
                    validator: widget.validator,
                    textInputAction: widget.textInputAction,
                    keyboardType: widget.keyboardType,
                    maxLines: widget.maxLines,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: AppSpacing.md),
                      border: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.outlineVariant)),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.outlineVariant)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondary, width: 1)),
                      errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                      focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error, width: 1)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StitchDropdownField extends StatefulWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?) validator;

  const _StitchDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.validator,
  });

  @override
  State<_StitchDropdownField> createState() => _StitchDropdownFieldState();
}

class _StitchDropdownFieldState extends State<_StitchDropdownField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: _isFocused ? AppColors.secondary : Colors.transparent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.label,
                      style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      ' *',
                      style: AppTypography.labelMono.copyWith(color: AppColors.error),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Focus(
                  onFocusChange: (focused) => setState(() => _isFocused = focused),
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.value,
                    items: widget.items,
                    onChanged: widget.onChanged,
                    validator: widget.validator,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                    dropdownColor: AppColors.surfaceContainerLowest,
                    icon: const Icon(Icons.expand_more, color: AppColors.outlineVariant),
                    decoration: InputDecoration(
                      hintText: 'Select category',
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: AppSpacing.md),
                      border: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.outlineVariant)),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.outlineVariant)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondary, width: 1)),
                      errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                      focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error, width: 1)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BlueprintGridPainter extends CustomPainter {
  final Color lineColor;
  final double spacing;

  BlueprintGridPainter({required this.lineColor, this.spacing = 40.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/blueprint_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_form_field.dart';

class ProvisionProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback onProvisioned;

  const ProvisionProfileScreen({super.key, required this.onProvisioned});

  @override
  ConsumerState<ProvisionProfileScreen> createState() =>
      _ProvisionProfileScreenState();
}

class _ProvisionProfileScreenState
    extends ConsumerState<ProvisionProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  String _selectedRole = 'ENGINEER';

  Uint8List? _proofBytes;
  String? _proofFileName;
  int _proofFileSize = 0;
  String? _proofError;

  String get _requiredProofLabel {
    switch (_selectedRole.toUpperCase()) {
      case 'STUDENT':
        return 'Valid Student ID card';
      case 'DRAUGHTSMAN':
        return 'Draughtsmanship degree, diploma, or relevant qualification certificate';
      case 'ENGINEER':
      default:
        return 'Engineering degree or relevant qualification certificate';
    }
  }

  String get _proofDocType {
    switch (_selectedRole.toUpperCase()) {
      case 'STUDENT':
        return 'STUDENT_ID';
      case 'DRAUGHTSMAN':
        return 'QUALIFICATION_CERTIFICATE';
      case 'ENGINEER':
      default:
        return 'DEGREE_CERTIFICATE';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _pickProofDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result.isEmpty) return;
      final file = result.first;

      final extension = (file.extension ?? '').toLowerCase();
      if (!['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
        setState(() {
          _proofError =
              'Invalid file type. Only PDF, JPG, and PNG files are accepted.';
        });
        return;
      }

      Uint8List? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        // Fallback
      }

      final fileSize = bytes?.length ?? (file.lengthSync() as int?) ?? 0;
      if (fileSize > 10 * 1024 * 1024) {
        setState(() {
          _proofError = 'File size exceeds the 10MB limit.';
        });
        return;
      }

      setState(() {
        _proofBytes = bytes;
        _proofFileName = file.name;
        _proofFileSize = fileSize;
        _proofError = null;
      });
    } catch (e) {
      setState(() {
        _proofError = 'Failed to select document: $e';
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _handleProvision() async {
    if (!_formKey.currentState!.validate()) return;

    if (_proofBytes == null || _proofBytes!.isEmpty) {
      setState(() {
        _proofError =
            'Proof document is mandatory. Please upload your $_requiredProofLabel.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload your $_requiredProofLabel.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.provisionProfileWithProof(
      name: _nameController.text,
      mobile: _mobileController.text,
      role: _selectedRole,
      proofBytes: _proofBytes!,
      proofFileName: _proofFileName ?? 'proof_document.pdf',
      proofDocumentType: _proofDocType,
    );

    if (!mounted) return;

    if (!success) {
      final errorState = ref.read(authControllerProvider);
      if (errorState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorMapper.mapException(errorState.error!)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      widget.onProvisioned();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: BlueprintBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal:
                    MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassCard(
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 600 ? 18.0 : 24.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ARCHI DRAFT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Provision Profile',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Firebase account exists but is missing in the database. Please provide your profile and qualification proof.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        AuthFormField(
                          controller: _nameController,
                          label: 'FULL NAME',
                          hint: 'Jane Doe',
                          prefixIcon: Icons.person_outline,
                          validator: Validators.name,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        AuthFormField(
                          controller: _mobileController,
                          label: 'MOBILE NUMBER',
                          hint: '+1 234 567 8900',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: Validators.mobile,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'ACCOUNT TYPE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 420;
                            final isCompact = constraints.maxWidth < 360;

                            return SegmentedButton<String>(
                              segments: [
                                ButtonSegment<String>(
                                  value: 'ENGINEER',
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'ENGINEER/ARCHITECT',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: isCompact
                                            ? 10.0
                                            : (isNarrow ? 11.0 : 12.5),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: isNarrow ? 0.2 : 0.4,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(Icons.engineering_outlined,
                                      size: isNarrow ? 16 : 18),
                                ),
                                ButtonSegment<String>(
                                  value: 'DRAUGHTSMAN',
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'DRAUGHTSMAN',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: isCompact
                                            ? 10.0
                                            : (isNarrow ? 11.0 : 12.5),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: isNarrow ? 0.2 : 0.4,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(Icons.architecture_outlined,
                                      size: isNarrow ? 16 : 18),
                                ),
                                ButtonSegment<String>(
                                  value: 'STUDENT',
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'STUDENT',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: isCompact
                                            ? 10.0
                                            : (isNarrow ? 11.0 : 12.5),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: isNarrow ? 0.2 : 0.4,
                                      ),
                                    ),
                                  ),
                                  icon: Icon(Icons.school_outlined,
                                      size: isNarrow ? 16 : 18),
                                ),
                              ],
                              selected: {_selectedRole},
                              selectedIcon:
                                  Icon(Icons.check, size: isNarrow ? 15 : 18),
                              onSelectionChanged: isLoading
                                  ? null
                                  : (Set<String> selection) {
                                      setState(() {
                                        _selectedRole = selection.first;
                                      });
                                    },
                              style: SegmentedButton.styleFrom(
                                backgroundColor:
                                    AppColors.surfaceContainerLowest,
                                selectedForegroundColor:
                                    AppColors.onPrimaryContainer,
                                selectedBackgroundColor:
                                    AppColors.secondaryFixed,
                                side: const BorderSide(
                                    color: AppColors.outlineVariant),
                                visualDensity: isNarrow
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isNarrow ? 4 : 10,
                                  vertical: isNarrow ? 8 : 12,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Mandatory proof upload container
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: _proofError != null
                                ? AppColors.errorContainer.withValues(alpha: 0.1)
                                : AppColors.surfaceContainerLowest,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: _proofError != null
                                  ? AppColors.error
                                  : AppColors.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 18,
                                    color: _proofError != null
                                        ? AppColors.error
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'REQUIRED PROOF UPLOAD',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.0,
                                        color: _proofError != null
                                            ? AppColors.error
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _requiredProofLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Formats: PDF, JPG, PNG (Max 10MB)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.outline,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_proofBytes == null) ...[
                                OutlinedButton.icon(
                                  onPressed:
                                      isLoading ? null : _pickProofDocument,
                                  icon: const Icon(Icons.upload_file, size: 18),
                                  label: const Text('CHOOSE DOCUMENT'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: _proofError != null
                                          ? AppColors.error
                                          : AppColors.primary,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _proofFileName
                                                    ?.toLowerCase()
                                                    .endsWith('.pdf') ==
                                                true
                                            ? Icons.picture_as_pdf
                                            : Icons.image_outlined,
                                        size: 20,
                                        color: Colors.green.shade800,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _proofFileName ?? 'Document',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green.shade900,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _formatFileSize(_proofFileSize),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: isLoading
                                            ? null
                                            : _pickProofDocument,
                                        child: const Text('Replace'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_proofError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _proofError!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        FilledButton(
                          onPressed: isLoading ? null : _handleProvision,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('PROVISION PROFILE'),
                        ),
                        const SizedBox(height: 20),

                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        await ref
                                            .read(authControllerProvider.notifier)
                                            .signOut();
                                        if (context.mounted) {
                                          context.go('/role-selection');
                                        }
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.secondary,
                                ),
                                child: const Text('CREATE NEW ACCOUNT'),
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => ref
                                        .read(authControllerProvider.notifier)
                                        .signOut(),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  textStyle: theme.textTheme.labelSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                child: const Text('SIGN OUT'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

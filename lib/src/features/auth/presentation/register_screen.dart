import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_form_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? role;
  const RegisterScreen({super.key, this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _selectedRole;

  Uint8List? _proofBytes;
  String? _proofFileName;
  int _proofFileSize = 0;
  String? _proofError;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role?.toUpperCase() ?? 'ENGINEER';
    if (_selectedRole == 'CLIENT') _selectedRole = 'ENGINEER';
  }

  String get _roleTitle {
    if (_selectedRole == 'STUDENT') return 'Student Registration';
    if (_selectedRole == 'DRAUGHTSMAN') return 'Draughtsman Registration';
    return 'Engineer Registration';
  }

  String get _roleSubtitle {
    if (_selectedRole == 'STUDENT') {
      return 'Create your student account to begin training';
    }
    if (_selectedRole == 'DRAUGHTSMAN') {
      return 'Create your draughtsman account to join the studio';
    }
    return 'Create your engineer account to join the studio';
  }

  String get _roleLabel => _selectedRole;

  String get _requiredProofLabel {
    if (_selectedRole == 'STUDENT') {
      return 'Valid Student ID card';
    }
    if (_selectedRole == 'DRAUGHTSMAN') {
      return 'Draughtsmanship degree, diploma, or relevant qualification certificate';
    }
    return 'Engineering degree or relevant qualification certificate';
  }

  String get _proofDocType {
    if (_selectedRole == 'STUDENT') return 'STUDENT_ID';
    if (_selectedRole == 'DRAUGHTSMAN') return 'QUALIFICATION_CERTIFICATE';
    return 'DEGREE_CERTIFICATE';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        // Fallback for platforms with sync bytes
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

  Future<void> _handleRegister() async {
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
    final success = await controller.register(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      mobile: _mobileController.text,
      role: _selectedRole,
      proofBytes: _proofBytes,
      proofFileName: _proofFileName,
      proofDocumentType: _proofDocType,
    );

    if (!mounted) return;

    if (success) {
      context.go('/registration-confirmation');
    } else {
      final errorState = ref.read(authControllerProvider);
      if (errorState.hasError) {
        String message;
        if (errorState.error is FirebaseAuthException) {
          message = AuthErrorMapper.mapException(errorState.error!);
        } else {
          final raw = errorState.error.toString().replaceAll('Exception: ', '');
          message =
              raw.isNotEmpty ? raw : 'Registration failed. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ARCHI DRAFT',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _roleTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _roleSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        AuthFormField(
                          controller: _nameController,
                          label: 'FULL NAME',
                          hint: 'Er. Jane Doe',
                          prefixIcon: Icons.person_outline,
                          textCapitalization: TextCapitalization.words,
                          validator: Validators.name,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),

                        AuthFormField(
                          controller: _emailController,
                          label: 'EMAIL',
                          hint: 'name@firm.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),

                        AuthFormField(
                          controller: _mobileController,
                          label: 'MOBILE NUMBER',
                          hint: '+91 98765 43210',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 24),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedRole == 'DRAUGHTSMAN'
                                    ? Icons.architecture_outlined
                                    : (_selectedRole == 'STUDENT'
                                          ? Icons.school_outlined
                                          : Icons.engineering_outlined),
                                size: 20,
                                color: AppColors.outline,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Registering as: $_roleLabel',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.outline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Role-specific mandatory proof upload section
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
                                        _proofFileName?.toLowerCase().endsWith('.pdf') ==
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
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          foregroundColor:
                                              AppColors.primary,
                                        ),
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        AuthFormField(
                          controller: _passwordController,
                          label: 'PASSWORD',
                          hint: 'Min 8 chars, uppercase, lowercase, number',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: Validators.password,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),

                        AuthFormField(
                          controller: _confirmPasswordController,
                          label: 'CONFIRM PASSWORD',
                          hint: 'Re-enter your password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: (value) => Validators.confirmPassword(
                            value,
                            _passwordController.text,
                          ),
                          onFieldSubmitted: (_) => _handleRegister(),
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 32),

                        FilledButton(
                          onPressed: isLoading ? null : _handleRegister,
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
                              : const Text('CREATE ACCOUNT'),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ALREADY REGISTERED? ',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading ? null : () => context.pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                textStyle: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('SIGN IN'),
                            ),
                          ],
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

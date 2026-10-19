import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.register(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      mobile: _mobileController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (!success) {
      final errorState = ref.read(authControllerProvider);
      if (errorState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorState.error.toString().replaceAll('Exception: ', ''),
            ),
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
                              Text(
                                'Registering as: $_roleLabel',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

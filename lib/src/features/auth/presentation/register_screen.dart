import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/blueprint_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_form_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

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

  String _selectedRole = 'CLIENT';

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
            content: Text(AuthErrorMapper.mapException(errorState.error!)),
            behavior: SnackBarBehavior.floating,
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: isLoading ? null : () => context.pop(),
        ),
      ),
      body: BlueprintBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassCard(
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
                          'Request Access',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your account to join the studio',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

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
                          controller: _emailController,
                          label: 'EMAIL ADDRESS',
                          hint: 'user@example.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
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
                        const SizedBox(height: 24),

                        Text(
                          'ACCOUNT TYPE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment<String>(
                              value: 'CLIENT',
                              label: Text('CLIENT'),
                              icon: Icon(Icons.business_outlined),
                            ),
                            ButtonSegment<String>(
                              value: 'DRAUGHTSMAN',
                              label: Text('DRAUGHTSMAN'),
                              icon: Icon(Icons.architecture_outlined),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: isLoading
                              ? null
                              : (Set<String> selection) {
                                  setState(() {
                                    _selectedRole = selection.first;
                                  });
                                },
                          style: SegmentedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerLowest,
                            selectedForegroundColor: AppColors.onPrimaryContainer,
                            selectedBackgroundColor: AppColors.secondaryFixed,
                            side: const BorderSide(color: AppColors.outlineVariant),
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
                                textStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
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

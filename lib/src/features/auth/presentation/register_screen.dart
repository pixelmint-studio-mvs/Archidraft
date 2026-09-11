import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/auth_error_mapper.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_form_field.dart';

/// Registration screen for ARCHI DRAFT.
///
/// Per USER_ROLES.md: Only CLIENT and DRAUGHTSMAN can register.
/// Per SECURITY_ARCHITECTURE.md: "Normal registration must never create an ADMIN."
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

  /// Selected role — only CLIENT or DRAUGHTSMAN permitted.
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

    if (success) {
      // Registration successful — GoRouter redirect handles navigation
      // to /verify-email automatically based on auth state.
    } else {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join Archi Draft',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                ),
                const SizedBox(height: 24),

                // Name
                AuthFormField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outlined,
                  validator: Validators.name,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),

                // Email
                AuthFormField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),

                // Mobile
                AuthFormField(
                  controller: _mobileController,
                  label: 'Mobile Number',
                  hint: 'Enter your mobile number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.mobile,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),

                // Role Selection
                // Per SECURITY_ARCHITECTURE.md: Only CLIENT and DRAUGHTSMAN.
                // ADMIN is never available in the registration flow.
                Text(
                  'I am a:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'CLIENT',
                      label: Text('Client'),
                      icon: Icon(Icons.business_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'DRAUGHTSMAN',
                      label: Text('Draughtsman'),
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
                ),
                const SizedBox(height: 16),

                // Password
                AuthFormField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Min 8 chars, uppercase, lowercase, number',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: true,
                  validator: Validators.password,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                AuthFormField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _handleRegister(),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),

                // Register Button
                FilledButton(
                  onPressed: isLoading ? null : _handleRegister,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 16),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: isLoading ? null : () => context.pop(),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

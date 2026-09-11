import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/auth_error_mapper.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_form_field.dart';

/// Forgot Password screen for ARCHI DRAFT.
///
/// Per SECURITY_ARCHITECTURE.md and ERROR_HANDLING.md:
/// Always shows a generic success message regardless of whether the
/// email exists in the system, to prevent account enumeration.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    await controller.sendPasswordResetEmail(
      email: _emailController.text,
    );

    if (!mounted) return;

    // Per security policy: always show success message to prevent
    // account enumeration. Even if the email doesn't exist, we show
    // "If an account exists..." message.
    final errorState = ref.read(authControllerProvider);
    if (errorState.hasError) {
      // Only show error for non-enumeration errors (network, rate limit)
      final errorMessage =
          AuthErrorMapper.mapException(errorState.error!);
      if (errorMessage.contains('internet') ||
          errorMessage.contains('Too many')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // Show success state (generic message)
    setState(() {
      _emailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: _emailSent ? _buildSuccessView(context) : _buildFormView(context, isLoading),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Forgot your password?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(153),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Email
          AuthFormField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onFieldSubmitted: (_) => _handleResetPassword(),
            enabled: !isLoading,
          ),
          const SizedBox(height: 24),

          // Submit Button
          FilledButton(
            onPressed: isLoading ? null : _handleResetPassword,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Send Reset Link'),
          ),
          const SizedBox(height: 16),

          // Back to login
          TextButton(
            onPressed: isLoading ? null : () => context.pop(),
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'If an account exists with this email, a password reset link has been sent. Please check your inbox and spam folder.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(153),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.go('/login'),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }
}

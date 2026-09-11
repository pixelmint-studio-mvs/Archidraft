import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

/// Email verification screen shown after registration or when
/// an unverified user logs in.
///
/// Features:
/// - Status message with the user's email
/// - "I've Verified" button that reloads Firebase user state
/// - "Resend Email" button with 60-second cooldown
/// - "Log Out" button
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  /// Cooldown timer for the resend button (60 seconds).
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _resendCooldown = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);

    final controller = ref.read(authControllerProvider.notifier);
    final isVerified = await controller.checkEmailVerified();

    if (!mounted) return;

    setState(() => _isChecking = false);

    if (isVerified) {
      // Verified — GoRouter redirect will handle navigation
      // Force auth state refresh by invalidating the provider
      ref.invalidate(authStateChangesProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not yet verified. Please check your inbox or spam folder.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resendVerification() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.sendEmailVerification();

    if (!mounted) return;

    setState(() => _isResending = false);

    if (success) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent. Please check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend email. Please try again later.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signOut();
    // GoRouter redirect handles navigation to /login
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final email = currentUser?.email ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify Your Email',
                  style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'A verification email has been sent to:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please click the link in the email to verify your account. Check your spam folder if you don\'t see it.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // "I've Verified" button
                FilledButton.icon(
                  onPressed: _isChecking ? null : _checkVerification,
                  icon: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                      _isChecking ? 'Checking...' : "I've Verified My Email"),
                ),
                const SizedBox(height: 12),

                // Resend button with cooldown
                OutlinedButton.icon(
                  onPressed: (_isResending || _resendCooldown > 0)
                      ? null
                      : _resendVerification,
                  icon: _isResending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _resendCooldown > 0
                        ? 'Resend in ${_resendCooldown}s'
                        : 'Resend Verification Email',
                  ),
                ),
                const SizedBox(height: 24),

                // Log out
                TextButton(
                  onPressed: _handleLogout,
                  child: const Text('Log Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

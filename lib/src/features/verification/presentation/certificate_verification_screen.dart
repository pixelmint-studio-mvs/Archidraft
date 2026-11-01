import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/certificate_verification_providers.dart';

class CertificateVerificationScreen extends ConsumerWidget {
  final String token;

  const CertificateVerificationScreen({super.key, required this.token});

  bool _canPop(BuildContext context) {
    try {
      return context.canPop();
    } catch (_) {
      return Navigator.canPop(context);
    }
  }

  void _handleBack(BuildContext context) {
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
    } catch (_) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        return;
      }
    }
    try {
      context.go('/landing');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationAsync = ref.watch(certificateVerificationProvider(token));
    final canGoBack = _canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(canGoBack ? Icons.arrow_back_rounded : Icons.home_outlined),
          tooltip: canGoBack ? 'Back' : 'Home',
          onPressed: () => _handleBack(context),
        ),
        title: Text('Certificate Verification', style: AppTypography.headlineSmMobile),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: verificationAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => _buildInvalidUI(context, 'Network error during verification'),
            data: (result) {
              if (result.isValid && result.credentialData != null) {
                return _buildValidUI(context, result.credentialData!);
              } else {
                return _buildInvalidUI(context, result.error);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildValidUI(BuildContext context, Map<String, dynamic> credentialData) {
    final issuedAtRaw = credentialData['issuedAt'];
    DateTime? issuedAt;
    if (issuedAtRaw != null) {
      issuedAt = DateTime.tryParse(issuedAtRaw.toString());
    }
    final formattedDate = issuedAt != null
        ? "${issuedAt.day}/${issuedAt.month}/${issuedAt.year}"
        : '';

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: AppColors.success, size: 64),
          const SizedBox(height: 16),
          Text('VERIFIED CERTIFICATE', style: AppTypography.headlineLgMobile),
          const SizedBox(height: 8),
          Text('✓ Valid Certificate', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          if (credentialData['id'] != null && credentialData['id'].toString().isNotEmpty) ...[
            _buildDetailRow('Certificate ID:', credentialData['id'].toString()),
            const SizedBox(height: 16),
          ],
          _buildDetailRow('Certificate / Credential:', credentialData['title'] ?? ''),
          if (credentialData['moduleTitle'] != null && credentialData['moduleTitle'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailRow('Training Module:', credentialData['moduleTitle'].toString()),
          ],
          const SizedBox(height: 16),
          _buildDetailRow('Recipient:', credentialData['recipientName'] ?? ''),
          const SizedBox(height: 16),
          _buildDetailRow('Issued:', formattedDate),
          const SizedBox(height: 16),
          _buildDetailRow('Credential Type:', credentialData['type'] ?? ''),
          const SizedBox(height: 32),
          Text(
            'Verification:\nVerified by Archi Draft & Draughtsman Studio',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _handleBack(context),
            icon: Icon(_canPop(context) ? Icons.arrow_back : Icons.home, size: 18),
            label: Text(_canPop(context) ? 'Go Back' : 'Return to Archi Draft'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidUI(BuildContext context, String? error) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: 16),
          Text(error ?? 'INVALID CERTIFICATE', style: AppTypography.headlineLgMobile),
          const SizedBox(height: 16),
          Text(
            'This certificate could not be verified in our records.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _handleBack(context),
            icon: Icon(_canPop(context) ? Icons.arrow_back : Icons.home, size: 18),
            label: Text(_canPop(context) ? 'Go Back' : 'Return to Archi Draft'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

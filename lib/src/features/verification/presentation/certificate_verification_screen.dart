import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/certificate_verification_result.dart';
import '../providers/certificate_verification_providers.dart';

class CertificateVerificationScreen extends ConsumerStatefulWidget {
  final String token;

  const CertificateVerificationScreen({super.key, required this.token});

  @override
  ConsumerState<CertificateVerificationScreen> createState() =>
      _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState
    extends ConsumerState<CertificateVerificationScreen> {
  late final TextEditingController _tokenController;
  late String _activeToken;

  @override
  void initState() {
    super.initState();
    _activeToken = widget.token.trim();
    _tokenController = TextEditingController(text: _activeToken);
  }

  @override
  void didUpdateWidget(covariant CertificateVerificationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token) {
      setState(() {
        _activeToken = widget.token.trim();
        _tokenController.text = _activeToken;
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final query = _tokenController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _activeToken = query;
      });
    }
  }

  void _clearSearch() {
    _tokenController.clear();
    setState(() {
      _activeToken = '';
    });
  }

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
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSearchCard(context),
              const SizedBox(height: 24),
              _buildResultArea(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'OFFICIAL REGISTRY LOOKUP',
                style: AppTypography.labelMono.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    hintText: 'Enter Certificate ID or Token',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _tokenController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: _clearSearch,
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _submitSearch(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _submitSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Verify'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea(BuildContext context) {
    if (_activeToken.isEmpty) {
      return _buildIdleUI(context);
    }

    final verificationAsync = ref.watch(certificateVerificationProvider(_activeToken));

    return verificationAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => _buildInvalidUI(context, 'Network error during verification'),
      data: (result) {
        if (result.status == VerificationStatus.revoked) {
          return _buildRevokedUI(context, result.credentialData, result.error);
        } else if (result.status == VerificationStatus.pending) {
          return _buildPendingUI(context, result.error);
        } else if (result.isValid && result.credentialData != null) {
          return _buildValidUI(context, result.credentialData!);
        } else {
          return _buildInvalidUI(context, result.error);
        }
      },
    );
  }

  Widget _buildIdleUI(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, color: AppColors.onSurfaceVariant, size: 56),
          const SizedBox(height: 16),
          Text('Enter Certificate Identifier', style: AppTypography.headlineSmMobile),
          const SizedBox(height: 8),
          Text(
            'Scan the QR code printed on your official document or enter your Certificate ID (e.g. DS-AD-LES-XXXX) above to verify its authenticity.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.4),
          ),
        ],
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

  Widget _buildRevokedUI(
    BuildContext context,
    Map<String, dynamic>? credentialData,
    String? error,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gpp_bad_rounded, color: AppColors.error, size: 64),
          const SizedBox(height: 16),
          Text('CERTIFICATE REVOKED', style: AppTypography.headlineLgMobile.copyWith(color: AppColors.error)),
          const SizedBox(height: 8),
          Text(
            error ?? 'This certificate has been formally revoked by administrative authority.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 32),
          if (credentialData != null) ...[
            if (credentialData['id'] != null) ...[
              _buildDetailRow('Certificate ID:', credentialData['id'].toString()),
              const SizedBox(height: 14),
            ],
            if (credentialData['title'] != null) ...[
              _buildDetailRow('Credential Title:', credentialData['title'].toString()),
              const SizedBox(height: 14),
            ],
            if (credentialData['recipientName'] != null) ...[
              _buildDetailRow('Recipient:', credentialData['recipientName'].toString()),
              const SizedBox(height: 14),
            ],
            if (credentialData['revocationReason'] != null) ...[
              _buildDetailRow('Revocation Reason:', credentialData['revocationReason'].toString()),
              const SizedBox(height: 14),
            ],
            if (credentialData['revokedAt'] != null) ...[
              _buildDetailRow('Revocation Recorded:', credentialData['revokedAt'].toString()),
              const SizedBox(height: 14),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            'This credential is no longer valid for professional or accreditation purposes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
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

  Widget _buildPendingUI(BuildContext context, String? error) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pending_actions, color: Colors.amber, size: 64),
          const SizedBox(height: 16),
          Text('CERTIFICATE PENDING', style: AppTypography.headlineLgMobile),
          const SizedBox(height: 8),
          Text(
            error ?? 'This certificate issuance is currently pending verification.',
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

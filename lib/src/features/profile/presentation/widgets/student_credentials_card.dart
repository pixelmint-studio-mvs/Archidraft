import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/credentials_providers.dart';
import '../../domain/student_credential.dart';

class StudentCredentialsCard extends ConsumerStatefulWidget {
  const StudentCredentialsCard({super.key});

  @override
  ConsumerState<StudentCredentialsCard> createState() => _StudentCredentialsCardState();
}

class _StudentCredentialsCardState extends ConsumerState<StudentCredentialsCard> {
  final Map<String, bool> _isProcessing = {};

  Future<void> _handleGenerateOrDownload(StudentCredential credential) async {
    if (_isProcessing[credential.id] == true) return;

    setState(() => _isProcessing[credential.id] = true);
    try {
      final repository = ref.read(credentialsRepositoryProvider);
      if (credential.certificateObjectKey == null) {
        await repository.generateCertificate(credential.id);
        ref.invalidate(studentCredentialsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Certificate generated successfully!')),
          );
        }
      } else {
        // Download
        String savePath = 'Certificate_${credential.id}.pdf';
        bool isMobile = false;
        try {
          if (!identical(0, 0.0)) { // non-web proxy check
            isMobile = true;
            final directory = await getApplicationDocumentsDirectory();
            savePath = '${directory.path}/$savePath';
          }
        } catch (_) {}
        
        await repository.downloadCertificate(credential.id, savePath);
        if (mounted) {
          if (isMobile) {
            await OpenFilex.open(savePath);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Certificate opened')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Certificate downloaded')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing[credential.id] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final credentialsAsync = ref.watch(studentCredentialsProvider);

    return credentialsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            Text('Failed to load credentials', style: AppTypography.bodyMd),
            TextButton(
              onPressed: () => ref.invalidate(studentCredentialsProvider),
              child: const Text('Retry'),
            )
          ],
        ),
      ),
      data: (credentials) {
        if (credentials.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('CREDENTIALS & CERTIFICATES'),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No credentials earned yet.',
                      style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Complete training modules or approved practical projects to earn certificates.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('CREDENTIALS & CERTIFICATES'),
            const SizedBox(height: AppSpacing.md),
            ...credentials.map((cred) => _CredentialItem(
                  credential: cred,
                  isProcessing: _isProcessing[cred.id] ?? false,
                  onAction: () => _handleGenerateOrDownload(cred),
                  onVerify: cred.verificationToken != null 
                    ? () {
                        // We can either push to the verification screen
                        context.push('/verify/${cred.verificationToken}');
                        
                        // And copy to clipboard for convenience
                        Clipboard.setData(ClipboardData(
                          text: 'https://archi-draft.web.app/verify/${cred.verificationToken}'
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verification link copied to clipboard')),
                        );
                      }
                    : null,
                )),
          ],
        );
      },
    );
  }
}

class _CredentialItem extends StatelessWidget {
  final StudentCredential credential;
  final bool isProcessing;
  final VoidCallback onAction;
  final VoidCallback? onVerify;

  const _CredentialItem({
    required this.credential,
    required this.isProcessing,
    required this.onAction,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final hasCert = credential.certificateObjectKey != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credential.title,
                      style: AppTypography.headlineSmMobile,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Issued: ${credential.issuedAt.toLocal().toString().split(' ')[0]}',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasCert && onVerify != null)
                        IconButton(
                          onPressed: onVerify,
                          icon: const Icon(Icons.share),
                          tooltip: 'Share Verification Link',
                        ),
                      const SizedBox(width: 4),
                      OutlinedButton.icon(
                        onPressed: onAction,
                        icon: Icon(hasCert ? Icons.download : Icons.picture_as_pdf),
                        label: Text(hasCert ? 'Download Certificate' : 'Generate Certificate'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.labelMono.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}

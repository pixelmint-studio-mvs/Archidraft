import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/legal_document.dart';
import 'legal_markdown_viewer.dart';

/// Modal bottom sheet / dialog for reading full legal documents
class DocumentReaderSheet extends StatelessWidget {
  final LegalDocument document;

  const DocumentReaderSheet({super.key, required this.document});

  static Future<void> show(BuildContext context, LegalDocument document) {
    final media = MediaQuery.of(context);
    final isDesktop = media.size.width >= 800;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
            child: DocumentReaderSheet(document: document),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DocumentReaderSheet(document: document),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'EFFECTIVE':
        return AppColors.success;
      case 'PENDING_LEGAL_REVIEW':
        return Colors.orange.shade700;
      case 'PENDING_BUSINESS_APPROVAL':
        return Colors.amber.shade800;
      case 'DRAFT':
        return AppColors.secondary;
      case 'SUPERSEDED':
      case 'ARCHIVED':
        return AppColors.outline;
      default:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(document.status);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document.title, style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    document.status.replaceAll('_', ' '),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'v${document.version} • ${document.effectiveAt != null ? 'Effective: ${document.effectiveAt!.split('T').first}' : 'Publication Pending'}',
                  style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LegalMarkdownViewer(markdown: document.content),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}


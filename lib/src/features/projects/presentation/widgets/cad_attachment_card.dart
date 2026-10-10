import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/file_repository.dart';
import '../../domain/project_message.dart';
import 'dxf_viewer.dart';

/// Card widget for CAD attachments (DXF & DWG) in Collaboration Hub
class CadAttachmentCard extends ConsumerWidget {
  final ProjectMessage message;

  const CadAttachmentCard({super.key, required this.message});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _openDxfViewer(BuildContext context) {
    final fileId = message.attachmentFileId;
    if (fileId == null) return;
    final fileName = message.attachmentName ?? 'drawing.dxf';

    showDialog(
      context: context,
      builder: (_) => DxfViewerDialog(
        fileId: fileId,
        fileName: fileName,
      ),
    );
  }

  void _downloadOrOpen(BuildContext context, WidgetRef ref) {
    final fileId = message.attachmentFileId;
    if (fileId == null) return;
    final fileName = message.attachmentName ?? 'drawing.dwg';

    ref.read(fileRepositoryProvider).downloadFile(
      fileId,
      fileName,
      openInBrowser: !kIsWeb, // on mobile, try open_filex
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading $fileName...')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileName = message.attachmentName ?? 'CAD Drawing';
    final size = message.attachmentSize != null ? _formatBytes(message.attachmentSize!) : '';
    final isDxf = message.isDxfAttachment;
    final isDwg = message.isDwgAttachment;

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.architecture_rounded,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: AppTypography.buttonText.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isDxf ? 'DXF 2D Vector' : (isDwg ? 'DWG Binary' : 'CAD File'),
                            style: AppTypography.labelMono.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        if (size.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            size,
                            style: AppTypography.labelMono.copyWith(
                              color: AppColors.outline,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: AppSpacing.sm),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isDxf) ...[
                // In-app 2D vector viewer action
                FilledButton.tonalIcon(
                  onPressed: () => _openDxfViewer(context),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View 2D Drawing'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded, size: 18),
                  tooltip: 'Download DXF file',
                  onPressed: () => _downloadOrOpen(context, ref),
                ),
              ] else if (isDwg) ...[
                // DWG fallback explanation + download / external app
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          kIsWeb ? 'Binary DWG (AutoCAD)' : 'Open with external CAD viewer',
                          style: AppTypography.labelMono.copyWith(
                            fontSize: 10,
                            color: AppColors.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _downloadOrOpen(context, ref),
                  icon: Icon(kIsWeb ? Icons.download_rounded : Icons.open_in_new_rounded, size: 16),
                  label: Text(kIsWeb ? 'Download' : 'Open CAD'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ] else ...[
                // Generic CAD download
                IconButton(
                  icon: const Icon(Icons.download_rounded, size: 18),
                  tooltip: 'Download file',
                  onPressed: () => _downloadOrOpen(context, ref),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

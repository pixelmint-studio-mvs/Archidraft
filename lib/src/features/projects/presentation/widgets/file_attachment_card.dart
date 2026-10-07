import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../domain/project_file.dart';
import '../../data/file_repository.dart';
import '../../providers/file_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/file_category_labels.dart';
class FileAttachmentCard extends ConsumerStatefulWidget {
  final ProjectFile file;

  const FileAttachmentCard({super.key, required this.file});

  @override
  ConsumerState<FileAttachmentCard> createState() => _FileAttachmentCardState();
}

class _FileAttachmentCardState extends ConsumerState<FileAttachmentCard> {
  bool _isDownloading = false;
  bool _isDeleting = false;

  Future<void> _openFile() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final repository = ref.read(fileRepositoryProvider);

      if (kIsWeb) {
        await repository.downloadFile(
          widget.file.id,
          widget.file.sanitizedName,
          openInBrowser: true,
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/${widget.file.sanitizedName}';

        await repository.downloadFile(widget.file.id, filePath);
        await OpenFilex.open(filePath);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Open failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _deleteFile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        title: Text('Delete File', style: AppTypography.headlineLgMobile.copyWith(fontSize: 20)),
        content: Text(
          'Are you sure you want to delete "${widget.file.originalName}"?',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: AppTypography.buttonText.copyWith(color: AppColors.onSurface)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: AppTypography.buttonText.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final repository = ref.read(fileRepositoryProvider);
      await repository.deleteFile(widget.file.projectId, widget.file.id);
      
      ref.invalidate(projectFilesProvider(widget.file.projectId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final repository = ref.read(fileRepositoryProvider);

      if (kIsWeb) {
        // On web, api_client_web.dart handles downloading via Blob and anchor tag.
        // We pass the filename as savePath since directory paths don't matter on Web.
        await repository.downloadFile(
          widget.file.id,
          widget.file.sanitizedName,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download started in browser.'),
            backgroundColor: AppColors.secondary,
          ),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/${widget.file.sanitizedName}';

        // Streams directly to disk, avoiding memory bloat
        await repository.downloadFile(widget.file.id, filePath);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to $filePath'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  String _formatCategory(String category) => fileCategoryLabel(category);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 0),
        leading: const Icon(Icons.drafts_outlined, color: AppColors.outline),
        title: Text(
          widget.file.originalName,
          style: AppTypography.labelMono.copyWith(color: AppColors.primary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${(widget.file.size / 1024).toStringAsFixed(1)} KB • ${_formatCategory(widget.file.category)}',
          style: AppTypography.labelMono.copyWith(color: AppColors.outline, fontSize: 10),
        ),
        trailing: _isDownloading || _isDeleting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    tooltip: 'Open',
                    color: AppColors.outline,
                    onPressed: widget.file.status == 'COMPLETED'
                        ? _openFile
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, size: 20),
                    tooltip: 'Download',
                    color: AppColors.outline,
                    onPressed: widget.file.status == 'COMPLETED'
                        ? _downloadFile
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Delete',
                    color: AppColors.error,
                    onPressed: widget.file.status == 'COMPLETED'
                        ? _deleteFile
                        : null,
                  ),
                ],
              ),
      ),
    );
  }
}

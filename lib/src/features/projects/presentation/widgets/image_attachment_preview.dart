import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../api/providers/api_providers.dart';
import '../../data/file_repository.dart';
import '../../domain/project_message.dart';

/// In-chat inline image preview widget with authenticated fetching
/// and interactive zoomable lightbox viewer.
class ImageAttachmentPreview extends ConsumerStatefulWidget {
  final ProjectMessage message;

  const ImageAttachmentPreview({super.key, required this.message});

  // Global session cache for loaded image bytes to avoid repeated network fetches
  static final Map<String, Uint8List> _imageCache = {};

  @override
  ConsumerState<ImageAttachmentPreview> createState() => _ImageAttachmentPreviewState();
}

class _ImageAttachmentPreviewState extends ConsumerState<ImageAttachmentPreview> {
  Uint8List? _bytes;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant ImageAttachmentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.attachmentFileId != widget.message.attachmentFileId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final fileId = widget.message.attachmentFileId;
    if (fileId == null || fileId.isEmpty) return;

    if (ImageAttachmentPreview._imageCache.containsKey(fileId)) {
      if (mounted) {
        setState(() {
          _bytes = ImageAttachmentPreview._imageCache[fileId];
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final raw = await apiClient.downloadBinary('/api/files/$fileId/download');
      final bytes = Uint8List.fromList(raw);

      if (bytes.isEmpty) {
        throw Exception('Received 0 bytes for image');
      }

      ImageAttachmentPreview._imageCache[fileId] = bytes;

      if (mounted) {
        setState(() {
          _bytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Could not load image';
        });
      }
    }
  }

  void _openLightbox(BuildContext context, Uint8List bytes) {
    final fileName = widget.message.attachmentName ?? 'Image Preview';
    final fileId = widget.message.attachmentFileId;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (dialogCtx) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
              tooltip: 'Close preview',
              onPressed: () => Navigator.of(dialogCtx).pop(),
            ),
            title: Text(
              fileName,
              style: AppTypography.buttonText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (fileId != null)
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  tooltip: 'Download image',
                  onPressed: () {
                    ref.read(fileRepositoryProvider).downloadFile(
                          fileId,
                          fileName,
                          openInBrowser: false,
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading $fileName...')),
                    );
                  },
                ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              clipBehavior: Clip.none,
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: 240,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, color: AppColors.error, size: 32),
            const SizedBox(height: 6),
            Text(
              _errorMessage,
              style: AppTypography.labelMono.copyWith(fontSize: 11, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadImage,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading || _bytes == null) {
      return Container(
        width: 260,
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              'Loading image...',
              style: AppTypography.labelMono.copyWith(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth < 320 ? constraints.maxWidth : 320.0;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _openLightbox(context, _bytes!),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxW,
                maxHeight: 240,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Image.memory(
                    _bytes!,
                    width: maxW,
                    fit: BoxFit.cover,
                  ),
                  // Subtle tap-to-expand badge
                  Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'View',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../data/file_repository.dart';
import '../../providers/file_providers.dart';
import '../../../../core/theme/app_colors.dart';

class FileUploadButton extends ConsumerStatefulWidget {
  final String projectId;
  final String category;

  const FileUploadButton({
    super.key,
    required this.projectId,
    required this.category,
  });

  @override
  ConsumerState<FileUploadButton> createState() => _FileUploadButtonState();
}

class _FileUploadButtonState extends ConsumerState<FileUploadButton> {
  bool _isUploading = false;
  int _fileSize = 0;
  final Uuid _uuid = const Uuid();

  // Cache to ensure retries of the same file pick reuse the same actionId.
  final Map<String, String> _actionIdCache = {};

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'dwg', 'dxf', 'png', 'jpg', 'jpeg', 'zip'],
    );

    if (result.isEmpty) return;

    final file = result.first;

    final fileSize = file.lengthSync() ?? 0;
    if (fileSize > 50 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('File must be less than 50MB.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _fileSize = fileSize;
    });

    try {
      final repository = ref.read(fileRepositoryProvider);

      // Attempt to guess content type (Worker will also validate extension)
      String contentType = 'application/octet-stream';
      if (file.extension == 'pdf') {
        contentType = 'application/pdf';
      } else if (file.extension == 'png') {
        contentType = 'image/png';
      } else if (file.extension == 'jpg' || file.extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (file.extension == 'zip') {
        contentType = 'application/zip';
      }

      // Generate a deterministic actionId for this upload attempt based on file properties.
      // If the exact same file selection fails, it reuses the actionId to satisfy idempotency.
      final cacheKey = '${file.name}_$fileSize';
      final actionId = _actionIdCache.putIfAbsent(cacheKey, () => _uuid.v4());

      await repository.uploadFile(
        projectId: widget.projectId,
        category: widget.category,
        fileName: file.name,
        contentType: contentType,
        stream: file.readAsByteStream(),
        length: fileSize,
        actionId: actionId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File uploaded successfully.'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }

      // Remove from cache on success so a future identical upload gets a new ID
      _actionIdCache.remove(cacheKey);

      // Refresh the list of files
      ref.invalidate(projectFilesProvider(widget.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _fileSize = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isUploading ? null : _pickAndUpload,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 192, // h-48 = 192px
        decoration: BoxDecoration(
          color: const Color(0xFFDAE2FF), // secondary-fixed
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF0453CD).withValues(alpha: 0.4), // secondary/40
            width: 2,
          ),
          image: const DecorationImage(
            image: NetworkImage('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAIklEQVQIW2NkQAKrVq36zwjjgzhhYWGMYAEYB8RmROaABADeOQ8CXl/xfgAAAABJRU5ErkJggg=='),
            repeat: ImageRepeat.repeat,
            colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcATop),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  child: Center(
                    child: _isUploading
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0453CD)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Uploading...',
                                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                              ),
                              if (_fileSize > 0)
                                Text(
                                  '${(_fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
                                  style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: const Color(0xFF44474D)),
                                ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.upload_file, color: Color(0xFF0453CD), size: 40),
                              const SizedBox(height: 12),
                              const Text(
                                'Drag & Drop Blueprint Files',
                                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Max size: 50MB',
                                style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: Color(0xFF75777E)),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../data/file_repository.dart';
import '../../providers/file_providers.dart';

class FileUploadButton extends ConsumerStatefulWidget {
  final String projectId;
  final String category;

  const FileUploadButton({
    Key? key,
    required this.projectId,
    required this.category,
  }) : super(key: key);

  @override
  ConsumerState<FileUploadButton> createState() => _FileUploadButtonState();
}

class _FileUploadButtonState extends ConsumerState<FileUploadButton> {
  bool _isUploading = false;
  final _uuid = const Uuid();
  
  // Cache to ensure retries of the same file pick reuse the same actionId.
  final Map<String, String> _actionIdCache = {};

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'dwg', 'dxf', 'png', 'jpg', 'jpeg', 'zip'],
      withReadStream: true,
      withData: false, // Using streams to avoid high memory usage
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    
    if (file.size > 50 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File exceeds 50MB limit')),
      );
      return;
    }

    final stream = file.readStream;
    if (stream == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read file stream')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final repository = ref.read(fileRepositoryProvider);
      
      // Attempt to guess content type (Worker will also validate extension)
      String contentType = 'application/octet-stream';
      if (file.extension == 'pdf') contentType = 'application/pdf';
      else if (file.extension == 'png') contentType = 'image/png';
      else if (file.extension == 'jpg' || file.extension == 'jpeg') contentType = 'image/jpeg';
      else if (file.extension == 'zip') contentType = 'application/zip';

      // Generate a deterministic actionId for this upload attempt based on file properties.
      // If the exact same file selection fails, it reuses the actionId to satisfy idempotency.
      final cacheKey = '${file.name}_${file.size}';
      final actionId = _actionIdCache.putIfAbsent(cacheKey, () => _uuid.v4());

      await repository.uploadFile(
        projectId: widget.projectId,
        category: widget.category,
        fileName: file.name,
        contentType: contentType,
        stream: stream,
        length: file.size,
        actionId: actionId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
      }
      
      // Remove from cache on success so a future identical upload gets a new ID
      _actionIdCache.remove(cacheKey);
      
      // Refresh the list of files
      ref.invalidate(projectFilesProvider(widget.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : _pickAndUpload,
      icon: _isUploading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.upload_file),
      label: const Text('Upload File'),
    );
  }
}

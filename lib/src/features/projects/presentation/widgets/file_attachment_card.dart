import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../domain/project_file.dart';
import '../../data/file_repository.dart';
import '../../providers/file_providers.dart';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Open failed: $e')));
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
        title: const Text('Delete File'),
        content: Text(
          'Are you sure you want to delete "${widget.file.originalName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
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
          const SnackBar(content: Text('Download started in browser')),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/${widget.file.sanitizedName}';

        // Streams directly to disk, avoiding memory bloat
        await repository.downloadFile(widget.file.id, filePath);

        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Downloaded to $filePath')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file),
        title: Text(widget.file.originalName),
        subtitle: Text(
          '${(widget.file.size / 1024).toStringAsFixed(1)} KB • ${widget.file.category}',
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
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Open',
                    onPressed: widget.file.status == 'COMPLETED'
                        ? _openFile
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Download',
                    onPressed: widget.file.status == 'COMPLETED'
                        ? _downloadFile
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    color: Theme.of(context).colorScheme.error,
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

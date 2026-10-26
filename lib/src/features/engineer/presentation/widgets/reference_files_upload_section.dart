import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/core/theme/app_typography.dart';
import 'package:archi_draft/src/features/projects/data/file_repository.dart';
import 'package:archi_draft/src/features/projects/presentation/widgets/file_attachment_card.dart';
import 'package:archi_draft/src/features/projects/providers/file_providers.dart';
import 'package:archi_draft/src/features/projects/providers/project_form_controller.dart';

/// Exact 50 MiB limit in bytes: 50 * 1024 * 1024.
const int kMaxReferenceFileSizeBytes = 52428800;

/// 27 allowlisted file extensions for engineering reference files.
const List<String> kAllowedReferenceExtensions = [
  'dwg', 'dxf', 'dwf', 'dwfx', 'dgn', 'ifc', 'step', 'stp', 'iges', 'igs',
  'rvt', 'rfa', 'skp', 'pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'png',
  'jpg', 'jpeg', 'webp', 'tif', 'tiff', 'xls', 'xlsx', 'csv', 'zip',
];

/// Engineer Reference-File Upload Section with 50 MiB size enforcement,
/// allowlisted CAD/document/image formats, auto-draft creation, and progress tracking.
class ReferenceFilesUploadSection extends ConsumerStatefulWidget {
  final String? projectId;
  final ProjectFormController? controller;
  final VoidCallback? onUploadStart;
  final VoidCallback? onUploadComplete;

  const ReferenceFilesUploadSection({
    super.key,
    this.projectId,
    this.controller,
    this.onUploadStart,
    this.onUploadComplete,
  });

  @override
  ConsumerState<ReferenceFilesUploadSection> createState() => _ReferenceFilesUploadSectionState();
}

class _ReferenceFilesUploadSectionState extends ConsumerState<ReferenceFilesUploadSection> {
  bool _isUploading = false;
  String? _uploadingFileName;
  final Uuid _uuid = const Uuid();
  final Map<String, String> _actionIdCache = {};

  Future<void> _pickAndUploadFiles() async {
    // 1. Ensure project draft exists or auto-save if projectId is null
    String? currentProjectId = widget.projectId;
    final controller = widget.controller;

    if (currentProjectId == null && controller != null) {
      final success = await controller.saveDraft();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill required fields before uploading files.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      currentProjectId = ref.read(projectFormControllerProvider).projectId;
    }

    if (currentProjectId == null) return;

    // 2. Open native file picker with 27 supported extensions
    List<dynamic> result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: kAllowedReferenceExtensions,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (result.isEmpty) return;

    // 3. Process selected files
    setState(() {
      _isUploading = true;
    });
    widget.onUploadStart?.call();

    final repository = ref.read(fileRepositoryProvider);

    for (final file in result) {
      final fileSize = (file.lengthSync() as int?) ?? (await file.length() as int);
      final fileName = file.name as String;

      // 50 MiB size gate
      if (fileSize > kMaxReferenceFileSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "$fileName" exceeds the 50 MiB limit ($fileSize bytes).'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        continue;
      }

      setState(() {
        _uploadingFileName = fileName;
      });

      final extension = (fileName.contains('.') ? fileName.split('.').last : '').toLowerCase();
      String contentType = 'application/octet-stream';
      if (extension == 'pdf') {
        contentType = 'application/pdf';
      } else if (['png', 'jpg', 'jpeg', 'webp'].contains(extension)) {
        contentType = 'image/$extension';
      } else if (extension == 'zip') {
        contentType = 'application/zip';
      } else if (extension == 'dwg') {
        contentType = 'image/vnd.dwg';
      } else if (extension == 'dxf') {
        contentType = 'image/vnd.dxf';
      }

      final cacheKey = '${fileName}_$fileSize';
      final actionId = _actionIdCache.putIfAbsent(cacheKey, () => _uuid.v4());

      try {
        await repository.uploadFile(
          projectId: currentProjectId,
          category: 'client_upload',
          fileName: fileName,
          contentType: contentType,
          stream: file.readAsByteStream(),
          length: fileSize,
          actionId: actionId,
        );
        _actionIdCache.remove(cacheKey);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload "$fileName": $err'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadingFileName = null;
      });
      ref.invalidate(projectFilesProvider(currentProjectId));
    }
    widget.onUploadComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final activeProjectId = widget.projectId;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REFERENCE_FILES (CAD / PDF / DOCS)',
                style: AppTypography.labelMono.copyWith(color: AppColors.onSurfaceVariant),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Max 50 MiB / file',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.outline,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Supported: .dwg, .dxf, .ifc, .rvt, .step, .pdf, .docx, images, .zip',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.outline,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Upload Trigger / Drop Zone
          InkWell(
            onTap: _isUploading ? null : _pickAndUploadFiles,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  if (_isUploading) ...[
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _uploadingFileName != null ? 'Uploading $_uploadingFileName...' : 'Uploading files...',
                      style: AppTypography.buttonText.copyWith(color: AppColors.primary),
                    ),
                  ] else ...[
                    const Icon(Icons.cloud_upload_outlined, color: AppColors.secondary, size: 36),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Click to Select Reference Files',
                      style: AppTypography.buttonText.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CAD blueprints, 3D models, site sketches, specifications',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.outline, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (activeProjectId == null && widget.controller != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Selecting files will auto-save your draft. Or pre-save explicitly:',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outline, fontSize: 11),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final success = await widget.controller!.saveDraft();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Draft saved successfully.'),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Draft Now'),
                ),
              ],
            ),
          ],

          // Uploaded Files List
          if (activeProjectId != null) ...[
            const SizedBox(height: AppSpacing.md),
            ref.watch(projectFilesProvider(activeProjectId)).when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text('Error loading files: $err', style: TextStyle(color: AppColors.error)),
              ),
              data: (files) {
                final clientFiles = files.where((f) => f.category == 'client_upload' && f.status != 'FAILED').toList();
                if (clientFiles.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      'No source files uploaded yet. Upload reference files to provide context for your request.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                return Column(
                  children: clientFiles.map((f) => FileAttachmentCard(file: f)).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

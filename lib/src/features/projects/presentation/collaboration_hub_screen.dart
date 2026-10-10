import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../domain/project.dart';
import '../domain/project_message.dart';
import '../domain/project_file.dart';
import '../providers/project_providers.dart';
import '../providers/message_providers.dart';
import '../data/file_repository.dart';
import '../providers/voice_recording_controller.dart';
import 'widgets/voice_message_player.dart';
import 'widgets/voice_recorder_bar.dart';
import 'widgets/image_attachment_preview.dart';
import 'widgets/cad_attachment_card.dart';

/// Collaboration Hub Screen for Engineer Portal.
///
/// Implements the shared Project Collaboration Hub matching the Stitch Design System:
/// REFERENCE DESIGN/stitch_draughtsman_studio_os/collaboration_hub
class CollaborationHubScreen extends ConsumerStatefulWidget {
  final String projectId;

  const CollaborationHubScreen({super.key, required this.projectId});

  @override
  ConsumerState<CollaborationHubScreen> createState() => _CollaborationHubScreenState();
}

class _CollaborationHubScreenState extends ConsumerState<CollaborationHubScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isUploadingAttachment = false;
  ProjectFile? _pendingAttachment;
  int _previousMessageCount = 0;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndUploadAttachment() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'dwg', 'dxf', 'png', 'jpg', 'jpeg', 'zip'],
      );

      if (result.isEmpty) return;
      final file = result.first;

      final fileSize = file.lengthSync() ?? 0;
      if (fileSize > 50 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attachment must be under 50MB.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploadingAttachment = true;
      });

      // Resolve content type
      final ext = file.extension?.toLowerCase() ?? '';
      String contentType = 'application/octet-stream';
      if (ext == 'pdf') {
        contentType = 'application/pdf';
      } else if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (ext == 'zip') {
        contentType = 'application/zip';
      } else if (ext == 'dwg') {
        contentType = 'application/acad';
      } else if (ext == 'dxf') {
        contentType = 'application/dxf';
      }

      final actionId = const Uuid().v4();
      final uploadedFile = await ref.read(fileRepositoryProvider).uploadFile(
        projectId: widget.projectId,
        category: 'chat_attachment',
        fileName: file.name,
        contentType: contentType,
        stream: file.readAsByteStream(),
        length: fileSize,
        actionId: actionId,
      );

      if (mounted) {
        setState(() {
          _pendingAttachment = uploadedFile;
          _isUploadingAttachment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAttachment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload attachment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    final attachmentId = _pendingAttachment?.id;

    if (text.isEmpty && attachmentId == null) return;

    final controller = ref.read(messageSenderControllerProvider.notifier);
    final previousText = _textController.text;
    final previousAttachment = _pendingAttachment;

    _textController.clear();
    setState(() {
      _pendingAttachment = null;
    });

    try {
      await controller.sendMessage(
        projectId: widget.projectId,
        text: text,
        attachmentFileId: attachmentId,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        // Restore input if send failed
        _textController.text = previousText;
        setState(() {
          _pendingAttachment = previousAttachment;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openOrDownloadAttachment(ProjectMessage message) {
    if (message.attachmentFileId == null) return;
    final fileName = message.attachmentName ?? 'attachment';
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    final isPreviewable = ['jpg', 'jpeg', 'png', 'pdf'].contains(ext);

    ref.read(fileRepositoryProvider).downloadFile(
      message.attachmentFileId!,
      fileName,
      openInBrowser: isPreviewable,
    );

    if (kIsWeb && !isPreviewable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $fileName...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(projectMessagesProvider(widget.projectId), (prev, next) {
      if (next.hasValue && (next.value?.isNotEmpty ?? false)) {
        _scrollToBottom();
      }
    });

    final projectAsync = ref.watch(projectProvider(widget.projectId));
    final messagesAsync = ref.watch(projectMessagesProvider(widget.projectId));
    final sendState = ref.watch(messageSenderControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        title: projectAsync.when(
          data: (project) => Row(
            children: [
              const Icon(Icons.forum_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'Collaboration Hub',
                  style: AppTypography.buttonText.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${widget.projectId.substring(0, 8).toUpperCase()}',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.outline,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Text('Collaboration Hub'),
          error: (_, _) => const Text('Collaboration Hub'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh conversation',
            onPressed: () => ref.invalidate(projectMessagesProvider(widget.projectId)),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BlueprintGridPainter(),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: isMobile ? EdgeInsets.zero : const EdgeInsets.all(AppSpacing.md),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(AppSpacing.radiusXl),
                        border: isMobile
                            ? null
                            : Border.all(
                                color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                        boxShadow: isMobile
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Panel Sub-Header (Project & Participant Context)
                          _buildContextBanner(projectAsync.value, isMobile: isMobile),

                          // Messages List
                          Expanded(
                            child: messagesAsync.when(
                              loading: () => const AppLoadingIndicator(message: 'Loading conversation...'),
                              error: (err, _) => AppErrorWidget(
                                message: 'Failed to load messages.',
                                onRetry: () => ref.invalidate(projectMessagesProvider(widget.projectId)),
                              ),
                              data: (messages) {
                                if (messages.isEmpty) {
                                  return _buildEmptyState();
                                }
                                return _buildMessagesList(messages);
                              },
                            ),
                          ),

                          // Input Composer
                          _buildComposer(sendState.isLoading),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContextBanner(Project? project, {bool isMobile = false}) {
    final projectName = project?.projectName.isNotEmpty == true ? project!.projectName : 'Project #${widget.projectId.substring(0, 8)}';
    final isAssigned = project?.assignedDraughtsmanId != null && project!.assignedDraughtsmanId!.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: isMobile ? AppSpacing.sm : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName,
                  style: AppTypography.buttonText.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isAssigned ? AppColors.secondaryContainer : AppColors.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAssigned
                          ? 'Draughtsman Assigned (Studio Active)'
                          : 'Awaiting draughtsman assignment',
                      style: AppTypography.labelMono.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Encrypted Workspace',
                  style: AppTypography.labelMono.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 40,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No messages yet',
              style: AppTypography.headlineLgMobile.copyWith(
                color: AppColors.primary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start the conversation with your assigned draughtsman regarding revisions, drawings, or project requirements.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<ProjectMessage> messages) {
    if (!_initialScrollDone || messages.length > _previousMessageCount) {
      _previousMessageCount = messages.length;
      _initialScrollDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: messages.length + 1, // +1 for date divider
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.outlineVariant.withValues(alpha: 0.4))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'Project Conversation',
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.outline,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.outlineVariant.withValues(alpha: 0.4))),
              ],
            ),
          );
        }

        final message = messages[index - 1];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(ProjectMessage message) {
    final isEngineer = message.isFromEngineer;
    final timeStr = DateFormat('h:mm a').format(message.createdAt);
    final dateStr = DateFormat('MMM d').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isEngineer
                ? AppColors.primaryContainer.withValues(alpha: 0.1)
                : AppColors.secondaryContainer.withValues(alpha: 0.1),
            child: Icon(
              isEngineer ? Icons.person : Icons.architecture,
              size: 20,
              color: isEngineer ? AppColors.primary : AppColors.secondaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Sender + Role + Timestamp)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      message.senderName,
                      style: AppTypography.buttonText.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isEngineer ? AppColors.surfaceContainerHigh : AppColors.secondaryFixed.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isEngineer ? 'Engineer' : 'Draughtsman',
                        style: AppTypography.labelMono.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isEngineer ? AppColors.onSurfaceVariant : AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '$dateStr, $timeStr',
                      style: AppTypography.labelMono.copyWith(
                        color: AppColors.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Bubble Container
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(AppSpacing.radiusMd),
                      bottomLeft: Radius.circular(AppSpacing.radiusMd),
                      bottomRight: Radius.circular(AppSpacing.radiusMd),
                    ),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.message.isNotEmpty)
                        SelectableText(
                          message.message,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),

                      // Attachment card if present
                      if (message.hasAttachment) ...[
                        if (message.message.isNotEmpty) const SizedBox(height: AppSpacing.md),
                        if (message.isVoiceMessage)
                          VoiceMessagePlayer(message: message)
                        else if (message.isImageAttachment)
                          ImageAttachmentPreview(message: message)
                        else if (message.isCadAttachment)
                          CadAttachmentCard(message: message)
                        else
                          _buildAttachmentBubble(message),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentBubble(ProjectMessage message) {
    final fileName = message.attachmentName ?? 'Attached File';
    final size = message.attachmentSize != null ? _formatBytes(message.attachmentSize!) : '';
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

    IconData iconData = Icons.insert_drive_file;
    Color iconColor = AppColors.outline;
    Color iconBg = AppColors.surfaceContainerHigh;

    if (ext == 'pdf') {
      iconData = Icons.picture_as_pdf;
      iconColor = AppColors.error;
      iconBg = AppColors.error.withValues(alpha: 0.1);
    } else if (['dwg', 'dxf'].contains(ext)) {
      iconData = Icons.architecture;
      iconColor = AppColors.secondaryContainer;
      iconBg = AppColors.secondaryContainer.withValues(alpha: 0.1);
    } else if (['png', 'jpg', 'jpeg'].contains(ext)) {
      iconData = Icons.image;
      iconColor = AppColors.onTertiaryContainer;
      iconBg = AppColors.tertiaryFixed.withValues(alpha: 0.3);
    }

    return InkWell(
      onTap: () => _openOrDownloadAttachment(message),
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(iconData, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: AppTypography.labelMono.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (size.isNotEmpty)
                    Text(
                      size,
                      style: AppTypography.labelMono.copyWith(
                        color: AppColors.outline,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            const Icon(Icons.download_rounded, size: 18, color: AppColors.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(bool isSending) {
    final recordingState = ref.watch(voiceRecordingControllerProvider);
    if (!recordingState.isIdle) {
      return SafeArea(
        top: false,
        bottom: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(
              top: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
          ),
          child: VoiceRecorderBar(projectId: widget.projectId),
        ),
      );
    }

    final hasText = _textController.text.trim().isNotEmpty;
    final canSend = (hasText || _pendingAttachment != null) && !isSending && !_isUploadingAttachment;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending attachment preview
          if (_isUploadingAttachment)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uploading attachment...',
                    style: AppTypography.labelMono.copyWith(fontSize: 12, color: AppColors.outline),
                  ),
                ],
              ),
            )
          else if (_pendingAttachment != null)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.secondaryContainer.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file, size: 16, color: AppColors.secondaryContainer),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _pendingAttachment!.originalName,
                      style: AppTypography.labelMono.copyWith(fontSize: 12, color: AppColors.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.outline),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _pendingAttachment = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Composer Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach button
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.outline),
                  tooltip: 'Add attachment (PDF, DWG, DXF, PNG, JPG, ZIP)',
                  onPressed: _isUploadingAttachment || isSending ? null : _pickAndUploadAttachment,
                ),

                // Record voice message button
                IconButton(
                  icon: const Icon(Icons.mic_rounded, color: AppColors.outline),
                  tooltip: 'Record voice message',
                  onPressed: _isUploadingAttachment || isSending
                      ? null
                      : () => ref.read(voiceRecordingControllerProvider.notifier).startRecording(),
                ),

                // Text field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (canSend) _handleSendMessage();
                    },
                    decoration: InputDecoration(
                      hintText: 'Type a message or project note...',
                      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                  ),
                ),

                // Send button
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, right: 4),
                  child: FilledButton(
                    onPressed: canSend ? _handleSendMessage : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.surfaceContainerHigh,
                      disabledForegroundColor: AppColors.outline,
                      minimumSize: const Size(40, 40),
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += AppSpacing.blueprintUnit) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += AppSpacing.blueprintUnit) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

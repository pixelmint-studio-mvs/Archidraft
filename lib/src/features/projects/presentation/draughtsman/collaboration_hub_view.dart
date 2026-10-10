import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../notifications/providers/notification_providers.dart';
import '../../data/file_repository.dart';
import '../../domain/project.dart';
import '../../domain/project_file.dart';
import '../../domain/project_message.dart';
import '../../providers/file_providers.dart';
import '../../providers/project_providers.dart';
import '../../data/audio_service.dart';
import 'widgets/voice_note_player_widget.dart';
import 'widgets/voice_note_recorder_widget.dart';

/// Collaboration Hub view for Panel 6.
///
/// Faithfully reproduces the technical threaded discussion panel from:
/// - REFERENCE DESIGN/collaboration_hub/code.html
/// - REFERENCE DESIGN/collaboration_hub/screen.png
///
/// Features:
/// - Exact reference styling (glass-panel, hairline borders, Inter & JetBrains Mono typography)
/// - Sender identity, roles, timestamps, formatted date dividers
/// - Inline mentions (@Sarah J.) and structural column badges (C-4, S-102)
/// - File attachments with PDF/DWG badges and authenticated direct downloads
/// - Voice note waveform player integration
/// - Responsive composer with file attachment staging, project file picker, and mic control
/// - Zero horizontal or RenderFlex overflows across Desktop and Mobile viewports
/// Safe provider for the current user's UID (falls back to null if Firebase is uninitialized in tests)
final currentUserIdProvider = Provider<String?>((ref) {
  try {
    return ref.watch(authRepositoryProvider).currentUser?.uid;
  } catch (_) {
    return null;
  }
});

class CollaborationHubView extends ConsumerStatefulWidget {
  final String projectId;
  final Project project;
  final bool isEmbedded;
  final String? assignmentId;

  const CollaborationHubView({
    super.key,
    required this.projectId,
    required this.project,
    this.isEmbedded = false,
    this.assignmentId,
  });

  @override
  ConsumerState<CollaborationHubView> createState() => _CollaborationHubViewState();
}

class _CollaborationHubViewState extends ConsumerState<CollaborationHubView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  bool _isSending = false;
  bool _isUploadingAttachment = false;
  bool _isRecordingVoiceNote = false;

  String? _selectedAttachmentId;
  String? _selectedAttachmentName;
  int? _selectedAttachmentSize;

  String _filter = 'ALL'; // 'ALL', 'ATTACHMENTS', 'ENGINEER'

  @override
  void initState() {
    super.initState();
    // Dismiss/mark any unread CHAT_MESSAGE notifications for this project if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearUnreadChatNotifications();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearUnreadChatNotifications() {
    try {
      final notificationsAsync = ref.read(notificationsProvider);
      notificationsAsync.whenData((notifs) {
        for (final n in notifs) {
          if (!n.isRead && n.type == 'CHAT_MESSAGE') {
            ref.read(markNotificationReadProvider(n.id));
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _pickAndUploadAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'dwg', 'dxf', 'png', 'jpg', 'jpeg', 'zip'],
      withReadStream: true,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;

    if (picked.size > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File exceeds 50 MB limit.')),
        );
      }
      return;
    }

    final stream = picked.readStream;
    if (stream == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read selected file stream.')),
        );
      }
      return;
    }

    setState(() => _isUploadingAttachment = true);
    try {
      String contentType = 'application/octet-stream';
      final ext = picked.extension?.toLowerCase() ?? '';
      if (ext == 'pdf') {
        contentType = 'application/pdf';
      } else if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (ext == 'zip') {
        contentType = 'application/zip';
      }

      final uploadedFile = await ref.read(fileRepositoryProvider).uploadFile(
        projectId: widget.projectId,
        category: 'message_attachment',
        fileName: picked.name,
        contentType: contentType,
        stream: stream,
        length: picked.size,
        actionId: _uuid.v4(),
      );

      setState(() {
        _selectedAttachmentId = uploadedFile.id;
        _selectedAttachmentName = uploadedFile.originalName;
        _selectedAttachmentSize = uploadedFile.size;
      });

      ref.invalidate(projectFilesProvider(widget.projectId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attached: ${picked.name}'),
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload attachment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
      }
    }
  }

  void _showProjectFilesPicker(List<ProjectFile> files) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attach Project File',
                      style: AppTypography.buttonText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Select an existing drawing or document to reference in this message:',
                  style: AppTypography.bodyMd.copyWith(
                    fontSize: 12,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (files.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No project files uploaded yet.',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: files.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final file = files[idx];
                        final isPdf = file.originalName.toLowerCase().endsWith('.pdf');
                        final isDwg = file.originalName.toLowerCase().endsWith('.dwg') ||
                            file.originalName.toLowerCase().endsWith('.dxf');

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPdf
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : (isDwg
                                      ? AppColors.secondary.withValues(alpha: 0.1)
                                      : AppColors.surfaceContainerHigh),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              isPdf
                                  ? Icons.picture_as_pdf_outlined
                                  : (isDwg
                                      ? Icons.architecture_rounded
                                      : Icons.insert_drive_file_outlined),
                              size: 20,
                              color: isPdf
                                  ? AppColors.error
                                  : (isDwg ? AppColors.secondary : AppColors.onSurfaceVariant),
                            ),
                          ),
                          title: Text(
                            file.originalName,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              color: AppColors.outline,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedAttachmentId = file.id;
                              _selectedAttachmentName = file.originalName;
                              _selectedAttachmentSize = file.size;
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedAttachmentId == null) return;
    if (_isSending) return;

    setState(() => _isSending = true);
    try {
      final msg = text.isEmpty && _selectedAttachmentId != null
          ? 'Attached file: $_selectedAttachmentName'
          : text;

      await ref.read(projectRepositoryProvider).sendProjectMessage(
        projectId: widget.projectId,
        message: msg,
        attachmentFileId: _selectedAttachmentId,
      );

      _messageController.clear();
      setState(() {
        _selectedAttachmentId = null;
        _selectedAttachmentName = null;
        _selectedAttachmentSize = null;
      });

      ref.invalidate(projectMessagesProvider(widget.projectId));

      // Scroll to bottom after new message
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post remark: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _startVoiceNoteRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    final hasPerm = await recorder.hasPermission();
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required to record voice notes.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      await recorder.startRecording();
      if (mounted) {
        setState(() => _isRecordingVoiceNote = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start microphone: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSendVoiceNote(RecordedAudio audio) async {
    final timeStamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'voice_note_$timeStamp.${audio.fileExtension}';
    final durMin = audio.duration.inMinutes;
    final durSec = audio.duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final durationText = '$durMin:$durSec';

    // 1. Upload audio file to authorized R2 storage via existing FileRepository
    final uploadedFile = await ref.read(fileRepositoryProvider).uploadFile(
      projectId: widget.projectId,
      category: 'message_attachment',
      fileName: fileName,
      contentType: audio.mimeType,
      stream: Stream.value(audio.bytes),
      length: audio.bytes.length,
      actionId: _uuid.v4(),
    );

    // 2. Persist project message referencing the audio file
    final customText = _messageController.text.trim();
    final messageText = customText.isNotEmpty
        ? '$customText (Voice Note $durationText)'
        : 'Voice Note ($durationText)';

    await ref.read(projectRepositoryProvider).sendProjectMessage(
      projectId: widget.projectId,
      message: messageText,
      attachmentFileId: uploadedFile.id,
    );

    _messageController.clear();
    if (mounted) {
      setState(() => _isRecordingVoiceNote = false);
    }

    ref.invalidate(projectMessagesProvider(widget.projectId));
    ref.invalidate(projectFilesProvider(widget.projectId));

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(projectMessagesProvider(widget.projectId));
    final filesAsync = ref.watch(projectFilesProvider(widget.projectId));
    final currentUid = ref.watch(currentUserIdProvider);

    final prjCode = widget.project.projectId.length > 8
        ? '#DWG-${widget.project.projectId.substring(0, 6).toUpperCase()}'
        : '#DWG-${widget.project.projectId.toUpperCase()}';

    // Reference container: rounded-xl, hairline-border, glass-panel, soft-elevation
    final containerDecoration = BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFE2E8F0),
        width: 0.5,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
        BoxShadow(
          color: Color(0x08000000),
          offset: Offset(0, 8),
          blurRadius: 24,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final double bottomPadding = isNarrow ? 76.0 : (widget.isEmbedded ? AppSpacing.xl : AppSpacing.lg);
        final double horizPadding = isNarrow ? AppSpacing.sm : (widget.isEmbedded ? AppSpacing.xl : AppSpacing.lg);
        final double topPadding = isNarrow ? AppSpacing.sm : (widget.isEmbedded ? AppSpacing.xl : AppSpacing.lg);

        return Padding(
          padding: EdgeInsets.only(
            left: horizPadding,
            right: horizPadding,
            top: topPadding,
            bottom: bottomPadding,
          ),
          child: Container(
            decoration: containerDecoration,
            child: Column(
              children: [
                // 1. PANEL HEADER
                _buildPanelHeader(prjCode, isNarrow),

                const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),

                // 2. MESSAGES STREAM
                Expanded(
                  child: messagesAsync.when(
                    loading: () => const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            'Loading collaboration thread...',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 36, color: AppColors.error),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Failed to load collaboration messages: $err',
                              style: AppTypography.bodyMd,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton.icon(
                              onPressed: () => ref.invalidate(projectMessagesProvider(widget.projectId)),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (rawMessages) {
                      // Apply filters
                      var messages = rawMessages;
                      if (_filter == 'ATTACHMENTS') {
                        messages = messages.where((m) => m.attachmentFileId != null).toList();
                      } else if (_filter == 'ENGINEER') {
                        messages = messages.where((m) => m.senderRole == 'ENGINEER').toList();
                      }

                      if (messages.isEmpty) {
                        return _buildEmptyState();
                      }

                      return _buildMessagesList(messages, currentUid, isNarrow);
                    },
                  ),
                ),

                const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),

                // 3. ATTACHMENT STAGING BANNER
                if (_selectedAttachmentName != null) _buildStagedAttachmentBanner(),

                // 4. COMPOSER INPUT AREA
                _buildComposer(filesAsync.value ?? [], isNarrow),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // PANEL HEADER (forum icon, Collaboration Hub, #DWG-XXX, filter & more)
  // ─────────────────────────────────────────────────────────
  Widget _buildPanelHeader(String prjCode, bool isNarrow) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: Color(0x66FFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.forum_outlined,
                  size: 20,
                  color: Color(0xFF44474D),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'Collaboration Hub',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.buttonText.copyWith(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B1B1D),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEDEF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    prjCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF44474D),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.filter_list_rounded,
                  size: 20,
                  color: _filter != 'ALL' ? AppColors.secondary : const Color(0xFF75777E),
                ),
                tooltip: 'Filter remarks',
                onSelected: (val) => setState(() => _filter = val),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'ALL',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 16,
                          color: _filter == 'ALL' ? AppColors.secondary : Colors.transparent,
                        ),
                        const SizedBox(width: 8),
                        const Text('All Messages'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ATTACHMENTS',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 16,
                          color: _filter == 'ATTACHMENTS' ? AppColors.secondary : Colors.transparent,
                        ),
                        const SizedBox(width: 8),
                        const Text('With Attachments Only'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ENGINEER',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 16,
                          color: _filter == 'ENGINEER' ? AppColors.secondary : Colors.transparent,
                        ),
                        const SizedBox(width: 8),
                        const Text('Engineer Remarks Only'),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: Color(0xFF75777E),
                ),
                tooltip: 'Refresh thread',
                onPressed: () {
                  ref.invalidate(projectMessagesProvider(widget.projectId));
                  ref.invalidate(projectFilesProvider(widget.projectId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Discussion refreshed.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3F5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.mark_chat_read_outlined,
                size: 32,
                color: Color(0xFF75777E),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _filter == 'ALL'
                  ? 'No collaboration remarks yet.'
                  : 'No messages match current filter.',
              style: AppTypography.buttonText.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B1B1D),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Technical feedback, seismic parameter adjustments, and CAD vector notes\nbetween Engineer and Draughtsman will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: Color(0xFF75777E),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _lastMessageCount = 0;

  // ─────────────────────────────────────────────────────────
  // MESSAGES LIST & DATE DIVIDERS
  // ─────────────────────────────────────────────────────────
  Widget _buildMessagesList(List<ProjectMessage> messages, String? currentUid, bool isNarrow) {
    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final prevMessage = index > 0 ? messages[index - 1] : null;

        final showDateDivider = prevMessage == null ||
            !_isSameDay(prevMessage.createdAt, message.createdAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateDivider) _buildDateDivider(message.createdAt),
            _buildMessageItem(message, currentUid, isNarrow),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final isYesterday = _isSameDay(date, now.subtract(const Duration(days: 1)));

    final dateText = isToday
        ? 'Today'
        : (isYesterday ? 'Yesterday' : DateFormat('MMMM d, yyyy').format(date));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color: Color(0x4DC5C6CD),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              dateText,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF75777E),
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              color: Color(0x4DC5C6CD),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // INDIVIDUAL MESSAGE ITEM
  // ─────────────────────────────────────────────────────────
  Widget _buildMessageItem(ProjectMessage message, String? currentUid, bool isNarrow) {
    final isDraughtsman = message.senderRole == 'DRAUGHTSMAN';
    final isYou = currentUid != null && message.senderId == currentUid;

    final displayName = isYou
        ? 'You'
        : (isDraughtsman
            ? '${message.senderName} (Draughtsman)'
            : (message.senderRole == 'ENGINEER'
                ? '${message.senderName} (Engineer)'
                : '${message.senderName} (Client)'));

    final timeStr = DateFormat('hh:mm a').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SENDER AVATAR
          _buildAvatar(message.senderRole, isYou),

          const SizedBox(width: AppSpacing.md),

          // CONTENT COLUMN
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name and timestamp
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.buttonText.copyWith(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B1B1D),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: Color(0xFF75777E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // MESSAGE BUBBLE
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3F5), // surface-container-low
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.zero,
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Formatted Text with @mentions and CAD tags
                      _buildFormattedMessageText(message.message),

                      // Real Audio / Voice Note presentation
                      if (message.isVoiceNote)
                        VoiceNotePlayerWidget(
                          fileId: message.attachmentFileId,
                          fileName: message.attachmentName,
                          uniqueId: message.id,
                        ),

                      // File Attachment Card (if present and not audio voice note)
                      if (message.hasDocumentAttachment)
                        _buildAttachmentCard(message),
                    ],
                  ),
                ),

                // Thread Reply Indicator (matching reference)
                if (message.senderRole == 'ENGINEER' && !isYou)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 14,
                          color: const Color(0x4DC5C6CD),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.reply_rounded,
                          size: 14,
                          color: Color(0xFF356EE7),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '1 reply',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF356EE7),
                          ),
                        ),
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

  // ─────────────────────────────────────────────────────────
  // SENDER AVATAR
  // ─────────────────────────────────────────────────────────
  Widget _buildAvatar(String senderRole, bool isYou) {
    Color bg = const Color(0xFFEFEDEF);
    Color iconColor = const Color(0xFF1B1B1D);
    IconData icon = Icons.person_outline_rounded;

    if (isYou || senderRole == 'DRAUGHTSMAN') {
      bg = const Color(0xFFDAE2FF);
      iconColor = const Color(0xFF0453CD);
      icon = Icons.architecture_rounded;
    } else if (senderRole == 'ENGINEER') {
      bg = const Color(0xFFD6E3FF);
      iconColor = const Color(0xFF0D1C32);
      icon = Icons.engineering_outlined;
    }

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0x4DC5C6CD),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FORMATTED MESSAGE TEXT WITH @MENTIONS AND CAD BADGES
  // ─────────────────────────────────────────────────────────
  Widget _buildFormattedMessageText(String content) {
    // Splits message by tokens: @Sarah J. or C-4, S-102, #DWG-XXX
    final mentionRegex = RegExp(r'(@[a-zA-Z0-9_\.]+|[A-Z]-[0-9]+|S-[0-9]+|#DWG-[a-zA-Z0-9]+)');
    final spans = <InlineSpan>[];
    int start = 0;

    for (final match in mentionRegex.allMatches(content)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: content.substring(start, match.start),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF44474D),
          ),
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('@')) {
        // User mention like @Sarah J.
        spans.add(TextSpan(
          text: matchedText,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0453CD), // secondary-container
          ),
        ));
      } else {
        // Structural column or sheet tag like C-4 or S-102
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0x0D000000),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              matchedText,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
          ),
        ));
      }
      start = match.end;
    }

    if (start < content.length) {
      spans.add(TextSpan(
        text: content.substring(start),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          height: 1.5,
          color: Color(0xFF44474D),
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  // ─────────────────────────────────────────────────────────
  // ATTACHMENT CARD INSIDE MESSAGE BUBBLE
  // ─────────────────────────────────────────────────────────
  Widget _buildAttachmentCard(ProjectMessage message) {
    final fileName = message.attachmentName ?? 'Attachment';
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final isDwg = fileName.toLowerCase().endsWith('.dwg') || fileName.toLowerCase().endsWith('.dxf');

    final sizeStr = message.attachmentSize != null
        ? '${(message.attachmentSize! / (1024 * 1024)).toStringAsFixed(1)} MB'
        : 'Download';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: () async {
          if (message.attachmentFileId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File attachment not available.')),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading $fileName...'),
              duration: const Duration(seconds: 1),
            ),
          );

          try {
            await ref.read(fileRepositoryProvider).downloadFile(
              message.attachmentFileId!,
              fileName,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloaded: $fileName'),
                  backgroundColor: AppColors.secondary,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Download failed: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0x80C5C6CD),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPdf
                      ? const Color(0x1ABA1A1A)
                      : (isDwg ? const Color(0x1A0453CD) : const Color(0x1A069669)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isPdf
                      ? Icons.picture_as_pdf_outlined
                      : (isDwg ? Icons.architecture_rounded : Icons.insert_drive_file_outlined),
                  size: 18,
                  color: isPdf
                      ? const Color(0xFFBA1A1A)
                      : (isDwg ? const Color(0xFF0453CD) : const Color(0xFF069669)),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1B1B1D),
                      ),
                    ),
                    Text(
                      sizeStr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        color: Color(0xFF75777E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.download_rounded,
                size: 16,
                color: Color(0xFF75777E),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STAGED ATTACHMENT BANNER
  // ─────────────────────────────────────────────────────────
  Widget _buildStagedAttachmentBanner() {
    final fileName = _selectedAttachmentName ?? 'Attachment';
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final isDwg = fileName.toLowerCase().endsWith('.dwg') || fileName.toLowerCase().endsWith('.dxf');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
      color: const Color(0x0A0453CD),
      child: Row(
        children: [
          Icon(
            isPdf
                ? Icons.picture_as_pdf_outlined
                : (isDwg ? Icons.architecture_rounded : Icons.attach_file_rounded),
            size: 16,
            color: const Color(0xFF0453CD),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Staged Attachment: $fileName${_selectedAttachmentSize != null ? ' (${(_selectedAttachmentSize! / (1024 * 1024)).toStringAsFixed(1)} MB)' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0453CD),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF75777E)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() {
              _selectedAttachmentId = null;
              _selectedAttachmentName = null;
              _selectedAttachmentSize = null;
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // COMPOSER INPUT AREA
  // ─────────────────────────────────────────────────────────
  Widget _buildComposer(List<ProjectFile> existingFiles, bool isNarrow) {
    if (_isRecordingVoiceNote) {
      return Container(
        padding: EdgeInsets.all(isNarrow ? AppSpacing.sm : AppSpacing.md),
        decoration: const BoxDecoration(
          color: Color(0xCCFFFFFF),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        child: VoiceNoteRecorderWidget(
          recorder: ref.read(audioRecorderProvider),
          onSendVoiceNote: _handleSendVoiceNote,
          onCancel: () => setState(() => _isRecordingVoiceNote = false),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isNarrow ? AppSpacing.sm : AppSpacing.md),
      decoration: const BoxDecoration(
        color: Color(0xCCFFFFFF),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ATTACHMENT '+' BUTTON
            PopupMenuButton<String>(
              icon: _isUploadingAttachment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded, color: Color(0xFF75777E)),
              tooltip: 'Add attachment',
              onSelected: (val) {
                if (val == 'upload') {
                  _pickAndUploadAttachment();
                } else if (val == 'project') {
                  _showProjectFilesPicker(existingFiles);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'upload',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Upload from device'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'project',
                  child: Row(
                    children: [
                      Icon(Icons.folder_open_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Choose from project files'),
                    ],
                  ),
                ),
              ],
            ),

            // TEXT FIELD
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF1B1B1D),
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message or use @ to mention...',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF75777E),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),

            // MIC / VOICE BUTTON
            IconButton(
              icon: const Icon(
                Icons.mic_none_rounded,
                size: 20,
                color: Color(0xFF75777E),
              ),
              tooltip: 'Record voice note',
              onPressed: _startVoiceNoteRecording,
            ),

            // SEND BUTTON
            Padding(
              padding: const EdgeInsets.only(bottom: 2, right: 4),
              child: InkWell(
                onTap: _isSending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000), // primary
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: Colors.white,
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

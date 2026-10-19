import 'dart:async';
import 'package:flutter/material.dart';
import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/core/theme/app_spacing.dart';
import 'package:archi_draft/src/features/projects/data/audio_service.dart';
import 'voice_note_player_widget.dart';

class VoiceNoteRecorderWidget extends StatefulWidget {
  final AudioRecorderService recorder;
  final Future<void> Function(RecordedAudio audio) onSendVoiceNote;
  final VoidCallback onCancel;

  const VoiceNoteRecorderWidget({
    super.key,
    required this.recorder,
    required this.onSendVoiceNote,
    required this.onCancel,
  });

  @override
  State<VoiceNoteRecorderWidget> createState() => _VoiceNoteRecorderWidgetState();
}

class _VoiceNoteRecorderWidgetState extends State<VoiceNoteRecorderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  RecordedAudio? _recordedAudio;
  bool _isUploading = false;
  String? _uploadError;

  Duration _elapsed = Duration.zero;
  double _amplitude = 0.0;

  StreamSubscription? _durationSub;
  StreamSubscription? _ampSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _durationSub = widget.recorder.durationStream.listen((dur) {
      if (!mounted) return;
      setState(() => _elapsed = dur);
    });

    _ampSub = widget.recorder.amplitudeStream.listen((amp) {
      if (!mounted) return;
      setState(() => _amplitude = amp);
    });
  }

  @override
  void dispose() {
    _pulseController.stop();
    _pulseController.dispose();
    _durationSub?.cancel();
    _ampSub?.cancel();
    super.dispose();
  }

  Future<void> _stopRecording() async {
    try {
      _pulseController.stop();
      final audio = await widget.recorder.stopRecording();
      if (mounted) {
        setState(() {
          _recordedAudio = audio;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadError = 'Failed to stop recording: $e');
      }
    }
  }

  Future<void> _cancel() async {
    _pulseController.stop();
    await widget.recorder.cancelRecording();
    widget.onCancel();
  }

  Future<void> _confirmSend() async {
    if (_recordedAudio == null || _isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      await widget.onSendVoiceNote(_recordedAudio!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = 'Send failed: $e';
          _isUploading = false;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // 1. PREVIEW & CONFIRM SEND STATE
    if (_recordedAudio != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF9FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.graphic_eq_rounded,
                  size: 16,
                  color: Color(0xFF0453CD),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Preview Voice Note before sending',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1B1D),
                    ),
                  ),
                ),
                if (!_isUploading)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF75777E)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Discard recording',
                    onPressed: _cancel,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: VoiceNotePlayerWidget(
                    initialBytes: _recordedAudio!.bytes,
                    previewUrl: _recordedAudio!.previewUrl,
                    fallbackDuration: _recordedAudio!.duration,
                    uniqueId: 'composer_preview',
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _confirmSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: _isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 14),
                  label: Text(
                    _isUploading ? 'Sending...' : 'Send',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (_uploadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _uploadError!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // 2. ACTIVE RECORDING STATE
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Blinking recording dot
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.4 + 0.6 * _pulseController.value),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 10),

          // Duration display
          Text(
            _formatDuration(_elapsed),
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(width: 12),

          // Real live sound wave indicator
          Expanded(
            child: Row(
              children: List.generate(8, (i) {
                final height = (4.0 + (_amplitude * 16.0 * ((i % 3) + 1) / 2.0)).clamp(4.0, 20.0);
                return Container(
                  width: 2.5,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              }),
            ),
          ),

          // Cancel button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFF75777E)),
            tooltip: 'Cancel recording',
            onPressed: _cancel,
          ),

          const SizedBox(width: 4),

          // Stop button
          ElevatedButton.icon(
            onPressed: _stopRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.stop_rounded, size: 16),
            label: const Text(
              'Stop',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

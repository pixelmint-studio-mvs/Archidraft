import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/active_audio_provider.dart';
import '../../providers/voice_recording_controller.dart';
import '../../utils/app_audio_player.dart';

/// WhatsApp-style Voice Recorder Bar for the Collaboration Hub message composer.
class VoiceRecorderBar extends ConsumerStatefulWidget {
  final String projectId;

  const VoiceRecorderBar({super.key, required this.projectId});

  @override
  ConsumerState<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends ConsumerState<VoiceRecorderBar> with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  AppAudioPlayer? _previewPlayer;
  AppPlayerState _playerState = AppPlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _previewPlayer?.dispose();
    super.dispose();
  }

  void _initPreviewPlayer(VoiceRecordingState state) {
    if (_previewPlayer != null) return;
    final recording = state.result;
    if (recording == null) return;

    _duration = recording.duration;

    final player = createAppAudioPlayer();
    _previewPlayer = player;

    player.onPlayerStateChanged.listen((s) {
      if (mounted) {
        setState(() {
          _playerState = s;
          if (s == AppPlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });

    player.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
        });
      }
    });

    player.onDurationChanged.listen((d) {
      if (mounted && d > Duration.zero) {
        setState(() {
          _duration = d;
        });
      }
    });

    try {
      player.setSourceBytes(recording.bytes, recording.contentType);
    } catch (_) {}
  }

  void _disposePreviewPlayer() {
    _previewPlayer?.pause();
    _previewPlayer?.dispose();
    _previewPlayer = null;
    _playerState = AppPlayerState.stopped;
    _position = Duration.zero;
    _duration = Duration.zero;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(voiceRecordingControllerProvider);
    final controller = ref.read(voiceRecordingControllerProvider.notifier);

    // Synchronize preview player
    if (recordingState.isRecorded && _previewPlayer == null) {
      _initPreviewPlayer(recordingState);
    } else if (!recordingState.isRecorded && _previewPlayer != null) {
      _disposePreviewPlayer();
    }

    // ── 1. ACTIVE RECORDING STATE (WhatsApp Style) ──
    if (recordingState.isRecording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Discard / Trash Can Button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
              tooltip: 'Cancel & Discard',
              onPressed: () => controller.cancelOrDiscard(),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Pulsing Red Recording Dot
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                final pulse = 0.6 + 0.4 * math.sin(_waveController.value * 2 * math.pi);
                return Opacity(
                  opacity: pulse,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.sm),

            // Live Timer
            Text(
              _formatDuration(recordingState.elapsedDuration),
              style: AppTypography.labelMono.copyWith(
                color: AppColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Animated WhatsApp Soundwave Bars
            Expanded(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(16, (i) {
                        final wave = math.sin((_waveController.value * 2 * math.pi) + (i * 0.4)).abs();
                        final barHeight = 6.0 + 16.0 * wave;
                        return Container(
                          width: 3,
                          height: barHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.4 + 0.6 * wave),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Stop / Pause Button (Allows reviewing before sending)
            IconButton(
              icon: const Icon(Icons.pause_circle_outline_rounded, color: AppColors.outline, size: 24),
              tooltip: 'Review before sending',
              onPressed: () => controller.stopRecording(),
            ),

            // Instant Send Button (Stops and sends immediately like WhatsApp)
            FilledButton(
              onPressed: () async {
                await controller.stopRecording();
                await controller.sendVoiceMessage(widget.projectId);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
                minimumSize: const Size(40, 40),
              ),
              child: const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      );
    }

    // ── 2. PREVIEW STATE (Listen before sending) ──
    if (recordingState.isRecorded) {
      final isPlaying = _playerState == AppPlayerState.playing;
      final maxDur = _duration > Duration.zero ? _duration : const Duration(seconds: 1);
      final curPos = _position > maxDur ? maxDur : _position;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Play / Pause Preview Button
            InkWell(
              onTap: () async {
                if (isPlaying) {
                  await _previewPlayer?.pause();
                } else {
                  ref.read(activeAudioPlayerIdProvider.notifier).setActive('preview');
                  await _previewPlayer?.play();
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Scrub Slider
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                      thumbColor: AppColors.primary,
                    ),
                    child: Slider(
                      value: curPos.inMilliseconds.toDouble(),
                      max: maxDur.inMilliseconds.toDouble(),
                      onChanged: (val) {
                        _previewPlayer?.seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: AppTypography.labelMono.copyWith(fontSize: 10, color: AppColors.outline),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: AppTypography.labelMono.copyWith(fontSize: 10, color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Discard Button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.outline, size: 20),
              tooltip: 'Discard',
              onPressed: () {
                _disposePreviewPlayer();
                controller.cancelOrDiscard();
              },
            ),

            // Send Voice Note Button
            FilledButton(
              onPressed: () async {
                _disposePreviewPlayer();
                await controller.sendVoiceMessage(widget.projectId);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
                minimumSize: const Size(40, 40),
              ),
              child: const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      );
    }

    // ── 0. REQUESTING PERMISSION STATE ──
    if (recordingState.isRequestingPermission) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Requesting microphone permission...',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.outline),
              tooltip: 'Cancel',
              onPressed: () => controller.cancelOrDiscard(),
            ),
          ],
        ),
      );
    }

    // ── 3. UPLOADING STATE ──
    if (recordingState.isUploading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Sending voice message...',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // ── 4. FAILURE / RECOVERY STATE ──
    if (recordingState.hasFailure) {
      final canRetrySend = recordingState.result != null;
      final isPermError = recordingState.isPermissionDenied ||
          recordingState.isBlocked ||
          recordingState.errorType == VoiceErrorType.micUnavailable;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                recordingState.errorMessage ?? 'Voice message failed.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.error, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            if (canRetrySend) ...[
              TextButton(
                onPressed: () => controller.sendVoiceMessage(widget.projectId),
                child: const Text('Retry Send'),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.outline),
                tooltip: 'Discard',
                onPressed: () => controller.cancelOrDiscard(),
              ),
            ] else if (isPermError) ...[
              FilledButton.tonal(
                onPressed: () => controller.startRecording(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Try Again'),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.outline),
                tooltip: 'Dismiss',
                onPressed: () => controller.clearFailure(),
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.outline),
                tooltip: 'Dismiss',
                onPressed: () => controller.clearFailure(),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

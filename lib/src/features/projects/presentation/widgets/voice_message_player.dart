import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../api/providers/api_providers.dart';
import '../../domain/project_message.dart';
import '../../providers/active_audio_provider.dart';
import '../../utils/app_audio_player.dart';

/// WhatsApp-style Voice Message Player for the Collaboration Hub.
class VoiceMessagePlayer extends ConsumerStatefulWidget {
  final ProjectMessage message;

  const VoiceMessagePlayer({super.key, required this.message});

  @override
  ConsumerState<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends ConsumerState<VoiceMessagePlayer> {
  late final AppAudioPlayer _player;
  Uint8List? _audioBytes;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  AppPlayerState _playerState = AppPlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;

  bool get _isPlaying => _playerState == AppPlayerState.playing;

  @override
  void initState() {
    super.initState();
    _player = createAppAudioPlayer();

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == AppPlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });

    _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _player.onDurationChanged.listen((dur) {
      if (mounted && dur > Duration.zero) {
        setState(() {
          _duration = dur;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadAndPlay() async {
    final attachmentId = widget.message.attachmentFileId;
    if (attachmentId == null || attachmentId.isEmpty) return;

    // Notify other voice messages to pause
    ref.read(activeAudioPlayerIdProvider.notifier).setActive(widget.message.id);

    if (_audioBytes == null) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      try {
        final apiClient = ref.read(apiClientProvider);
        final rawBytes = await apiClient.downloadBinary('/api/files/$attachmentId/download');
        final bytes = Uint8List.fromList(rawBytes);

        if (bytes.isEmpty) {
          throw Exception('Empty audio recording received');
        }

        final mimeType = widget.message.attachmentContentType ?? 'audio/webm';
        await _player.setSourceBytes(bytes, mimeType);

        if (mounted) {
          setState(() {
            _audioBytes = bytes;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Failed to load audio: $e';
          });
        }
        return;
      }
    }

    try {
      await _player.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Playback error: $e';
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _loadAndPlay();
    }
  }

  void _toggleSpeed() {
    double nextSpeed = 1.0;
    if (_playbackSpeed == 1.0) {
      nextSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      nextSpeed = 2.0;
    } else {
      nextSpeed = 1.0;
    }

    setState(() {
      _playbackSpeed = nextSpeed;
    });
    _player.setSpeed(nextSpeed);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Listen for global active audio changes; pause if another player takes over
    ref.listen<String?>(activeAudioPlayerIdProvider, (previous, next) {
      if (next != widget.message.id && _isPlaying) {
        _player.pause();
      }
    });

    final isEngineer = widget.message.isFromEngineer;
    final accentColor = isEngineer ? AppColors.primary : AppColors.secondary;
    final maxDur = _duration > Duration.zero ? _duration : const Duration(seconds: 1);
    final curPos = _position > maxDur ? maxDur : _position;

    return Container(
      constraints: const BoxConstraints(maxWidth: 380, minWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Large Circular Play / Pause button
              InkWell(
                onTap: _isLoading ? null : _togglePlayPause,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Interactive Waveform / Scrub Slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: accentColor,
                        inactiveTrackColor: accentColor.withValues(alpha: 0.2),
                        thumbColor: accentColor,
                      ),
                      child: Slider(
                        value: curPos.inMilliseconds.toDouble(),
                        max: maxDur.inMilliseconds.toDouble(),
                        onChanged: (val) {
                          if (_audioBytes != null) {
                            _player.seek(Duration(milliseconds: val.toInt()));
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.mic_none_rounded,
                                size: 13,
                                color: accentColor.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatDuration(_position),
                                style: AppTypography.labelMono.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _duration > Duration.zero
                                ? _formatDuration(_duration)
                                : 'Voice note',
                            style: AppTypography.labelMono.copyWith(
                              fontSize: 11,
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // WhatsApp-Style Speed Toggle (1x / 1.5x / 2x)
              InkWell(
                onTap: _toggleSpeed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${_playbackSpeed == 1.0 ? '1' : _playbackSpeed}x',
                    style: AppTypography.labelMono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Error banner if any
          if (_hasError) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: AppTypography.labelMono.copyWith(
                        color: AppColors.error,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _loadAndPlay,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Retry', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

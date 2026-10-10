import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:archi_draft/src/core/theme/app_colors.dart';
import 'package:archi_draft/src/features/api/providers/api_providers.dart';
import 'package:archi_draft/src/features/projects/data/audio_service.dart';

class VoiceNotePlayerWidget extends ConsumerStatefulWidget {
  final String? fileId;
  final String? fileName;
  final Uint8List? initialBytes;
  final String? previewUrl;
  final Duration? fallbackDuration;
  final String uniqueId;

  const VoiceNotePlayerWidget({
    super.key,
    this.fileId,
    this.fileName,
    this.initialBytes,
    this.previewUrl,
    this.fallbackDuration,
    required this.uniqueId,
  });

  @override
  ConsumerState<VoiceNotePlayerWidget> createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends ConsumerState<VoiceNotePlayerWidget> {
  late final AudioPlayerService _player;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  PlaybackState _state = PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Waveform bars height profile matching technical CAD styling
  static const List<double> _barHeights = [6, 14, 8, 18, 10, 16, 6, 12, 10, 15, 8, 4];

  @override
  void initState() {
    super.initState();
    _player = createPlatformPlayer();
    _duration = widget.fallbackDuration ?? const Duration(seconds: 12);

    _player.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _state = state;
        if (state == PlaybackState.playing) {
          ref.read(activeAudioIdProvider.notifier).setActive(widget.uniqueId);
        }
      });
    });

    _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    _player.durationStream.listen((dur) {
      if (!mounted) return;
      if (dur > Duration.zero) {
        setState(() => _duration = dur);
      }
    });

    if (widget.initialBytes != null || widget.previewUrl != null) {
      _loadDirectAudio();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadDirectAudio() async {
    try {
      setState(() => _isLoading = true);
      if (widget.initialBytes != null) {
        await _player.loadFromBytes(widget.initialBytes!);
      } else if (widget.previewUrl != null) {
        await _player.loadFromUrl(widget.previewUrl!);
      }
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Load error';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAndPlayAudio() async {
    if (_state == PlaybackState.playing) {
      await _player.pause();
      return;
    }

    if (_isInitialized) {
      await _player.play();
      return;
    }

    if (widget.fileId == null) {
      setState(() => _errorMessage = 'Missing audio reference');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final audioBytes = await apiClient.downloadBinary('/api/files/${widget.fileId}/download');
      if (audioBytes.isEmpty) {
        throw Exception('Audio file empty');
      }

      await _player.loadFromBytes(
        Uint8List.fromList(audioBytes),
        mimeType: widget.fileName?.toLowerCase().endsWith('.m4a') == true ? 'audio/mp4' : 'audio/webm',
      );
      _isInitialized = true;
      await _player.play();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Audio error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // If another player becomes active, pause this one
    ref.listen<String?>(activeAudioIdProvider, (prev, activeId) {
      if (activeId != null && activeId != widget.uniqueId && _state == PlaybackState.playing) {
        _player.pause();
      }
    });

    final isPlaying = _state == PlaybackState.playing;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final displayTime = isPlaying
        ? _formatDuration(_position)
        : _formatDuration(_duration);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _errorMessage != null
              ? AppColors.error.withValues(alpha: 0.4)
              : const Color(0x80C5C6CD),
          width: 0.5,
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause / Loading button
          InkWell(
            onTap: _isLoading ? null : _fetchAndPlayAudio,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _errorMessage != null
                    ? AppColors.error
                    : const Color(0xFF000000), // primary
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _errorMessage != null
                            ? Icons.replay_rounded
                            : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        size: 18,
                        color: Colors.white,
                      ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Waveform bars with interactive scrub/seek
          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                if (_duration > Duration.zero) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final width = box.size.width;
                  // Estimate progress based on local tap
                  final newPos = Duration(
                    milliseconds: (_duration.inMilliseconds * (details.localPosition.dx / width)).round(),
                  );
                  _player.seek(newPos);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_barHeights.length, (idx) {
                  final barProgress = (idx + 1) / _barHeights.length;
                  final isPassed = progress >= barProgress;

                  return Container(
                    width: 2.5,
                    height: _barHeights[idx],
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? const Color(0xFF000000)
                          : const Color(0xFF000000).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Duration label
          Text(
            _errorMessage ?? displayTime,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _errorMessage != null ? AppColors.error : const Color(0xFF75777E),
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

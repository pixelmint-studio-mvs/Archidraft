// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'voice_recorder_service_interface.dart';

export 'voice_recorder_service_interface.dart';

class WebVoiceRecorderService implements VoiceRecorderService {
  html.MediaStream? _stream;
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _chunks = [];
  Completer<VoiceRecordingResult?>? _stopCompleter;
  String? _currentBlobUrl;
  Duration _currentElapsed = Duration.zero;

  String _currentExt = 'webm';
  String _currentContentType = 'audio/webm';
  bool _isRecording = false;
  bool _isCancelled = false;

  @override
  Future<MicrophonePermissionResult> checkAndRequestPermission() async {
    try {
      // 1. Check navigator.permissions API if supported
      final permissions = html.window.navigator.permissions;
      if (permissions != null) {
        try {
          final status = await permissions.query({'name': 'microphone'});
          if (status.state == 'denied') {
            return MicrophonePermissionResult.permanentlyDenied;
          }
          if (status.state == 'granted') {
            return MicrophonePermissionResult.granted;
          }
        } catch (_) {
          // Some browsers throw on querying microphone permission, continue to getUserMedia
        }
      }

      // 2. Request permission directly via standard getUserMedia
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        return MicrophonePermissionResult.unavailable;
      }

      final stream = await mediaDevices.getUserMedia({'audio': true});
      // Stop probe stream tracks immediately so microphone is released
      for (final track in stream.getAudioTracks()) {
        track.stop();
      }
      return MicrophonePermissionResult.granted;
    } on html.DomException catch (e) {
      debugPrint('Web getUserMedia DOMException: ${e.name} - ${e.message}');
      if (e.name == 'NotAllowedError' || e.name == 'PermissionDeniedError') {
        try {
          final status = await html.window.navigator.permissions?.query({'name': 'microphone'});
          if (status?.state == 'denied') {
            return MicrophonePermissionResult.permanentlyDenied;
          }
        } catch (_) {}
        return MicrophonePermissionResult.denied;
      } else if (e.name == 'NotFoundError' || e.name == 'DevicesNotFoundError') {
        return MicrophonePermissionResult.unavailable;
      }
      return MicrophonePermissionResult.denied;
    } catch (e) {
      debugPrint('Web microphone permission check error: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('notallowed') || errStr.contains('denied') || errStr.contains('permission')) {
        return MicrophonePermissionResult.denied;
      } else if (errStr.contains('notfound') || errStr.contains('device')) {
        return MicrophonePermissionResult.unavailable;
      }
      return MicrophonePermissionResult.denied;
    }
  }

  @override
  Future<bool> hasPermission() async {
    final res = await checkAndRequestPermission();
    return res == MicrophonePermissionResult.granted;
  }

  @override
  Future<void> startRecording() async {
    _cleanupResources();
    _isCancelled = false;

    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw Exception('MediaDevices API is not supported in this browser environment.');
    }

    try {
      final stream = await mediaDevices.getUserMedia({'audio': true});
      _stream = stream;

      // Select supported audio MIME type
      String selectedMime = '';
      if (html.MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
        selectedMime = 'audio/webm;codecs=opus';
        _currentExt = 'webm';
        _currentContentType = 'audio/webm';
      } else if (html.MediaRecorder.isTypeSupported('audio/webm')) {
        selectedMime = 'audio/webm';
        _currentExt = 'webm';
        _currentContentType = 'audio/webm';
      } else if (html.MediaRecorder.isTypeSupported('audio/mp4')) {
        selectedMime = 'audio/mp4';
        _currentExt = 'm4a';
        _currentContentType = 'audio/mp4';
      } else if (html.MediaRecorder.isTypeSupported('audio/ogg;codecs=opus')) {
        selectedMime = 'audio/ogg;codecs=opus';
        _currentExt = 'ogg';
        _currentContentType = 'audio/ogg';
      } else {
        _currentExt = 'webm';
        _currentContentType = 'audio/webm';
      }

      final html.MediaRecorder recorder;
      if (selectedMime.isNotEmpty) {
        recorder = html.MediaRecorder(stream, {'mimeType': selectedMime});
      } else {
        recorder = html.MediaRecorder(stream);
      }

      _mediaRecorder = recorder;
      _chunks.clear();
      _isRecording = true;

      recorder.addEventListener('dataavailable', (event) {
        if (event is html.BlobEvent && event.data != null && event.data!.size > 0) {
          _chunks.add(event.data!);
        }
      });

      recorder.addEventListener('stop', (event) async {
        if (_isCancelled) {
          _cleanupResources();
          if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
            _stopCompleter!.complete(null);
          }
          return;
        }

        try {
          if (_chunks.isEmpty) {
            if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
              _stopCompleter!.complete(null);
            }
            return;
          }

          final combinedBlob = html.Blob(_chunks, _currentContentType);
          if (combinedBlob.size == 0) {
            if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
              _stopCompleter!.complete(null);
            }
            return;
          }

          final bytes = await _blobToBytes(combinedBlob);
          if (bytes.isEmpty) {
            if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
              _stopCompleter!.complete(null);
            }
            return;
          }

          if (_currentBlobUrl != null) {
            try {
              html.Url.revokeObjectUrl(_currentBlobUrl!);
            } catch (_) {}
          }
          _currentBlobUrl = html.Url.createObjectUrlFromBlob(combinedBlob);

          final result = VoiceRecordingResult(
            bytes: bytes,
            path: _currentBlobUrl!,
            extension: _currentExt,
            contentType: _currentContentType,
            duration: _currentElapsed,
          );

          if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
            _stopCompleter!.complete(result);
          }
        } catch (e) {
          if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
            _stopCompleter!.completeError(e);
          }
        } finally {
          _cleanupResources();
        }
      });

      recorder.addEventListener('error', (event) {
        debugPrint('Web MediaRecorder error: $event');
        if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
          _stopCompleter!.completeError(Exception('MediaRecorder encountered an error: $event'));
        }
      });

      // Request data chunks every 200ms
      recorder.start(200);
    } catch (e) {
      _cleanupResources();
      rethrow;
    }
  }

  @override
  Future<VoiceRecordingResult?> stopRecording(Duration elapsedDuration) async {
    final recorder = _mediaRecorder;
    if (recorder == null || !_isRecording) {
      return null;
    }

    _isRecording = false;
    _currentElapsed = elapsedDuration;
    final completer = Completer<VoiceRecordingResult?>();
    _stopCompleter = completer;

    try {
      if (recorder.state != 'inactive') {
        recorder.stop();
      } else {
        return null;
      }
    } catch (e) {
      _cleanupResources();
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _cleanupResources();
        return null;
      },
    );
  }

  @override
  Future<void> cancelRecording() async {
    _isCancelled = true;
    _isRecording = false;
    try {
      if (_mediaRecorder != null && _mediaRecorder!.state != 'inactive') {
        _mediaRecorder!.stop();
      }
    } catch (_) {}
    _cleanupResources();
  }

  @override
  Future<void> dispose() async {
    await cancelRecording();
    if (_currentBlobUrl != null) {
      try {
        html.Url.revokeObjectUrl(_currentBlobUrl!);
      } catch (_) {}
      _currentBlobUrl = null;
    }
  }

  void _cleanupResources() {
    _chunks.clear();
    try {
      if (_stream != null) {
        for (final track in _stream!.getTracks()) {
          track.stop();
        }
        _stream = null;
      }
    } catch (_) {}
    _mediaRecorder = null;
    _isRecording = false;
  }

  Future<Uint8List> _blobToBytes(html.Blob blob) {
    final completer = Completer<Uint8List>();
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(Uint8List.view(result));
      } else if (result is Uint8List) {
        completer.complete(result);
      } else {
        completer.complete(Uint8List(0));
      }
    });
    reader.onError.listen((e) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Failed to read audio blob buffer: $e'));
      }
    });
    reader.readAsArrayBuffer(blob);
    return completer.future;
  }
}

VoiceRecorderService createPlatformVoiceRecorderService() => WebVoiceRecorderService();

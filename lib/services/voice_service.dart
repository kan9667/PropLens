import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _stopCallbackFired = false;

  VoidCallback? _onListeningStopped;
  void Function(String)? _onError;

  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
        debugLogging: kDebugMode,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech init failed: $e');
      return false;
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    debugPrint('Speech Error: ${error.errorMsg}');
    _onError?.call(_friendlyError(error.errorMsg));
    _fireStoppedOnce();
  }

  void _handleSpeechStatus(String status) {
    debugPrint('Speech Status: $status');
    if (status == 'done' || status == 'notListening') {
      _fireStoppedOnce();
    }
  }

  void _fireStoppedOnce() {
    if (_stopCallbackFired) return;
    _stopCallbackFired = true;
    _onListeningStopped?.call();
    _onListeningStopped = null;
    _onError = null;
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('permission') || lower.contains('denied')) {
      return 'Microphone permission is required for voice search.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Voice search needs an internet connection.';
    }
    if (lower.contains('not available') || lower.contains('no speech')) {
      return 'Speech recognition is not available on this device.';
    }
    return 'Voice input failed. Please try again.';
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required void Function(String) onResult,
    required VoidCallback onListeningStopped,
    void Function(String)? onError,
  }) async {
    if (_speech.isListening) {
      await stopListening();
    }

    _stopCallbackFired = false;
    _onListeningStopped = onListeningStopped;
    _onError = onError;

    final hasInit = await init();
    if (!hasInit) {
      onError?.call('Speech recognition is not available on this device.');
      _fireStoppedOnce();
      return;
    }

    if (!await _speech.hasPermission) {
      onError?.call('Microphone permission is required for voice search.');
      _fireStoppedOnce();
      return;
    }

    try {
      final locales = await _speech.locales();
      final localeId = locales.any((l) => l.localeId == 'en_IN')
          ? 'en_IN'
          : (locales.any((l) => l.localeId.startsWith('en')) ? 'en_US' : null);

      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        localeId: localeId,
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Speech listen failed: $e');
      onError?.call('Could not start voice input. Please try again.');
      _fireStoppedOnce();
    }
  }

  Future<void> stopListening() async {
    try {
      if (_isInitialized && _speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('Speech stop failed: $e');
    } finally {
      _fireStoppedOnce();
    }
  }
}

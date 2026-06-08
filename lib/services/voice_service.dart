import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) => debugPrint('Speech Error: $val'),
        onStatus: (val) => debugPrint('Speech Status: $val'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech init failed: $e');
      return false;
    }
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onListeningStopped,
  }) async {
    final hasInit = await init();
    if (!hasInit) {
      onListeningStopped();
      return;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
          if (result.finalResult) {
            onListeningStopped();
          }
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Speech listen failed: $e');
      onListeningStopped();
    }
  }

  Future<void> stopListening() async {
    try {
      if (_isInitialized) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('Speech stop failed: $e');
    }
  }
}
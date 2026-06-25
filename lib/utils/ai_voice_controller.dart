import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AiVoiceController {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechReady = false;

  Future<String?> listenOnce() async {
    if (!_speechReady) {
      _speechReady = await _speech.initialize();
    }

    if (!_speechReady) return null;

    final completer = Completer<String?>();
    String finalWords = '';

    await _speech.listen(
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      onResult: (result) {
        finalWords = result.recognizedWords;

        if (result.finalResult && !completer.isCompleted) {
          completer.complete(finalWords);
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () async {
        await _speech.stop();
        return finalWords.trim().isEmpty ? null : finalWords;
      },
    );
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
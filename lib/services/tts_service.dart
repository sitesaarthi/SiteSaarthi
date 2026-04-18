import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speakFast(String text) async {
    await _tts.stop(); // 🔥 clear previous speech

    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);

    // 🚀 FAST SPEED
    await _tts.setSpeechRate(1.5); // change 1.3–1.8

    // ⚡ NO WAIT DELAY
    await _tts.awaitSpeakCompletion(false);

    await _tts.speak(text);
  }
}
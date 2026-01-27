import "package:flutter/material.dart";
import "package:flutter_tts/flutter_tts.dart";

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String _language = "pt-BR";

  Future<void> init({String? language}) async {
    if (_initialized) return;
    _initialized = true;
    if (language != null) {
      _language = language;
    }
    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(0.95);
    await _tts.awaitSpeakCompletion(true);
    await _selectVoice();
  }

  Future<void> setLanguageFromLocale(Locale locale) async {
    _language = _mapLanguage(locale);
    if (_initialized) {
      await _tts.setLanguage(_language);
      await _selectVoice();
    }
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> _selectVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      final languageCode = _language.split("-").first.toLowerCase();
      Map<dynamic, dynamic>? best;
      for (final voice in voices) {
        if (voice is! Map) continue;
        final locale = (voice["locale"] ?? "").toString().toLowerCase();
        if (!locale.startsWith(languageCode)) continue;
        best ??= voice;
        final name = (voice["name"] ?? "").toString().toLowerCase();
        final quality = (voice["quality"] ?? "").toString().toLowerCase();
        if (name.contains("enhanced") ||
            name.contains("natural") ||
            quality.contains("high")) {
          best = voice;
          break;
        }
      }
      if (best != null) {
        await _tts.setVoice({
          "name": best["name"],
          "locale": best["locale"],
        });
      }
    } catch (_) {}
  }

  String _mapLanguage(Locale locale) {
    final language = locale.languageCode;
    final country = locale.countryCode;
    if (language == "es" && country == "419") {
      return "es-ES";
    }
    if (language == "pt" && country == "PT") {
      return "pt-PT";
    }
    if (language == "en" && country == "GB") {
      return "en-GB";
    }
    switch (language) {
      case "es":
        return "es-ES";
      case "en":
        return "en-US";
      case "pt":
      default:
        return "pt-BR";
    }
  }
}

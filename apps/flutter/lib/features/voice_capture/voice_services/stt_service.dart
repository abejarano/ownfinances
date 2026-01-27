import "package:flutter/material.dart";
import "package:speech_to_text/speech_to_text.dart";

class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  String _localeId = "pt_BR";
  bool _localeLocked = false;

  bool get isAvailable => _available;
  String get localeId => _localeId;

  Future<bool> init({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    _available = await _speech.initialize(
      onStatus: onStatus,
      onError: (error) => onError?.call(error.errorMsg),
    );
    if (_available) {
      final locales = await _speech.locales();
      if (_localeLocked) {
        _localeId = _pickLocaleId(
          locales,
          _parseLocaleId(_localeId),
          _localeId,
        );
      } else {
        final system = await _speech.systemLocale();
        final preferred = system ?? (locales.isNotEmpty ? locales.first : null);
        _localeId = preferred?.localeId ?? "pt_BR";
      }
    }
    return _available;
  }

  Future<void> setLocaleFromLocale(Locale locale) async {
    final fallback = _fallbackLocaleId(locale);
    _localeLocked = true;
    if (!_available) {
      _localeId = fallback;
      return;
    }
    final locales = await _speech.locales();
    _localeId = _pickLocaleId(locales, locale, fallback);
  }

  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_available) return;
    await _speech.listen(
      onResult: (result) => onResult(
        result.recognizedWords,
        result.finalResult,
      ),
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
      localeId: _localeId,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }

  String _pickLocaleId(
    List<LocaleName> locales,
    Locale locale,
    String fallback,
  ) {
    if (locales.isEmpty) return fallback;
    final normalizedLocales = <String, String>{};
    for (final locale in locales) {
      final normalized = _normalizeLocaleId(locale.localeId);
      normalizedLocales[normalized] = locale.localeId;
    }

    for (final candidate in _candidateLocaleIds(locale, fallback)) {
      final normalized = _normalizeLocaleId(candidate);
      final match = normalizedLocales[normalized];
      if (match != null) return match;
    }

    final lang = locale.languageCode.toLowerCase();
    final byLang = locales.firstWhere(
      (item) => _normalizeLocaleId(item.localeId).startsWith(lang),
      orElse: () => locales.first,
    );
    return byLang.localeId;
  }

  Locale _parseLocaleId(String localeId) {
    final parts = localeId.split("_");
    if (parts.length >= 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts.first);
  }

  List<String> _candidateLocaleIds(Locale locale, String fallback) {
    final lang = locale.languageCode.toLowerCase();
    final country = locale.countryCode?.toUpperCase();
    final candidates = <String>[];
    if (country != null && country.isNotEmpty) {
      candidates.add("${lang}_$country");
    }
    switch (lang) {
      case "es":
        if (country == "419") {
          candidates.add("es_419");
        }
        candidates.addAll(["es_ES", "es_US"]);
        break;
      case "pt":
        candidates.addAll(["pt_BR", "pt_PT"]);
        break;
      case "en":
        candidates.addAll(["en_US", "en_GB"]);
        break;
    }
    if (!candidates.contains(fallback)) {
      candidates.add(fallback);
    }
    return candidates;
  }

  String _normalizeLocaleId(String localeId) {
    return localeId.replaceAll("-", "_").toLowerCase();
  }

  String _fallbackLocaleId(Locale locale) {
    switch (locale.languageCode) {
      case "es":
        return "es_ES";
      case "en":
        return "en_US";
      case "pt":
      default:
        return "pt_BR";
    }
  }
}

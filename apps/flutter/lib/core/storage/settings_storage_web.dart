import "dart:html" as html;

import "settings_storage.dart";

class SettingsStorageImpl implements SettingsStorage {
  static const _primaryCurrencyKey = "of_primary_currency";

  @override
  Future<String?> readPrimaryCurrency() async {
    return html.window.localStorage[_primaryCurrencyKey];
  }

  @override
  Future<void> savePrimaryCurrency(String currency) async {
    html.window.localStorage[_primaryCurrencyKey] = currency;
  }

  static const _localeKey = "of_locale";

  @override
  Future<String?> readLocale() async {
    return html.window.localStorage[_localeKey];
  }

  @override
  Future<void> saveLocale(String locale) async {
    html.window.localStorage[_localeKey] = locale;
  }

  static const _countryKey = "of_country";

  @override
  Future<String?> readCountry() async {
    return html.window.localStorage[_countryKey];
  }

  @override
  Future<void> saveCountry(String countryCode) async {
    html.window.localStorage[_countryKey] = countryCode;
  }

  static const _voiceAssistantEnabledKey = "of_voice_assistant_enabled";

  @override
  Future<bool?> readVoiceAssistantEnabled() async {
    final raw = html.window.localStorage[_voiceAssistantEnabledKey];
    if (raw == null) return null;
    return raw.toLowerCase() == "true";
  }

  @override
  Future<void> saveVoiceAssistantEnabled(bool enabled) async {
    html.window.localStorage[_voiceAssistantEnabledKey] = enabled.toString();
  }

  @override
  Future<void> clear() async {
    html.window.localStorage.remove(_primaryCurrencyKey);
    html.window.localStorage.remove(_localeKey);
    html.window.localStorage.remove(_countryKey);
    html.window.localStorage.remove(_voiceAssistantEnabledKey);
  }
}

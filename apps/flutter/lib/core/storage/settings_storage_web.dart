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
}

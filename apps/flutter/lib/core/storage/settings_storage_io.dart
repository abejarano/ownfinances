import "package:flutter_secure_storage/flutter_secure_storage.dart";

import "settings_storage.dart";

class SettingsStorageImpl implements SettingsStorage {
  static const _primaryCurrencyKey = "of_primary_currency";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<String?> readPrimaryCurrency() async {
    return await _storage.read(key: _primaryCurrencyKey);
  }

  @override
  Future<void> savePrimaryCurrency(String currency) async {
    await _storage.write(key: _primaryCurrencyKey, value: currency);
  }

  static const _localeKey = "of_locale";

  @override
  Future<String?> readLocale() async {
    return await _storage.read(key: _localeKey);
  }

  @override
  Future<void> saveLocale(String locale) async {
    await _storage.write(key: _localeKey, value: locale);
  }

  static const _countryKey = "of_country";

  @override
  Future<String?> readCountry() async {
    return await _storage.read(key: _countryKey);
  }

  @override
  Future<void> saveCountry(String countryCode) async {
    await _storage.write(key: _countryKey, value: countryCode);
  }
}

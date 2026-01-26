import "settings_storage_io.dart"
    if (dart.library.html) "settings_storage_web.dart";

abstract class SettingsStorage {
  factory SettingsStorage() = SettingsStorageImpl;

  Future<String?> readPrimaryCurrency();
  Future<void> savePrimaryCurrency(String currency);

  Future<String?> readLocale();
  Future<void> saveLocale(String locale);

  Future<String?> readCountry();
  Future<void> saveCountry(String countryCode);

  Future<void> clear();
}

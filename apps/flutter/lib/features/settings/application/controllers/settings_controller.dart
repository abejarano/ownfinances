import 'package:flutter/material.dart';
import 'package:ownfinances/core/storage/settings_storage.dart';

class SettingsController extends ChangeNotifier {
  final SettingsStorage _storage;

  String _primaryCurrency = "BRL";
  Locale? _locale;
  String? _countryCode;
  bool _isLoading = true;

  SettingsController(this._storage);

  String get primaryCurrency => _primaryCurrency;
  Locale? get locale => _locale;
  String? get countryCode => _countryCode;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storedCurrency = await _storage.readPrimaryCurrency();
      if (storedCurrency != null && storedCurrency.isNotEmpty) {
        _primaryCurrency = storedCurrency;
      }

      final storedLocale = await _storage.readLocale();
      if (storedLocale != null && storedLocale.isNotEmpty) {
        _locale = Locale(storedLocale);
      }

      final storedCountry = await _storage.readCountry();
      if (storedCountry != null && storedCountry.isNotEmpty) {
        _countryCode = storedCountry;
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPrimaryCurrency(String currency) async {
    if (_primaryCurrency == currency) return;

    _primaryCurrency = currency;
    notifyListeners();

    await _storage.savePrimaryCurrency(currency);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    debugPrint("SettingsController: setLocale to ${_locale?.languageCode}");
    notifyListeners();

    await _storage.saveLocale(locale.languageCode);
  }

  Future<void> setCountryCode(String countryCode) async {
    if (_countryCode == countryCode) return;

    _countryCode = countryCode;
    notifyListeners();

    await _storage.saveCountry(countryCode);
  }
}

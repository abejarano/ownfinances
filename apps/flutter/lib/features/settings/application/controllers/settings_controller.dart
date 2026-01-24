import 'package:flutter/material.dart';
import 'package:ownfinances/core/storage/settings_storage.dart';

class SettingsController extends ChangeNotifier {
  final SettingsStorage _storage;

  String _primaryCurrency = "BRL";
  Locale? _locale;
  bool _isLoading = true;

  SettingsController(this._storage);

  String get primaryCurrency => _primaryCurrency;
  Locale? get locale => _locale;
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
}

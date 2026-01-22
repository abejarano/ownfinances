import 'package:flutter/material.dart';
import 'package:ownfinances/core/storage/settings_storage.dart';

class SettingsController extends ChangeNotifier {
  final SettingsStorage _storage;

  String _primaryCurrency = "BRL";
  bool _isLoading = true;

  SettingsController(this._storage);

  String get primaryCurrency => _primaryCurrency;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final stored = await _storage.readPrimaryCurrency();
      if (stored != null && stored.isNotEmpty) {
        _primaryCurrency = stored;
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
}

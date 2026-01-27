import 'package:flutter/material.dart';
import "package:ownfinances/core/storage/settings_storage.dart";
import "package:ownfinances/features/settings/data/repositories/settings_repository.dart";
import "package:ownfinances/features/settings/domain/entities/user_settings.dart";

class SettingsController extends ChangeNotifier {
  final SettingsStorage _storage;
  final SettingsRepository _repository;

  String _primaryCurrency = "BRL";
  Locale? _locale;
  String? _countryCode;
  bool _voiceAssistantEnabled = true;
  bool _isLoading = true;

  SettingsController(this._storage, this._repository);

  String get primaryCurrency => _primaryCurrency;
  Locale? get locale => _locale;
  String? get countryCode => _countryCode;
  bool get voiceAssistantEnabled => _voiceAssistantEnabled;
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
      final normalizedLocale = _normalizeLocale(storedLocale);
      if (normalizedLocale != null) {
        _locale = Locale(normalizedLocale);
      }

      final storedCountry = await _storage.readCountry();
      if (storedCountry != null && storedCountry.isNotEmpty) {
        _countryCode = storedCountry;
      }

      final storedVoiceAssistant = await _storage.readVoiceAssistantEnabled();
      if (storedVoiceAssistant != null) {
        _voiceAssistantEnabled = storedVoiceAssistant;
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncFromRemote() async {
    try {
      final settings = await _repository.fetch();
      if (settings == null) return;
      await _applyRemote(settings);
    } catch (e) {
      debugPrint("Error syncing settings: $e");
    }
  }

  Future<void> setPrimaryCurrency(String currency) async {
    if (_primaryCurrency == currency) return;

    _primaryCurrency = currency;
    notifyListeners();

    await _storage.savePrimaryCurrency(currency);
    await _updateRemote(primaryCurrency: currency);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    debugPrint("SettingsController: setLocale to ${_locale?.languageCode}");
    notifyListeners();

    await _storage.saveLocale(locale.languageCode);
    await _updateRemote(locale: locale.languageCode);
  }

  Future<void> setCountryCode(String countryCode) async {
    if (_countryCode == countryCode) return;

    _countryCode = countryCode;
    notifyListeners();

    await _storage.saveCountry(countryCode);
    await _updateRemote(countryCode: countryCode);
  }

  Future<void> setVoiceAssistantEnabled(bool enabled) async {
    if (_voiceAssistantEnabled == enabled) return;
    _voiceAssistantEnabled = enabled;
    notifyListeners();
    await _storage.saveVoiceAssistantEnabled(enabled);
  }

  Future<void> reset() async {
    _primaryCurrency = "BRL";
    _locale = null;
    _countryCode = null;
    _voiceAssistantEnabled = true;
    _isLoading = false;
    notifyListeners();
    await _storage.clear();
  }

  Future<void> _applyRemote(UserSettings settings) async {
    bool changed = false;
    final remoteCurrency = settings.primaryCurrency;
    if (remoteCurrency != null &&
        remoteCurrency.isNotEmpty &&
        remoteCurrency != _primaryCurrency) {
      _primaryCurrency = remoteCurrency;
      await _storage.savePrimaryCurrency(remoteCurrency);
      changed = true;
    }

    final remoteLocale = _normalizeLocale(settings.locale);
    if (remoteLocale != null && _locale?.languageCode != remoteLocale) {
      _locale = Locale(remoteLocale);
      await _storage.saveLocale(remoteLocale);
      changed = true;
    }

    final remoteCountry = settings.countryCode;
    if (remoteCountry != null &&
        remoteCountry.isNotEmpty &&
        _countryCode != remoteCountry) {
      _countryCode = remoteCountry;
      await _storage.saveCountry(remoteCountry);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<void> _updateRemote({
    String? primaryCurrency,
    String? countryCode,
    String? locale,
  }) async {
    try {
      await _repository.updatePreferences(
        primaryCurrency: primaryCurrency,
        countryCode: countryCode,
        locale: locale,
      );
    } catch (e) {
      debugPrint("Error updating settings: $e");
    }
  }

  String? _normalizeLocale(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll("-", "_");
    final parts = normalized.split("_");
    final languageCode = parts.first;
    if (languageCode.isEmpty) return null;
    return languageCode;
  }
}

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
}

import "package:ownfinances/features/settings/data/datasources/settings_remote_data_source.dart";
import "package:ownfinances/features/settings/domain/entities/user_settings.dart";

class SettingsRepository {
  final SettingsRemoteDataSource remote;

  SettingsRepository(this.remote);

  Future<UserSettings?> fetch() async {
    final payload = await remote.fetch();
    if (payload.isEmpty) return null;
    return UserSettings.fromJson(payload);
  }

  Future<void> updatePreferences({
    String? primaryCurrency,
    String? countryCode,
    String? locale,
  }) async {
    final payload = <String, dynamic>{};
    if (primaryCurrency != null) {
      payload["primaryCurrency"] = primaryCurrency;
    }
    if (countryCode != null) {
      payload["countryCode"] = countryCode;
    }
    if (locale != null) {
      payload["locale"] = locale;
    }
    if (payload.isEmpty) return;
    await remote.update(payload);
  }
}

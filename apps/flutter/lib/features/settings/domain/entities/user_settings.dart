class UserSettings {
  final bool autoGenerateRecurring;
  final String? primaryCurrency;
  final String? countryCode;
  final String? locale;

  const UserSettings({
    required this.autoGenerateRecurring,
    this.primaryCurrency,
    this.countryCode,
    this.locale,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      autoGenerateRecurring: json["autoGenerateRecurring"] as bool? ?? false,
      primaryCurrency: json["primaryCurrency"] as String?,
      countryCode: json["countryCode"] as String?,
      locale: json["locale"] as String?,
    );
  }
}

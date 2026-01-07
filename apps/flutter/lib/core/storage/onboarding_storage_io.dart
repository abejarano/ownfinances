import "package:flutter_secure_storage/flutter_secure_storage.dart";

import "onboarding_storage.dart";

class OnboardingStorageImpl implements OnboardingStorage {
  static const _completedKey = "of_onboarding_completed";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<bool> readCompleted() async {
    final raw = await _storage.read(key: _completedKey);
    return raw == "true";
  }

  @override
  Future<void> setCompleted(bool completed) async {
    await _storage.write(
      key: _completedKey,
      value: completed ? "true" : "false",
    );
  }
}

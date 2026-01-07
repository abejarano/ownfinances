import "dart:html" as html;

import "onboarding_storage.dart";

class OnboardingStorageImpl implements OnboardingStorage {
  static const _completedKey = "of_onboarding_completed";

  @override
  Future<bool> readCompleted() async {
    final raw = html.window.localStorage[_completedKey];
    return raw == "true";
  }

  @override
  Future<void> setCompleted(bool completed) async {
    html.window.localStorage[_completedKey] = completed ? "true" : "false";
  }
}

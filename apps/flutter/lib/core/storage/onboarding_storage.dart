import "onboarding_storage_io.dart"
    if (dart.library.html) "onboarding_storage_web.dart";

abstract class OnboardingStorage {
  factory OnboardingStorage() = OnboardingStorageImpl;

  Future<bool> readCompleted();
  Future<void> setCompleted(bool completed);
}

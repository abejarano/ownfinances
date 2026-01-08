import "package:flutter/material.dart";
import "package:ownfinances/core/storage/onboarding_storage.dart";
import "package:ownfinances/features/accounts/domain/repositories/account_repository.dart";

class OnboardingController extends ChangeNotifier {
  final OnboardingStorage storage;
  final AccountRepository accountRepository;
  bool _completed = false;
  bool _loaded = false;

  OnboardingController(this.storage, this.accountRepository);

  bool get completed => _completed;
  bool get loaded => _loaded;

  Future<void> load() async {
    // 1. Check local storage (fastest)
    _completed = await storage.readCompleted();

    // 2. If not completed locally, check if user has data on server
    // This handles the "new device / new browser" case for existing users
    if (!_completed) {
      try {
        final result = await accountRepository.list(isActive: true);
        if (result.results.isNotEmpty) {
          _completed = true;
          // Sync local storage so we don't need to fetch next time
          await storage.setCompleted(true);
        }
      } catch (_) {
        // If API fails (e.g. no internet), we default to false (show onboarding)
        // or we could optimistically assume true if we wanted, but false is safer here
        // preventing stuck states.
      }
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> complete() async {
    _completed = true;
    _loaded = true;
    await storage.setCompleted(true);
    notifyListeners();
  }
}

import "package:flutter/material.dart";
import "package:ownfinances/core/storage/onboarding_storage.dart";
import "package:ownfinances/features/accounts/data/repositories/account_repository.dart";
import "package:ownfinances/features/categories/data/repositories/category_repository.dart";

class OnboardingController extends ChangeNotifier {
  final OnboardingStorage storage;
  final AccountRepository accountRepository;
  final CategoryRepository categoryRepository;
  bool _completed = false;
  bool _loaded = false;

  OnboardingController(
    this.storage,
    this.accountRepository,
    this.categoryRepository,
  );

  bool get completed => _completed;
  bool get loaded => _loaded;

  Future<void> load() async {
    _completed = await storage.readCompleted();
    _loaded = true;
    notifyListeners();
  }

  Future<bool> checkExistingData() async {
    try {
      final accounts = await accountRepository.list(isActive: true);
      final categories = await categoryRepository.list(isActive: true);
      final hasSetup =
          accounts.results.isNotEmpty || categories.results.isNotEmpty;
      if (hasSetup) {
        await complete();
        return true;
      }
    } catch (_) {
      // Ignore errors
    }
    return false;
  }

  Future<void> complete() async {
    _completed = true;
    _loaded = true;
    await storage.setCompleted(true);
    notifyListeners();
  }

  Future<void> reset() async {
    _completed = false;
    _loaded = true;
    await storage.setCompleted(false);
    notifyListeners();
  }
}

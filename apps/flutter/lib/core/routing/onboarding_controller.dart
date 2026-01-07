import "package:flutter/material.dart";
import "package:ownfinances/core/storage/onboarding_storage.dart";

class OnboardingController extends ChangeNotifier {
  final OnboardingStorage storage;
  bool _completed = false;
  bool _loaded = false;

  OnboardingController(this.storage);

  bool get completed => _completed;
  bool get loaded => _loaded;

  Future<void> load() async {
    _completed = await storage.readCompleted();
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

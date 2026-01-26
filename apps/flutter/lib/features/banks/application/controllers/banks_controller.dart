import "package:flutter/material.dart";
import "package:ownfinances/features/banks/data/repositories/bank_repository.dart";
import "package:ownfinances/features/banks/domain/entities/bank.dart";

class BanksController extends ChangeNotifier {
  final BankRepository repository;

  List<Bank> banks = [];
  bool isLoading = false;
  String? error;

  BanksController(this.repository);

  void reset() {
    banks = [];
    isLoading = false;
    error = null;
    notifyListeners();
  }

  Future<void> load({String? country}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      banks = await repository.list(country: country);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

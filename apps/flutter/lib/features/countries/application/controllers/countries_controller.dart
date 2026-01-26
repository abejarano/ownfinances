import "package:flutter/material.dart";
import "package:ownfinances/features/countries/data/repositories/country_repository.dart";
import "package:ownfinances/features/countries/domain/entities/country.dart";

class CountriesController extends ChangeNotifier {
  final CountryRepository repository;

  List<Country> countries = [];
  bool isLoading = false;
  String? error;

  CountriesController(this.repository);

  void reset() {
    countries = [];
    isLoading = false;
    error = null;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      countries = await repository.list();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

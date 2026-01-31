import "dart:async";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/csv_import/application/state/csv_import_state.dart";
import "package:ownfinances/features/csv_import/data/repositories/csv_import_repository.dart";
import "package:ownfinances/features/csv_import/application/csv_import_copy.dart";

class CsvImportController extends ChangeNotifier {
  final CsvImportRepository repository;

  CsvImportCopy _copy = CsvImportCopy.fallbackPt();
  CsvImportState _state = CsvImportState.initial();

  CsvImportController(this.repository) {}

  void setCopy(CsvImportCopy copy) {
    _copy = copy;
    notifyListeners();
  }

  CsvImportState get state => _state;

  Future<void> selectAccount(String accountId) async {
    _state = _state.copyWith(selectedAccountId: accountId);
    notifyListeners();
  }

  Future<void> loadCsv(String csvContent) async {
    _state = _state.copyWith(csvContent: csvContent);
    notifyListeners();
  }

  Future<void> import(BuildContext? context) async {
    if (_state.selectedAccountId == null || _state.csvContent == null) {
      _state = _state.copyWith(error: _copy.errorSelectAccountAndFile);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    // Guardar contexto para navegación automática cuando llegue la notificación
    // Note: This logic might need further refactoring if context is strictly forbidden in controllers
    // but for now we follow the instruction to fix the localization part.

    try {
      await repository.import(_state.selectedAccountId!, _state.csvContent!);
      // final jobId = result["jobId"] as String?;
      // _state = _state.copyWith(isLoading: false, jobId: jobId);

      reset();

      // Navegar a la pantalla de éxito
      if (context != null && context.mounted) {
        context.push("/csv-import/success");
      }
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  void reset() {
    _state = CsvImportState.initial();
    notifyListeners();
  }

  String _message(dynamic error) {
    if (error is Map && error["error"] != null) {
      return error["error"] as String;
    }
    return error.toString();
  }
}

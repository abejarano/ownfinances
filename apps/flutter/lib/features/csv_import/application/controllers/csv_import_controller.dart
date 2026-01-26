import "dart:async";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/csv_import/application/state/csv_import_state.dart";
import "package:ownfinances/features/csv_import/data/repositories/csv_import_repository.dart";
import "package:ownfinances/core/infrastructure/websocket/websocket_client.dart";

class CsvImportController extends ChangeNotifier {
  final CsvImportRepository repository;
  final WebSocketClient? webSocketClient;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  BuildContext? _context;
  CsvImportState _state = CsvImportState.initial();

  CsvImportController(this.repository, {this.webSocketClient}) {
    _setupWebSocketListener();
  }

  void _setupWebSocketListener() {
    if (webSocketClient == null) return;
    
    _wsSubscription = webSocketClient!.messages.listen((message) {
      if (message["type"] == "import:completed") {
        final jobId = message["jobId"] as String?;
        if (jobId != null && jobId == _state.jobId) {
          // Recargar el job para obtener resultados actualizados
          loadImportJob(jobId);
          // Navegar automáticamente si hay contexto
          if (_context != null && _context!.mounted) {
            _context!.push("/csv-import/result/$jobId");
          }
        }
      }
    });
  }

  void setContext(BuildContext? context) {
    _context = context;
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
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

  Future<void> preview() async {
    if (_state.selectedAccountId == null || _state.csvContent == null) {
      _state = _state.copyWith(error: "Selecione uma conta e carregue o arquivo CSV");
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final preview = await repository.preview(_state.selectedAccountId!, _state.csvContent!);
      _state = _state.copyWith(isLoading: false, preview: preview);
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  Future<void> import(BuildContext? context) async {
    if (_state.selectedAccountId == null || _state.csvContent == null) {
      _state = _state.copyWith(error: "Selecione uma conta e carregue o arquivo CSV");
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    
    // Guardar contexto para navegación automática cuando llegue la notificación
    if (context != null) {
      setContext(context);
    }

    try {
      final result = await repository.import(_state.selectedAccountId!, _state.csvContent!);
      final jobId = result["jobId"] as String?;
      _state = _state.copyWith(isLoading: false, jobId: jobId);
      
      // No navegar inmediatamente, esperar notificación WebSocket
      // La navegación se hará automáticamente cuando llegue la notificación
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  Future<void> loadImportJob(String jobId) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final importJob = await repository.getImportJob(jobId);
      _state = _state.copyWith(isLoading: false, importJob: importJob);
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  void reset() {
    _state = CsvImportState.initial();
    _context = null;
    notifyListeners();
  }

  String _message(dynamic error) {
    if (error is Map && error["error"] != null) {
      return error["error"] as String;
    }
    return error.toString();
  }
}

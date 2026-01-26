import "package:flutter/material.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/features/voice_capture/models/transaction_draft.dart";
import "package:ownfinances/features/voice_capture/voice_services/stt_service.dart";
import "package:ownfinances/features/voice_capture/voice_services/tts_service.dart";

enum VoiceStep {
  listening,
  askingAmount,
  askingAccount,
  askingDate,
  askingCategory,
  confirm,
  saving,
  success,
}

class VoiceCaptureController extends ChangeNotifier {
  VoiceCaptureController({
    required this.ttsService,
    required this.sttService,
    this.intent = "expense",
    this.source = "assistant",
  });

  final TtsService ttsService;
  final SttService sttService;
  final String intent;
  final String source;

  TransactionDraft _draft = const TransactionDraft();
  VoiceStep _step = VoiceStep.listening;
  bool _initialized = false;
  bool _manualMode = false;
  bool _isListening = false;
  bool _micPermissionGranted = true;
  bool _sttAvailable = false;
  int _retryCount = 0;
  String _transcript = "";
  String? _lastError;
  List<Account> _accounts = [];
  List<Category> _categories = [];
  List<Account> _accountMatches = [];
  List<Category> _categoryMatches = [];

  TransactionDraft get draft => _draft;
  VoiceStep get step => _step;
  bool get isListening => _isListening;
  bool get manualMode => _manualMode;
  bool get micPermissionGranted => _micPermissionGranted;
  bool get sttAvailable => _sttAvailable;
  int get retryCount => _retryCount;
  String get transcript => _transcript;
  String? get lastError => _lastError;
  List<Account> get accountMatches => _accountMatches;
  List<Category> get categoryMatches => _categoryMatches;

  String get prompt => _promptForStep(_step);

  void syncData({
    required List<Account> accounts,
    required List<Category> categories,
  }) {
    _accounts = accounts;
    _categories = categories;
  }

  Future<void> start() async {
    if (!_initialized) {
      _initialized = true;
      await ttsService.init();
      await _initStt();
    }
    _step = _nextStep();
    notifyListeners();
    if (_sttAvailable && !_manualMode) {
      await _askCurrentStep();
    }
  }

  Future<void> requestMicPermission() async {
    final available = await _initStt();
    if (available) {
      _manualMode = false;
      _retryCount = 0;
      _lastError = null;
      if (_step == VoiceStep.listening) {
        _step = _nextStep();
      }
      notifyListeners();
      if (_step != VoiceStep.confirm &&
          _step != VoiceStep.saving &&
          _step != VoiceStep.success) {
        await _askCurrentStep();
      }
    }
  }

  Future<bool> _initStt() async {
    final available = await sttService.init(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          _isListening = false;
          notifyListeners();
        }
      },
      onError: (error) {
        _lastError = error;
        _manualMode = true;
        _isListening = false;
        notifyListeners();
      },
    );
    _sttAvailable = available;
    _micPermissionGranted = available;
    if (!available) {
      _manualMode = true;
    }
    notifyListeners();
    return available;
  }

  Future<void> _askCurrentStep() async {
    if (_manualMode || !_sttAvailable) return;
    final nextPrompt = _promptForStep(_step);
    if (nextPrompt.isEmpty) return;
    _transcript = "";
    _lastError = null;
    notifyListeners();
    await ttsService.speak(nextPrompt);
    await _startListening();
  }

  Future<void> _startListening() async {
    if (_manualMode || !_sttAvailable) return;
    _isListening = true;
    notifyListeners();
    await sttService.listen(onResult: _handleSpeechResult);
  }

  void _handleSpeechResult(String text, bool isFinal) {
    _transcript = text;
    notifyListeners();
    if (!isFinal) return;

    _isListening = false;
    final success = _applySpeech(text);
    if (success) {
      _retryCount = 0;
      _advance();
      return;
    }
    _handleParseFailure();
  }

  void _handleParseFailure() {
    if (_manualMode) {
      notifyListeners();
      return;
    }
    _retryCount += 1;
    if (_retryCount >= 2) {
      _manualMode = true;
      _lastError = "Nao entendi. Pode digitar?";
      sttService.stop();
      notifyListeners();
      return;
    }
    _askCurrentStep();
  }

  bool _applySpeech(String text) {
    final normalized = _normalize(text);
    if (normalized.contains("cancelar")) {
      _lastError = "Cancelar";
      return false;
    }

    switch (_step) {
      case VoiceStep.askingAmount:
        final amount = _parseAmount(text);
        if (amount == null || amount <= 0) return false;
        _draft = _draft.copyWith(amount: amount);
        return true;
      case VoiceStep.askingAccount:
        return _applyAccount(normalized);
      case VoiceStep.askingDate:
        final date = _parseDate(normalized);
        if (date == null) return false;
        _draft = _draft.copyWith(date: date);
        return true;
      case VoiceStep.askingCategory:
        return _applyCategory(normalized);
      default:
        return false;
    }
  }

  bool _applyAccount(String normalizedText) {
    final matches = _accounts.where((account) {
      final name = _normalize(account.name);
      return name.contains(normalizedText) || normalizedText.contains(name);
    }).toList();

    if (matches.isEmpty) return false;
    if (matches.length > 1) {
      _accountMatches = matches;
      _forceManual(
        "Encontrei mais de uma conta. Toque para escolher.",
      );
      return false;
    }
    _accountMatches = [];
    _draft = _draft.copyWith(fromAccountId: matches.first.id);
    return true;
  }

  bool _applyCategory(String normalizedText) {
    final expenseCategories =
        _categories.where((category) => category.kind == "expense").toList();

    final matches = expenseCategories.where((category) {
      final name = _normalize(category.name);
      return name.contains(normalizedText) || normalizedText.contains(name);
    }).toList();

    if (matches.isEmpty) {
      final hinted = _categoryHint(normalizedText, expenseCategories);
      if (hinted != null) {
        _draft = _draft.copyWith(categoryId: hinted.id);
        return true;
      }
      return false;
    }
    if (matches.length > 1) {
      _categoryMatches = matches;
      _forceManual(
        "Encontrei mais de uma categoria. Toque para escolher.",
      );
      return false;
    }
    _categoryMatches = [];
    _draft = _draft.copyWith(categoryId: matches.first.id);
    return true;
  }

  void _forceManual(String message) {
    _manualMode = true;
    _lastError = message;
    sttService.stop();
    notifyListeners();
  }

  void setManualMode(bool value) {
    _manualMode = value;
    if (value) {
      sttService.stop();
    } else {
      _retryCount = 0;
      _lastError = null;
      _askCurrentStep();
    }
    notifyListeners();
  }

  void jumpToStep(VoiceStep step) {
    _step = step;
    _retryCount = 0;
    _lastError = null;
    notifyListeners();
    if (!_manualMode && _step != VoiceStep.confirm) {
      _askCurrentStep();
    }
  }

  void setAmount(double amount) {
    _draft = _draft.copyWith(amount: amount);
    _advance();
  }

  void setAccount(Account account) {
    _accountMatches = [];
    _draft = _draft.copyWith(fromAccountId: account.id);
    _advance();
  }

  void setDate(DateTime date) {
    _draft = _draft.copyWith(date: date);
    _advance();
  }

  void setCategory(Category category) {
    _categoryMatches = [];
    _draft = _draft.copyWith(categoryId: category.id);
    _advance();
  }

  void continueFlow() {
    _advance();
  }

  void setSaving() {
    _step = VoiceStep.saving;
    notifyListeners();
  }

  void setSuccess() {
    _step = VoiceStep.success;
    notifyListeners();
  }

  void reset() {
    _draft = const TransactionDraft();
    _step = VoiceStep.listening;
    _retryCount = 0;
    _transcript = "";
    _lastError = null;
    _accountMatches = [];
    _categoryMatches = [];
    _manualMode = !_sttAvailable;
    notifyListeners();
    start();
  }

  void stopListening() {
    _isListening = false;
    sttService.stop();
    notifyListeners();
  }

  void disposeServices() {
    sttService.stop();
    ttsService.stop();
  }

  @override
  void dispose() {
    disposeServices();
    super.dispose();
  }

  VoiceStep _nextStep() {
    if (_draft.amount == null) return VoiceStep.askingAmount;
    if (_draft.fromAccountId == null) return VoiceStep.askingAccount;
    if (_draft.date == null) return VoiceStep.askingDate;
    if (_draft.categoryId == null) return VoiceStep.askingCategory;
    return VoiceStep.confirm;
  }

  void _advance() {
    final next = _nextStep();
    if (_step == next && next != VoiceStep.confirm) return;
    _retryCount = 0;
    _step = next;
    notifyListeners();
    if (_step == VoiceStep.confirm) {
      sttService.stop();
      return;
    }
    if (!_manualMode) {
      _askCurrentStep();
    }
  }

  double? _parseAmount(String raw) {
    final match = RegExp(r"([0-9]+(?:[\\.,][0-9]{1,2})?)").firstMatch(raw);
    if (match == null) return null;
    final cleaned = match.group(1)!.replaceAll(",", ".");
    return double.tryParse(cleaned);
  }

  DateTime? _parseDate(String normalizedText) {
    final now = DateTime.now();
    if (normalizedText.contains("hoje")) {
      return DateTime(now.year, now.month, now.day);
    }
    if (normalizedText.contains("ontem")) {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateTime(yesterday.year, yesterday.month, yesterday.day);
    }
    return null;
  }

  Category? _categoryHint(String normalizedText, List<Category> options) {
    if (normalizedText.contains("mercado")) {
      for (final category in options) {
        if (_normalize(category.name).contains("aliment")) {
          return category;
        }
      }
    }
    return null;
  }

  String _promptForStep(VoiceStep step) {
    switch (step) {
      case VoiceStep.askingAmount:
        return "Qual foi o valor?";
      case VoiceStep.askingAccount:
        return "De qual conta sai esse gasto?";
      case VoiceStep.askingDate:
        return "Foi hoje?";
      case VoiceStep.askingCategory:
        return "Qual categoria?";
      default:
        return "";
    }
  }

  String _normalize(String value) {
    var result = value.toLowerCase();
    const replacements = {
      "á": "a",
      "à": "a",
      "â": "a",
      "ã": "a",
      "é": "e",
      "ê": "e",
      "í": "i",
      "ó": "o",
      "ô": "o",
      "õ": "o",
      "ú": "u",
      "ç": "c",
    };
    replacements.forEach((key, replacement) {
      result = result.replaceAll(key, replacement);
    });
    return result;
  }
}

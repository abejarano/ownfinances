import "package:flutter/material.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/features/voice_capture/models/transaction_draft.dart";
import "package:ownfinances/features/voice_capture/voice_capture_copy.dart";
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

enum _SpeechParseResult {
  success,
  retry,
  handled,
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
  bool _ttsEnabled = true;
  Locale? _locale;
  String? _confirmationText;
  bool _confirmPrompted = false;
  bool _confirmRequested = false;
  bool _cancelRequested = false;
  VoiceCaptureCopy _copy = VoiceCaptureCopy.fallbackPt();
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
  bool get confirmRequested => _confirmRequested;
  bool get cancelRequested => _cancelRequested;
  VoiceCaptureCopy get copy => _copy;

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
        _handleSttError(error);
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
    if (_ttsEnabled) {
      await ttsService.speak(nextPrompt);
    }
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
    final result = _applySpeech(text);
    switch (result) {
      case _SpeechParseResult.success:
        _retryCount = 0;
        _advance();
        return;
      case _SpeechParseResult.handled:
        return;
      case _SpeechParseResult.retry:
        _handleParseFailure();
        return;
    }
  }

  void _handleParseFailure() {
    if (_manualMode) {
      notifyListeners();
      return;
    }
    _retryCount += 1;
    if (_retryCount >= 2) {
      _manualMode = true;
      _lastError = _copy.errorNotUnderstoodType;
      sttService.stop();
      notifyListeners();
      return;
    }
    _askCurrentStep();
  }

  void _handleSttError(String error) {
    final normalized = error.toLowerCase();
    _isListening = false;

    if (normalized.contains("error_no_match") ||
        normalized.contains("error_speech_timeout") ||
        normalized.contains("error_no_speech")) {
      _lastError = _copy.errorRepeat;
      notifyListeners();
      _handleParseFailure();
      return;
    }

    if (normalized.contains("error_permission")) {
      _micPermissionGranted = false;
      _manualMode = true;
      _lastError = _copy.errorMicPermission;
      notifyListeners();
      return;
    }

    _lastError = error;
    _manualMode = true;
    notifyListeners();
  }

  Future<void> setSessionLocale(Locale locale) async {
    if (_locale != null) return;
    _locale = locale;
    await ttsService.setLanguageFromLocale(locale);
    await sttService.setLocaleFromLocale(locale);
  }

  void setCopy(VoiceCaptureCopy copy) {
    _copy = copy;
    notifyListeners();
  }

  void setTtsEnabled(bool enabled) {
    _ttsEnabled = enabled;
  }

  _SpeechParseResult _applySpeech(String text) {
    final normalized = _normalize(text);
    if (_isCancelAnswer(normalized)) {
      _cancelRequested = true;
      _lastError = null;
      _isListening = false;
      sttService.stop();
      notifyListeners();
      return _SpeechParseResult.handled;
    }

    switch (_step) {
      case VoiceStep.askingAmount:
        if (_maybeHandleHelpIntent(normalized)) {
          return _SpeechParseResult.handled;
        }
        final amount = _parseAmount(text);
        if (amount == null || amount <= 0) return _SpeechParseResult.retry;
        _draft = _draft.copyWith(amount: amount);
        return _SpeechParseResult.success;
      case VoiceStep.askingAccount:
        if (_maybeHandleHelpIntent(normalized)) {
          return _SpeechParseResult.handled;
        }
        return _applyAccount(normalized)
            ? _SpeechParseResult.success
            : _SpeechParseResult.retry;
      case VoiceStep.askingDate:
        if (_isNegativeAnswer(normalized)) {
          _manualMode = true;
          _lastError = _copy.dateSelectPrompt;
          sttService.stop();
          notifyListeners();
          return _SpeechParseResult.handled;
        }
        if (_maybeHandleHelpIntent(normalized)) {
          return _SpeechParseResult.handled;
        }
        final date = _parseDate(normalized);
        if (date == null) return _SpeechParseResult.retry;
        _draft = _draft.copyWith(date: date);
        return _SpeechParseResult.success;
      case VoiceStep.askingCategory:
        if (_maybeHandleHelpIntent(normalized)) {
          return _SpeechParseResult.handled;
        }
        return _applyCategory(normalized)
            ? _SpeechParseResult.success
            : _SpeechParseResult.retry;
      case VoiceStep.confirm:
        if (_isConfirmAnswer(normalized)) {
          _confirmRequested = true;
          notifyListeners();
          return _SpeechParseResult.handled;
        }
        if (_isNegativeAnswer(normalized) || normalized.contains("editar")) {
          _manualMode = true;
          _lastError = _copy.editPrompt;
          notifyListeners();
          return _SpeechParseResult.handled;
        }
        return _SpeechParseResult.retry;
      default:
        return _SpeechParseResult.retry;
    }
  }

  bool _applyAccount(String normalizedText) {
    final matches = _matchByTokens(
      normalizedText,
      _accounts.map((account) => (id: account.id, name: account.name)).toList(),
    );

    if (matches.isEmpty) return false;
    if (matches.length > 1) {
      _accountMatches =
          _accounts.where((account) => matches.contains(account.id)).toList();
      _forceManual(_copy.multipleAccounts);
      return false;
    }
    _accountMatches = [];
    _draft = _draft.copyWith(fromAccountId: matches.first);
    return true;
  }

  bool _applyCategory(String normalizedText) {
    final expenseCategories =
        _categories.where((category) => category.kind == "expense").toList();

    final matches = _matchByTokens(
      normalizedText,
      expenseCategories
          .map((category) => (id: category.id, name: category.name))
          .toList(),
    );

    if (matches.isEmpty) {
      final hinted = _categoryHint(normalizedText, expenseCategories);
      if (hinted != null) {
        _draft = _draft.copyWith(categoryId: hinted.id);
        return true;
      }
      return false;
    }
    if (matches.length > 1) {
      _categoryMatches = expenseCategories
          .where((category) => matches.contains(category.id))
          .toList();
      _forceManual(_copy.multipleCategories);
      return false;
    }
    _categoryMatches = [];
    _draft = _draft.copyWith(categoryId: matches.first);
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
    if (step != VoiceStep.confirm) {
      _confirmPrompted = false;
    }
    notifyListeners();
    if (!_manualMode && _step != VoiceStep.confirm) {
      _askCurrentStep();
    }
    if (_step == VoiceStep.confirm && !_manualMode) {
      _askConfirmation();
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

  void setConfirmationText(String text) {
    if (_confirmationText == text) return;
    _confirmationText = text;
    if (_step == VoiceStep.confirm && !_manualMode) {
      _confirmPrompted = false;
      _askConfirmation();
    }
  }

  bool consumeConfirmRequested() {
    if (!_confirmRequested) return false;
    _confirmRequested = false;
    return true;
  }

  bool consumeCancelRequested() {
    if (!_cancelRequested) return false;
    _cancelRequested = false;
    return true;
  }

  void reset() {
    _draft = const TransactionDraft();
    _step = VoiceStep.listening;
    _retryCount = 0;
    _transcript = "";
    _lastError = null;
    _confirmationText = null;
    _confirmPrompted = false;
    _confirmRequested = false;
    _cancelRequested = false;
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
      if (!_manualMode) {
        _askConfirmation();
      }
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
    if (_isPositiveAnswer(normalizedText) ||
        normalizedText.contains("hoje") ||
        normalizedText.contains("hoy") ||
        normalizedText.contains("today")) {
      return DateTime(now.year, now.month, now.day);
    }
    if (normalizedText.contains("ontem") ||
        normalizedText.contains("ayer") ||
        normalizedText.contains("yesterday")) {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateTime(yesterday.year, yesterday.month, yesterday.day);
    }
    return null;
  }

  void _askConfirmation() {
    if (_confirmPrompted || _confirmationText == null) return;
    if (_manualMode || !_sttAvailable) return;
    _confirmPrompted = true;
    _lastError = null;
    notifyListeners();
    final prompt = _copy.confirmPrompt(_confirmationText!);
    if (_ttsEnabled) {
      ttsService.speak(prompt).then((_) => _startListening());
    } else {
      _startListening();
    }
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
        return _copy.promptAmount;
      case VoiceStep.askingAccount:
        return _copy.promptAccount;
      case VoiceStep.askingDate:
        return _copy.promptDate;
      case VoiceStep.askingCategory:
        return _copy.promptCategory;
      default:
        return "";
    }
  }

  bool _maybeHandleHelpIntent(String normalizedText) {
    final isAccountStep = _step == VoiceStep.askingAccount;
    final isCategoryStep = _step == VoiceStep.askingCategory;
    if (!isAccountStep && !isCategoryStep) return false;

    final triggerWords = [
      "quais",
      "qual",
      "que",
      "cuantas",
      "cuantos",
      "mostrar",
      "listar",
      "cuales",
      "what",
      "which",
      "show",
      "list",
      "my",
      "mis",
      "minhas",
    ];
    final accountWords = [
      "conta",
      "contas",
      "banco",
      "bancos",
      "account",
      "accounts",
      "bank",
      "banks",
      "cuenta",
      "cuentas",
    ];
    final categoryWords = [
      "categoria",
      "categorias",
      "category",
      "categories",
    ];

    final hasTrigger = triggerWords.any(normalizedText.contains);
    if (isAccountStep &&
        hasTrigger &&
        accountWords.any(normalizedText.contains)) {
      _respondWithAccounts();
      return true;
    }
    if (isCategoryStep &&
        hasTrigger &&
        categoryWords.any(normalizedText.contains)) {
      _respondWithCategories();
      return true;
    }
    return false;
  }

  void _respondWithAccounts() {
    sttService.stop();
    final names = _accounts.map((account) => account.name).toList();
    final response = names.isEmpty
        ? _copy.noAccounts
        : _copy.accountsList(_joinList(names));
    _speakThenRepeat(response);
  }

  void _respondWithCategories() {
    sttService.stop();
    final options = _categories
        .where((category) => category.kind == "expense")
        .map((category) => category.name)
        .toList();
    final response = options.isEmpty
        ? _copy.noCategories
        : _copy.categoriesList(_joinList(options));
    _speakThenRepeat(response);
  }

  void _speakThenRepeat(String response) {
    _retryCount = 0;
    if (_ttsEnabled) {
      _lastError = null;
      notifyListeners();
      ttsService.speak(response).then((_) => _askCurrentStep());
    } else {
      _lastError = response;
      notifyListeners();
      _askCurrentStep();
    }
  }

  List<String> _matchByTokens(
    String normalizedText,
    List<({String id, String name})> options,
  ) {
    final tokens = _tokenize(normalizedText);
    if (tokens.isEmpty) return [];

    final scored = <String, int>{};
    for (final option in options) {
      final name = _normalizeForMatch(option.name);
      var score = 0;
      for (final token in tokens) {
        if (name.contains(token)) {
          score += token.length >= 4 ? 2 : 1;
        }
      }
      if (name.contains(normalizedText) || normalizedText.contains(name)) {
        score += 3;
      }
      if (score > 0) {
        scored[option.id] = score;
      }
    }

    if (scored.isEmpty) return [];
    final maxScore = scored.values.reduce((a, b) => a > b ? a : b);
    final winners =
        scored.entries.where((entry) => entry.value == maxScore).toList();
    return winners.map((entry) => entry.key).toList();
  }

  List<String> _tokenize(String text) {
    final cleaned = _normalizeForMatch(text);
    final rawTokens = cleaned.split(" ").where((t) => t.isNotEmpty).toList();
    if (rawTokens.isEmpty) return [];
    const stopwords = {
      "de",
      "da",
      "do",
      "del",
      "la",
      "el",
      "los",
      "las",
      "my",
      "mis",
      "minhas",
      "conta",
      "contas",
      "banco",
      "bancos",
      "account",
      "accounts",
      "bank",
      "banks",
      "cuenta",
      "cuentas",
      "categoria",
      "categorias",
      "category",
      "categories",
    };
    return rawTokens.where((token) => !stopwords.contains(token)).toList();
  }

  String _normalizeForMatch(String value) {
    final lowered = _normalize(value);
    final cleaned = lowered.replaceAll(RegExp(r"[^a-z0-9]+"), " ");
    return cleaned.trim().replaceAll(RegExp(r"\\s+"), " ");
  }

  String _joinList(List<String> items) {
    if (items.isEmpty) return "";
    final limited = [...items];
    if (limited.length == 1) return limited.first;
    final last = limited.removeLast();
    final conjunction = _copy.conjunction;
    return "${limited.join(", ")} $conjunction $last";
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

  bool _isPositiveAnswer(String normalizedText) {
    return normalizedText == "sim" ||
        normalizedText == "si" ||
        normalizedText == "ok" ||
        normalizedText == "claro" ||
        normalizedText == "yes" ||
        normalizedText == "yeah" ||
        normalizedText == "yep";
  }

  bool _isNegativeAnswer(String normalizedText) {
    return normalizedText == "nao" ||
        normalizedText == "no" ||
        normalizedText == "nope" ||
        normalizedText == "nop" ||
        normalizedText == "nah";
  }

  bool _isConfirmAnswer(String normalizedText) {
    const tokens = [
      "confirmado",
      "confirmar",
      "confirmo",
      "correto",
      "certo",
      "ok",
      "okay",
      "vale",
      "sim",
      "si",
      "yes",
      "yeah",
      "yep",
    ];
    return tokens.any(normalizedText.contains);
  }

  bool _isCancelAnswer(String normalizedText) {
    return normalizedText.contains("cancel");
  }
}

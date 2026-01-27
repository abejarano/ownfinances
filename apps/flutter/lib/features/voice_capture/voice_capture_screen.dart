import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/settings/application/controllers/settings_controller.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/voice_capture/voice_capture_copy.dart";
import "package:ownfinances/features/voice_capture/voice_capture_controller.dart";
import "package:ownfinances/features/voice_capture/voice_services/stt_service.dart";
import "package:ownfinances/features/voice_capture/voice_services/tts_service.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class VoiceCaptureScreen extends StatefulWidget {
  final String? intent;
  final String? source;

  const VoiceCaptureScreen({super.key, this.intent, this.source});

  @override
  State<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

class _VoiceCaptureScreenState extends State<VoiceCaptureScreen>
    with WidgetsBindingObserver {
  late final VoiceCaptureController _controller;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  Locale? _sessionLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VoiceCaptureController(
      ttsService: TtsService(),
      sttService: SttService(),
      intent: widget.intent ?? "expense",
      source: widget.source ?? "assistant",
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.start();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionLocale != null) return;
    final settingsController = context.read<SettingsController>();
    final settingsLocale = settingsController.locale;
    final deviceLocale = Localizations.localeOf(context);
    _sessionLocale = _resolveSessionLocale(
      userLocale: settingsLocale,
      deviceLocale: deviceLocale,
    );
    final l10n = AppLocalizations.of(context)!;
    _controller.setCopy(VoiceCaptureCopy.fromL10n(l10n));
    _controller.setSessionLocale(_sessionLocale!);
    _controller.setTtsEnabled(settingsController.voiceAssistantEnabled);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controller.stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accounts = context.watch<AccountsController>().state.items;
    final categories = context.watch<CategoriesController>().state.items;
    _controller.syncData(accounts: accounts, categories: categories);

    return Scaffold(
      backgroundColor: const Color(0xB3000000),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final theme = Theme.of(context);
            final step = _controller.step;
            final account = _findAccount(accounts, _controller.draft.fromAccountId);
            final category = _findCategory(
              categories,
              _controller.draft.categoryId,
            );
            final amount = _controller.draft.amount;
            final date = _controller.draft.date;
            final currency = account?.currency ?? "BRL";

            _syncAmountField(amount);

            if (_controller.consumeConfirmRequested()) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _saveTransaction(account, category, amount, date, l10n);
              });
            }
            if (_controller.consumeCancelRequested()) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).maybePop();
              });
            }

            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.72,
                decoration: const BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, l10n),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPrompt(theme, step),
                            const SizedBox(height: AppSpacing.md),
                            _buildListeningRow(theme, l10n),
                            const SizedBox(height: AppSpacing.sm),
                            _buildTranscript(theme, l10n),
                            if (_controller.lastError != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Text(
                                  _controller.lastError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            const SizedBox(height: AppSpacing.md),
                            _buildProgressChips(
                              theme,
                              l10n,
                              amount: amount,
                              account: account,
                              category: category,
                              date: date,
                              currency: currency,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildStepContent(
                              theme,
                              l10n,
                              step: step,
                              accounts: accounts,
                              categories: categories,
                              account: account,
                              category: category,
                              amount: amount,
                              date: date,
                              currency: currency,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _buildFooter(
                      step: step,
                      account: account,
                      category: category,
                      amount: amount,
                      date: date,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _titleForIntent(_controller.intent, l10n),
              style: theme.textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () => _controller.setManualMode(true),
            child: Text(l10n.voiceButtonType),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt(ThemeData theme, VoiceStep step) {
    final prompt = _controller.prompt;
    if (prompt.isEmpty) return const SizedBox.shrink();
    return Text(
      prompt,
      style: theme.textTheme.titleMedium,
    );
  }

  Widget _buildListeningRow(ThemeData theme, AppLocalizations l10n) {
    final status = _controller.isListening
        ? l10n.voiceStatusListening
        : _controller.manualMode
        ? l10n.voiceStatusManual
        : l10n.voiceStatusWaiting;
    return Row(
      children: [
        MicPulse(active: _controller.isListening),
        const SizedBox(width: AppSpacing.sm),
        Text(status, style: theme.textTheme.bodyMedium),
        const Spacer(),
        if (!_controller.micPermissionGranted)
          TextButton(
            onPressed: _controller.requestMicPermission,
            child: Text(l10n.voicePermissionButton),
          ),
      ],
    );
  }

  Widget _buildTranscript(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        _controller.transcript.isEmpty
            ? l10n.voiceTranscriptPlaceholder
            : _controller.transcript,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: _controller.transcript.isEmpty
              ? AppColors.textTertiary
              : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProgressChips(
    ThemeData theme,
    AppLocalizations l10n, {
    required double? amount,
    required Account? account,
    required Category? category,
    required DateTime? date,
    required String currency,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        InputChip(
          label: Text(
            amount == null ? l10n.voiceChipAmount : _formatAmount(amount, currency),
          ),
          selected: _controller.step == VoiceStep.askingAmount,
          onSelected: (_) {
            _controller.setManualMode(true);
            _controller.jumpToStep(VoiceStep.askingAmount);
          },
        ),
        InputChip(
          label: Text(account?.name ?? l10n.voiceChipAccount),
          selected: _controller.step == VoiceStep.askingAccount,
          onSelected: (_) {
            _controller.setManualMode(true);
            _controller.jumpToStep(VoiceStep.askingAccount);
          },
        ),
        InputChip(
          label: Text(_formatDateLabel(date, l10n)),
          selected: _controller.step == VoiceStep.askingDate,
          onSelected: (_) {
            _controller.setManualMode(true);
            _controller.jumpToStep(VoiceStep.askingDate);
          },
        ),
        InputChip(
          label: Text(category?.name ?? l10n.voiceChipCategory),
          selected: _controller.step == VoiceStep.askingCategory,
          onSelected: (_) {
            _controller.setManualMode(true);
            _controller.jumpToStep(VoiceStep.askingCategory);
          },
        ),
      ],
    );
  }

  Widget _buildStepContent(
    ThemeData theme,
    AppLocalizations l10n, {
    required VoiceStep step,
    required List<Account> accounts,
    required List<Category> categories,
    required Account? account,
    required Category? category,
    required double? amount,
    required DateTime? date,
    required String currency,
  }) {
    switch (step) {
      case VoiceStep.askingAmount:
        return _buildAmountInput(theme, currency, l10n);
      case VoiceStep.askingAccount:
        return _buildAccountSelector(theme, accounts, l10n);
      case VoiceStep.askingDate:
        return _buildDateSelector(theme, date, l10n);
      case VoiceStep.askingCategory:
        return _buildCategorySelector(theme, categories, l10n);
      case VoiceStep.confirm:
        _controller.setConfirmationText(
          _summaryText(account, category, amount, date, l10n),
        );
        return _buildConfirmation(theme, account, category, amount, date, l10n);
      case VoiceStep.saving:
        return _buildSaving(theme, l10n);
      case VoiceStep.success:
        return _buildSuccess(theme, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAmountInput(
    ThemeData theme,
    String currency,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.voiceAmountLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _amountController,
          focusNode: _amountFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
          decoration: InputDecoration(
            hintText: "0,00",
            prefixText: currency == "BRL" ? "R\$ " : "$currency ",
          ),
          onSubmitted: (_) => _handleAmountSubmit(l10n),
        ),
      ],
    );
  }

  Widget _buildAccountSelector(
    ThemeData theme,
    List<Account> accounts,
    AppLocalizations l10n,
  ) {
    final options = _controller.accountMatches.isNotEmpty
        ? _controller.accountMatches
        : accounts;
    final visible = options.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.voiceAccountLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        ...visible.map(
          (account) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(account.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _controller.setAccount(account),
          ),
        ),
        if (options.length > visible.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _showAccountPicker(accounts, l10n),
              child: Text(l10n.voiceAccountAll),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSelector(
    ThemeData theme,
    DateTime? date,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.voiceDateLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: Text(l10n.voiceDateToday),
              selected: _isToday(date),
              onSelected: (_) => _controller.setDate(DateTime.now()),
            ),
            ChoiceChip(
              label: Text(l10n.voiceDateYesterday),
              selected: _isYesterday(date),
              onSelected: (_) => _controller.setDate(
                DateTime.now().subtract(const Duration(days: 1)),
              ),
            ),
            ChoiceChip(
              label: Text(l10n.voiceDateOther),
              selected: date != null && !_isToday(date) && !_isYesterday(date),
              onSelected: (_) => _pickDate(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
    ThemeData theme,
    List<Category> categories,
    AppLocalizations l10n,
  ) {
    final options = categories
        .where((category) => category.kind == "expense")
        .toList();
    final visible = (_controller.categoryMatches.isNotEmpty
            ? _controller.categoryMatches
            : options)
        .take(6)
        .toList();
    final fallback = _defaultCategory(options);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.voiceCategoryLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ...visible.map(
              (category) => ChoiceChip(
                label: Text(category.name),
                selected: _controller.draft.categoryId == category.id,
                onSelected: (_) => _controller.setCategory(category),
              ),
            ),
          ],
        ),
        if (fallback != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: TextButton(
              onPressed: () => _controller.setCategory(fallback),
              child: Text(l10n.voiceCategoryUncategorized),
            ),
          ),
        if (options.length > visible.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _showCategoryPicker(options, l10n),
              child: Text(l10n.voiceCategoryAll),
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmation(
    ThemeData theme,
    Account? account,
    Category? category,
    double? amount,
    DateTime? date,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.voiceConfirmTitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _summaryText(account, category, amount, date, l10n),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () {
            _controller.setManualMode(true);
            _controller.jumpToStep(VoiceStep.askingAmount);
          },
          icon: const Icon(Icons.edit),
          label: Text(l10n.voiceEditButton),
        ),
      ],
    );
  }

  Widget _buildSaving(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(l10n.voiceSavingLabel, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.success),
        const SizedBox(width: AppSpacing.sm),
        Text(l10n.voiceSuccessLabel, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildFooter({
    required VoiceStep step,
    required Account? account,
    required Category? category,
    required double? amount,
    required DateTime? date,
    required AppLocalizations l10n,
  }) {
    final primaryLabel = _primaryLabel(step, l10n);
    final secondaryLabel =
        step == VoiceStep.success ? l10n.voiceSecondaryClose : l10n.voiceSecondaryCancel;
    final isSaving = step == VoiceStep.saving;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () => _handlePrimaryAction(
                        step,
                        account: account,
                        category: category,
                        amount: amount,
                        date: date,
                        l10n: l10n,
                      ),
              child: Text(primaryLabel),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(secondaryLabel),
          ),
        ],
      ),
    );
  }

  void _handlePrimaryAction(
    VoiceStep step, {
    required Account? account,
    required Category? category,
    required double? amount,
    required DateTime? date,
    required AppLocalizations l10n,
  }) {
    switch (step) {
      case VoiceStep.askingAmount:
        _handleAmountSubmit(l10n);
        return;
      case VoiceStep.askingAccount:
        if (_controller.draft.fromAccountId == null) {
          showStandardSnackbar(context, l10n.voiceSnackbarMissingAccount);
          return;
        }
        _controller.continueFlow();
        return;
      case VoiceStep.askingDate:
        if (_controller.draft.date == null) {
          _controller.setDate(DateTime.now());
          return;
        }
        _controller.continueFlow();
        return;
      case VoiceStep.askingCategory:
        if (_controller.draft.categoryId == null) {
          showStandardSnackbar(context, l10n.voiceSnackbarMissingCategory);
          return;
        }
        _controller.continueFlow();
        return;
      case VoiceStep.confirm:
        _saveTransaction(account, category, amount, date, l10n);
        return;
      case VoiceStep.success:
        _amountController.clear();
        _controller.reset();
        return;
      default:
        return;
    }
  }

  Future<void> _saveTransaction(
    Account? account,
    Category? category,
    double? amount,
    DateTime? date,
    AppLocalizations l10n,
  ) async {
    final fallbackCategory = _defaultCategory(
      context
          .read<CategoriesController>()
          .state
          .items
          .where((item) => item.kind == "expense")
          .toList(),
    );

    if (amount == null || amount <= 0) {
      showStandardSnackbar(context, l10n.voiceSnackbarInvalidAmount);
      return;
    }
    if (account == null) {
      showStandardSnackbar(context, l10n.voiceSnackbarMissingAccount);
      return;
    }
    final categoryToUse = category ?? fallbackCategory;
    if (categoryToUse == null) {
      showStandardSnackbar(context, l10n.voiceSnackbarMissingCategory);
      return;
    }

    final payload = {
      "type": "expense",
      "date": (date ?? DateTime.now()).toIso8601String(),
      "amount": amount,
      "categoryId": categoryToUse.id,
      "fromAccountId": account.id,
      "toAccountId": null,
      "note": null,
      "tags": null,
      "status": "cleared",
    };

    _controller.setSaving();
    final reportsController = context.read<ReportsController>();
    final period = reportsController.state.period;
    final created = await context
        .read<TransactionsController>()
        .createWithImpact(payload: payload, period: period);

    if (!mounted) return;

    if (created == null) {
      _controller.jumpToStep(VoiceStep.confirm);
      showStandardSnackbar(context, l10n.voiceSnackbarSaveError);
      return;
    }

    context.read<TransactionsController>().rememberDefaults(
      created.transaction,
    );
    if (created.impact != null) {
      reportsController.applyImpactFromJson(created.impact!);
    } else {
      await reportsController.load();
    }

    _controller.setSuccess();
  }

  void _handleAmountSubmit(AppLocalizations l10n) {
    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      showStandardSnackbar(context, l10n.voiceSnackbarAmountRequired);
      return;
    }
    _controller.setAmount(amount);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (selected != null) {
      _controller.setDate(selected);
    }
  }

  void _syncAmountField(double? amount) {
    if (_amountFocus.hasFocus) return;
    if (amount == null) {
      if (_amountController.text.isNotEmpty) {
        _amountController.text = "";
      }
      return;
    }
    final formatted = amount.toStringAsFixed(2).replaceAll(".", ",");
    if (_amountController.text != formatted) {
      _amountController.text = formatted;
    }
  }

  double? _parseAmount(String raw) {
    final match = RegExp(r"([0-9]+(?:[\\.,][0-9]{1,2})?)").firstMatch(raw);
    if (match == null) return null;
    final cleaned = match.group(1)!.replaceAll(",", ".");
    return double.tryParse(cleaned);
  }

  Account? _findAccount(List<Account> accounts, String? id) {
    if (id == null) return null;
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  Category? _findCategory(List<Category> categories, String? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Category? _defaultCategory(List<Category> categories) {
    for (final category in categories) {
      if (category.name.toLowerCase() == "outros") return category;
    }
    return null;
  }

  String _formatAmount(double amount, String currency) {
    if (currency == "BRL") {
      return formatMoney(amount, symbol: "R\$");
    }
    return formatCurrency(amount, currency);
  }

  String _formatDateLabel(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.voiceChipDate;
    if (_isToday(date)) return l10n.voiceDateToday;
    if (_isYesterday(date)) return l10n.voiceDateYesterday;
    return formatDate(date);
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime? date) {
    if (date == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String _summaryText(
    Account? account,
    Category? category,
    double? amount,
    DateTime? date,
    AppLocalizations l10n,
  ) {
    final safeAmount =
        amount == null ? "--" : _formatAmount(amount, account?.currency ?? "BRL");
    final safeCategory = category?.name ?? l10n.voiceCategoryUncategorized;
    final safeAccount = account?.name ?? l10n.voiceChipAccount;
    final safeDate = _formatDateLabel(date, l10n);
    return _controller.copy.summaryText(
      amount: safeAmount,
      category: safeCategory,
      account: safeAccount,
      date: safeDate,
    );
  }

  String _primaryLabel(VoiceStep step, AppLocalizations l10n) {
    switch (step) {
      case VoiceStep.confirm:
        return l10n.voicePrimaryConfirm;
      case VoiceStep.saving:
        return l10n.voicePrimarySaving;
      case VoiceStep.success:
        return l10n.voicePrimaryNew;
      default:
        return l10n.voicePrimaryContinue;
    }
  }

  String _titleForIntent(String intent, AppLocalizations l10n) {
    switch (intent) {
      case "income":
        return l10n.voiceTitleIncome;
      case "transfer":
        return l10n.voiceTitleTransfer;
      default:
        return l10n.voiceTitleExpense;
    }
  }

  Locale _resolveSessionLocale({
    required Locale deviceLocale,
    Locale? userLocale,
  }) {
    final base = userLocale ?? deviceLocale;
    final language = base.languageCode.toLowerCase();
    final country = base.countryCode;
    switch (language) {
      case "es":
        return Locale("es", country?.isNotEmpty == true ? country : "419");
      case "en":
        return Locale("en", country?.isNotEmpty == true ? country : "US");
      case "pt":
        return Locale("pt", country?.isNotEmpty == true ? country : "BR");
      default:
        return const Locale("pt", "BR");
    }
  }

  Future<void> _showAccountPicker(
    List<Account> accounts,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final query = controller.text.toLowerCase();
            final filtered = accounts.where((account) {
              return account.name.toLowerCase().contains(query);
            }).toList();
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: l10n.voiceSearchAccount,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final account = filtered[index];
                        return ListTile(
                          title: Text(account.name),
                          onTap: () {
                            Navigator.of(context).pop();
                            _controller.setAccount(account);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _showCategoryPicker(
    List<Category> categories,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final query = controller.text.toLowerCase();
            final filtered = categories.where((category) {
              return category.name.toLowerCase().contains(query);
            }).toList();
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: l10n.voiceSearchCategory,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final category = filtered[index];
                        return ListTile(
                          title: Text(category.name),
                          onTap: () {
                            Navigator.of(context).pop();
                            _controller.setCategory(category);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }
}

class MicPulse extends StatefulWidget {
  final bool active;

  const MicPulse({super.key, required this.active});

  @override
  State<MicPulse> createState() => _MicPulseState();
}

class _MicPulseState extends State<MicPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant MicPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.active ? AppColors.primarySoft : AppColors.surface2,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic,
          color: widget.active ? AppColors.primary : AppColors.textSecondary,
          size: 18,
        ),
      ),
    );
  }
}

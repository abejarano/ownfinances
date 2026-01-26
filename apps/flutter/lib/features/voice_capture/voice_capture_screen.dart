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
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/voice_capture/voice_capture_controller.dart";
import "package:ownfinances/features/voice_capture/voice_services/stt_service.dart";
import "package:ownfinances/features/voice_capture/voice_services/tts_service.dart";

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
                    _buildHeader(context),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPrompt(theme, step),
                            const SizedBox(height: AppSpacing.md),
                            _buildListeningRow(theme),
                            const SizedBox(height: AppSpacing.sm),
                            _buildTranscript(theme),
                            if (_controller.lastError != null &&
                                _controller.lastError != "Cancelar")
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
                              amount: amount,
                              account: account,
                              category: category,
                              date: date,
                              currency: currency,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildStepContent(
                              theme,
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _titleForIntent(_controller.intent),
              style: theme.textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () => _controller.setManualMode(true),
            child: const Text("Digitar"),
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

  Widget _buildListeningRow(ThemeData theme) {
    final status = _controller.isListening
        ? "Estou ouvindo..."
        : _controller.manualMode
        ? "Modo manual"
        : "Aguardando...";
    return Row(
      children: [
        MicPulse(active: _controller.isListening),
        const SizedBox(width: AppSpacing.sm),
        Text(status, style: theme.textTheme.bodyMedium),
        const Spacer(),
        if (!_controller.micPermissionGranted)
          TextButton(
            onPressed: _controller.requestMicPermission,
            child: const Text("Permitir microfone"),
          ),
      ],
    );
  }

  Widget _buildTranscript(ThemeData theme) {
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
            ? "Transcricao aparecera aqui"
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
    ThemeData theme, {
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
            amount == null ? "Valor" : _formatAmount(amount, currency),
          ),
          selected: _controller.step == VoiceStep.askingAmount,
          onSelected: (_) {
            _controller.setManualMode(true);
            _controller.jumpToStep(VoiceStep.askingAmount);
          },
        ),
        InputChip(
          label: Text(account?.name ?? "Conta"),
          selected: _controller.step == VoiceStep.askingAccount,
          onSelected: (_) {
            _controller.setManualMode(true);
            _controller.jumpToStep(VoiceStep.askingAccount);
          },
        ),
        InputChip(
          label: Text(_formatDateLabel(date)),
          selected: _controller.step == VoiceStep.askingDate,
          onSelected: (_) {
            _controller.setManualMode(true);
            _controller.jumpToStep(VoiceStep.askingDate);
          },
        ),
        InputChip(
          label: Text(category?.name ?? "Categoria"),
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
    ThemeData theme, {
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
        return _buildAmountInput(theme, currency);
      case VoiceStep.askingAccount:
        return _buildAccountSelector(theme, accounts);
      case VoiceStep.askingDate:
        return _buildDateSelector(theme, date);
      case VoiceStep.askingCategory:
        return _buildCategorySelector(theme, categories);
      case VoiceStep.confirm:
        return _buildConfirmation(theme, account, category, amount, date);
      case VoiceStep.saving:
        return _buildSaving(theme);
      case VoiceStep.success:
        return _buildSuccess(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAmountInput(ThemeData theme, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Digite o valor", style: theme.textTheme.bodyMedium),
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
          onSubmitted: (_) => _handleAmountSubmit(),
        ),
      ],
    );
  }

  Widget _buildAccountSelector(ThemeData theme, List<Account> accounts) {
    final options = _controller.accountMatches.isNotEmpty
        ? _controller.accountMatches
        : accounts;
    final visible = options.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Escolha a conta", style: theme.textTheme.bodyMedium),
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
              onPressed: () => _showAccountPicker(accounts),
              child: const Text("Ver todas"),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSelector(ThemeData theme, DateTime? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quando foi?", style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text("Hoje"),
              selected: _isToday(date),
              onSelected: (_) => _controller.setDate(DateTime.now()),
            ),
            ChoiceChip(
              label: const Text("Ontem"),
              selected: _isYesterday(date),
              onSelected: (_) => _controller.setDate(
                DateTime.now().subtract(const Duration(days: 1)),
              ),
            ),
            ChoiceChip(
              label: const Text("Outro dia"),
              selected: date != null && !_isToday(date) && !_isYesterday(date),
              onSelected: (_) => _pickDate(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector(ThemeData theme, List<Category> categories) {
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
        Text("Escolha a categoria", style: theme.textTheme.bodyMedium),
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
              child: const Text("Sem categoria (Outros)"),
            ),
          ),
        if (options.length > visible.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _showCategoryPicker(options),
              child: const Text("Ver todas"),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Confirmacao", style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _summaryText(account, category, amount, date),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () {
            _controller.setManualMode(true);
            _controller.jumpToStep(VoiceStep.askingAmount);
          },
          icon: const Icon(Icons.edit),
          label: const Text("Editar"),
        ),
      ],
    );
  }

  Widget _buildSaving(ThemeData theme) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text("Salvando...", style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.success),
        const SizedBox(width: AppSpacing.sm),
        Text("Registrado", style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildFooter({
    required VoiceStep step,
    required Account? account,
    required Category? category,
    required double? amount,
    required DateTime? date,
  }) {
    final primaryLabel = _primaryLabel(step);
    final secondaryLabel = step == VoiceStep.success ? "Fechar" : "Cancelar";
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
  }) {
    switch (step) {
      case VoiceStep.askingAmount:
        _handleAmountSubmit();
        return;
      case VoiceStep.askingAccount:
        if (_controller.draft.fromAccountId == null) {
          showStandardSnackbar(context, "Falta escolher conta de saida");
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
          showStandardSnackbar(context, "Falta escolher categoria");
          return;
        }
        _controller.continueFlow();
        return;
      case VoiceStep.confirm:
        _saveTransaction(account, category, amount, date);
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
      showStandardSnackbar(context, "O valor deve ser maior que 0");
      return;
    }
    if (account == null) {
      showStandardSnackbar(context, "Falta escolher conta de saida");
      return;
    }
    final categoryToUse = category ?? fallbackCategory;
    if (categoryToUse == null) {
      showStandardSnackbar(context, "Falta escolher categoria");
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
      showStandardSnackbar(context, "Erro ao salvar");
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

  void _handleAmountSubmit() {
    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      showStandardSnackbar(context, "Digite um valor valido");
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

  String _formatDateLabel(DateTime? date) {
    if (date == null) return "Data";
    if (_isToday(date)) return "Hoje";
    if (_isYesterday(date)) return "Ontem";
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
  ) {
    final safeAmount =
        amount == null ? "--" : _formatAmount(amount, account?.currency ?? "BRL");
    final safeCategory = category?.name ?? "Sem categoria";
    final safeAccount = account?.name ?? "Conta";
    final safeDate = _formatDateLabel(date);
    return "Vou registrar: $safeAmount em $safeCategory, da conta $safeAccount, $safeDate.";
  }

  String _primaryLabel(VoiceStep step) {
    switch (step) {
      case VoiceStep.confirm:
        return "Confirmar";
      case VoiceStep.saving:
        return "Salvando";
      case VoiceStep.success:
        return "Registrar outro";
      default:
        return "Continuar";
    }
  }

  String _titleForIntent(String intent) {
    switch (intent) {
      case "income":
        return "Registrar receita";
      case "transfer":
        return "Registrar transferencia";
      default:
        return "Registrar despesa";
    }
  }

  Future<void> _showAccountPicker(List<Account> accounts) async {
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
                    decoration: const InputDecoration(
                      hintText: "Buscar conta",
                      prefixIcon: Icon(Icons.search),
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

  Future<void> _showCategoryPicker(List<Category> categories) async {
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
                    decoration: const InputDecoration(
                      hintText: "Buscar categoria",
                      prefixIcon: Icon(Icons.search),
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

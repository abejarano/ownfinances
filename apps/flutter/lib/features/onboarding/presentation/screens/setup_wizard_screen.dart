import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/routing/onboarding_controller.dart";
import "package:ownfinances/features/accounts/domain/repositories/account_repository.dart";
import "package:ownfinances/features/categories/domain/repositories/category_repository.dart";
import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/budgets/domain/repositories/budget_repository.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _accountNameController = TextEditingController(
    text: "Banco",
  );
  int _step = 0;
  bool _useExamples = false;
  bool _createBudget = true;
  bool _isSaving = false;
  String _accountType = "bank";
  bool _checkingExisting = true;

  @override
  void initState() {
    super.initState();
    _checkExistingData();
  }

  Future<void> _checkExistingData() async {
    final controller = context.read<OnboardingController>();
    final hasData = await controller.checkExistingData();
    if (hasData) {
      if (mounted) context.go("/dashboard");
    } else {
      if (mounted) setState(() => _checkingExisting = false);
    }
  }

  late final List<_CategorySeed> _baseCategories = [
    _CategorySeed(
      name: "Salario",
      kind: "income",
      color: "#22C55E",
      icon: "salary",
      planned: 5000,
    ),
    _CategorySeed(
      name: "Alimentacao",
      kind: "expense",
      color: "#F97316",
      icon: "restaurant",
      planned: 800,
    ),
  ];

  late final List<_CategorySeed> _exampleCategories = [
    _CategorySeed(
      name: "Moradia",
      kind: "expense",
      color: "#2563EB",
      icon: "home",
      planned: 1500,
    ),
    _CategorySeed(
      name: "Transporte",
      kind: "expense",
      color: "#0EA5E9",
      icon: "transport",
      planned: 400,
    ),
    _CategorySeed(
      name: "Lazer",
      kind: "expense",
      color: "#DB2777",
      icon: "leisure",
      planned: 300,
    ),
    _CategorySeed(
      name: "Saude",
      kind: "expense",
      color: "#16A34A",
      icon: "health",
      planned: 250,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingExisting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final categories = _selectedCategories();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comecar rapido"),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _skip),
        actions: [TextButton(onPressed: _skip, child: const Text("Pular"))],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _WelcomeStep(
            useExamples: _useExamples,
            onToggleExamples: (value) {
              setState(() {
                _useExamples = value;
                _createBudget = value;
              });
            },
          ),
          _AccountStep(
            controller: _accountNameController,
            accountType: _accountType,
            onTypeChanged: (value) => setState(() => _accountType = value),
          ),
          _CategoriesStep(
            categories: categories,
            useExamples: _useExamples,
            createBudget: _createBudget,
            onToggleCategory: (seed) {
              setState(() => seed.selected = !seed.selected);
            },
            onToggleBudget: (value) {
              setState(() => _createBudget = value);
            },
          ),
          _FinishStep(useExamples: _useExamples),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: SecondaryButton(label: "Voltar", onPressed: _prevStep),
              ),
            if (_step > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: PrimaryButton(
                label: _step == 3 ? "Finalizar" : "Proximo",
                onPressed: _isSaving ? null : _nextStep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_CategorySeed> _selectedCategories() {
    return _useExamples
        ? [..._baseCategories, ..._exampleCategories]
        : _baseCategories;
  }

  void _nextStep() {
    if (_step == 1) {
      if (_accountNameController.text.trim().isEmpty) {
        showStandardSnackbar(context, "Falta o nome da conta");
        return;
      }
    }
    if (_step < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      setState(() => _step += 1);
    } else {
      _finish();
    }
  }

  void _prevStep() {
    if (_step == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    setState(() => _step -= 1);
  }

  Future<void> _skip() async {
    await context.read<OnboardingController>().complete();
    if (context.mounted) {
      context.go("/dashboard");
    }
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    final accountRepo = context.read<AccountRepository>();
    final categoryRepo = context.read<CategoryRepository>();
    final budgetRepo = context.read<BudgetRepository>();
    final accountsState = context.read<AccountsController>().state;
    final categoriesState = context.read<CategoriesController>().state;

    try {
      final accountName = _accountNameController.text.trim();
      if (accountsState.items.isEmpty) {
        await accountRepo.create(
          name: accountName,
          type: _accountType,
          currency: "BRL",
          isActive: true,
        );
      }

      final existingByName = {
        for (final item in categoriesState.items) item.name.toLowerCase(): item,
      };
      final createdCategories = <String, String>{};
      for (final seed in _selectedCategories()) {
        if (!seed.selected) continue;
        final existing = existingByName[seed.name.toLowerCase()];
        if (existing != null) {
          createdCategories[seed.name] = existing.id;
          continue;
        }
        final created = await categoryRepo.create(
          name: seed.name,
          kind: seed.kind,
          color: seed.color,
          icon: seed.icon,
          isActive: true,
        );
        createdCategories[seed.name] = created.id;
      }

      if (_useExamples && _createBudget) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        final existingBudget = await budgetRepo.current(
          period: "monthly",
          date: now,
        );
        if (existingBudget.budget == null) {
          final lines = <BudgetLine>[];
          for (final seed in _selectedCategories()) {
            if (!seed.selected) continue;
            if (seed.planned == null) continue;
            final categoryId = createdCategories[seed.name];
            if (categoryId == null) continue;
            lines.add(
              BudgetLine(categoryId: categoryId, plannedAmount: seed.planned!),
            );
          }
          if (lines.isNotEmpty) {
            await budgetRepo.save(
              period: "monthly",
              startDate: start,
              endDate: end,
              lines: lines,
            );
          }
        }
      }

      await context.read<AccountsController>().load();
      await context.read<CategoriesController>().load();
      await context.read<OnboardingController>().complete();
      if (context.mounted) {
        context.go("/dashboard");
      }
    } catch (error) {
      if (mounted) {
        showStandardSnackbar(context, "Erro ao configurar. Tente novamente.");
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _WelcomeStep extends StatelessWidget {
  final bool useExamples;
  final ValueChanged<bool> onToggleExamples;

  const _WelcomeStep({
    required this.useExamples,
    required this.onToggleExamples,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bem-vindo!", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          const Text("Vamos deixar tudo pronto em menos de 60 segundos."),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Quero usar exemplos"),
            subtitle: const Text(
              "Criamos categorias e um orcamento base para voce editar depois.",
            ),
            value: useExamples,
            onChanged: onToggleExamples,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text("Voce pode pular e ajustar depois."),
        ],
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  final TextEditingController controller;
  final String accountType;
  final ValueChanged<String> onTypeChanged;

  const _AccountStep({
    required this.controller,
    required this.accountType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Conta principal",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text("Criaremos uma conta para voce registrar gastos."),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Nome da conta"),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: accountType,
            decoration: const InputDecoration(labelText: "Tipo"),
            items: const [
              DropdownMenuItem(value: "bank", child: Text("Banco")),
              DropdownMenuItem(value: "cash", child: Text("Dinheiro")),
              DropdownMenuItem(value: "wallet", child: Text("Carteira")),
            ],
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _CategoriesStep extends StatelessWidget {
  final List<_CategorySeed> categories;
  final bool useExamples;
  final bool createBudget;
  final ValueChanged<_CategorySeed> onToggleCategory;
  final ValueChanged<bool> onToggleBudget;

  const _CategoriesStep({
    required this.categories,
    required this.useExamples,
    required this.createBudget,
    required this.onToggleCategory,
    required this.onToggleBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Categorias base",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text("Escolha o que quer criar agora."),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = categories[index];
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text(item.kind == "income" ? "Receita" : "Gasto"),
                  value: item.selected,
                  onChanged: (_) => onToggleCategory(item),
                );
              },
            ),
          ),
          if (useExamples)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Criar orcamento base"),
              subtitle: const Text("Voce podera editar depois."),
              value: createBudget,
              onChanged: onToggleBudget,
            ),
        ],
      ),
    );
  }
}

class _FinishStep extends StatelessWidget {
  final bool useExamples;

  const _FinishStep({required this.useExamples});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tudo pronto",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text("Voce ja pode registrar seu primeiro gasto."),
          const SizedBox(height: AppSpacing.lg),
          Text(
            useExamples
                ? "Criamos exemplos basicos para voce ajustar depois."
                : "Criamos o minimo para voce comecar.",
          ),
        ],
      ),
    );
  }
}

class _CategorySeed {
  final String name;
  final String kind;
  final String? color;
  final String? icon;
  final double? planned;
  bool selected;

  _CategorySeed({
    required this.name,
    required this.kind,
    this.color,
    this.icon,
    this.planned,
    this.selected = true,
  });
}

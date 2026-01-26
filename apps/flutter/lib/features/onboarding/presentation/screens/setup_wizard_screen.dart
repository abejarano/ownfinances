import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/routing/onboarding_controller.dart";
import 'package:ownfinances/core/utils/currency_utils.dart';
import 'package:ownfinances/features/accounts/domain/entities/account.dart';
import "package:ownfinances/features/accounts/data/repositories/account_repository.dart";
import "package:ownfinances/features/categories/data/repositories/category_repository.dart";
import "package:ownfinances/features/transactions/data/repositories/transaction_repository.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import 'package:ownfinances/l10n/app_localizations.dart';
import 'package:ownfinances/features/settings/application/controllers/settings_controller.dart';
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/features/banks/application/controllers/banks_controller.dart";
import "package:ownfinances/features/banks/domain/entities/bank.dart";
import "package:ownfinances/features/countries/application/controllers/countries_controller.dart";
import "package:ownfinances/features/countries/domain/entities/country.dart";
import "package:ownfinances/features/accounts/presentation/widgets/account_form.dart";

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _initialBalanceController =
      TextEditingController();
  final TextEditingController _customCurrencyController =
      TextEditingController();

  int _step = 0;
  bool _isSaving = false;
  bool _checkingExisting = true;
  String? _selectedLanguage;
  String? _selectedCurrency; // "OTHER" or standard code
  String? _selectedCountry;
  String? _selectedBankId;

  // Step 2: Account
  String _accountType = "bank";

  // Step 3: Categories
  List<_CategorySeed> _categorySeeds = [];

  @override
  void initState() {
    super.initState();
    _checkExistingData();
    context.read<CountriesController>().load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsController>();
      if (mounted) {
        setState(() {
          _selectedLanguage = settings.locale?.languageCode ?? "pt";
          // Check if current setting is in our standard list or custom
          final current = settings.primaryCurrency;
          if (CurrencyUtils.commonCurrencies.contains(current)) {
            _selectedCurrency = current;
          } else {
            // It's a custom one (or empty/default)
            _selectedCurrency = "OTHER";
            _customCurrencyController.text = current;
          }
          _selectedCountry =
              settings.countryCode ?? _getCountryCode(current);
          if (_selectedCountry != null && settings.countryCode == null) {
            settings.setCountryCode(_selectedCountry!);
          }
        });
      }
    });
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

  @override
  void dispose() {
    _pageController.dispose();
    _accountNameController.dispose();
    _initialBalanceController.dispose();
    _customCurrencyController.dispose();
    super.dispose();
  }

  String _getEffectiveCurrency() {
    if (_selectedCurrency == "OTHER") {
      return _customCurrencyController.text.trim().toUpperCase();
    }
    return _selectedCurrency ?? "BRL";
  }

  double? _parseMoney(String text) {
    // MoneyInput saves formatted text (e.g. "R$ 1.200,50")
    // We strip non-digits and divide by 100
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return double.parse(digits) / 100;
  }

  String? _getCountryCode(String currency) {
    switch (currency) {
      case "BRL":
        return "BR";
      case "VES":
        return "VE";
      case "COP":
        return "CO";
      case "ARS":
        return "AR";
      default:
        return null;
    }
  }

  Future<void> _fetchBanks() async {
    final country = _selectedCountry;
    await context.read<BanksController>().load(country: country);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingExisting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    _updateCategorySeeds(l10n);

    // Watch countries/banks to rebuild when they load
    final countriesController = context.watch<CountriesController>();
    final banksController = context.watch<BanksController>();

    final totalSteps = 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              )
            : null,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                "${_step + 1}/$totalSteps",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _PreferencesStep(
            selectedLanguage: _selectedLanguage,
            selectedCurrency: _selectedCurrency,
            selectedCountry: _selectedCountry,
            countries: countriesController.countries,
            isLoadingCountries: countriesController.isLoading,
            customCurrencyController: _customCurrencyController,
            onLanguageChanged: (val) {
              setState(() => _selectedLanguage = val);
              if (val != null) {
                context.read<SettingsController>().setLocale(Locale(val));
              }
            },
            onCurrencyChanged: (val) {
              setState(() => _selectedCurrency = val);
              final settings = context.read<SettingsController>();
              if (val == "OTHER") {
                // Do not save "OTHER" to settings, wait for text input
                // But if text input already has value, save it
                final custom = _customCurrencyController.text
                    .trim()
                    .toUpperCase();
                if (custom.length >= 3) {
                  settings.setPrimaryCurrency(custom);
                }
              } else if (val != null) {
                settings.setPrimaryCurrency(val);
                _customCurrencyController.clear();
              }
            },
            onCountryChanged: (val) {
              setState(() => _selectedCountry = val);
              if (val != null) {
                context.read<SettingsController>().setCountryCode(val);
              }
            },
            onCustomCurrencyChanged: (val) {
              // Auto-save custom currency as user types (or debounced)
              if (_selectedCurrency == "OTHER" && val.length >= 3) {
                context.read<SettingsController>().setPrimaryCurrency(
                  val.toUpperCase(),
                );
              }
            },
          ),
          _AccountStep(
            nameController: _accountNameController,
            balanceController: _initialBalanceController,
            accountType: _accountType,
            currency: _getEffectiveCurrency(),
            onTypeChanged: (val) => setState(() => _accountType = val),
            banks: banksController.banks,
            selectedBankId: _selectedBankId,
            isLoadingBanks: banksController.isLoading,
            onBankChanged: (val) {
              setState(() {
                _selectedBankId = val;
                // meaningful Auto-fill name logic if name is empty
                if (_accountNameController.text.isEmpty && val != null) {
                  final bank = banksController.banks.firstWhere(
                    (b) => b.id == val,
                  );
                  _accountNameController.text = bank.name;
                }
              });
            },
          ),
          _CategoriesStep(
            categories: _categorySeeds,
            onToggle: (index) {
              setState(() {
                _categorySeeds[index].selected =
                    !_categorySeeds[index].selected;
              });
            },
            onSelectAll: () => setState(() {
              for (var s in _categorySeeds) s.selected = true;
            }),
            onDeselectAll: () => setState(() {
              for (var s in _categorySeeds) s.selected = false;
            }),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: PrimaryButton(
          label: _step == 2 ? l10n.commonFinish : l10n.commonNext,
          onPressed: _canProceed() ? (_isSaving ? null : _nextStep) : null,
        ),
      ),
    );
  }

  void _updateCategorySeeds(AppLocalizations l10n) {
    final selectionMap = {for (var s in _categorySeeds) s.id: s.selected};

    final rawList = [
      _CategorySeed(
        id: 'housing',
        name: l10n.catHousing,
        icon: 'home',
        kind: 'expense',
        color: '#DB2777', // Pink
      ),
      _CategorySeed(
        id: 'utilities',
        name: l10n.catUtilities,
        icon: 'bolt',
        kind: 'expense',
        color: '#F59E0B', // Amber
      ),
      _CategorySeed(
        id: 'internet',
        name: l10n.catInternet,
        icon: 'wifi',
        kind: 'expense',
        color: '#3B82F6', // Blue
      ),
      _CategorySeed(
        id: 'groceries',
        name: l10n.catGroceries,
        icon: 'shopping_cart',
        kind: 'expense',
        color: '#EA580C', // Orange
      ),
      _CategorySeed(
        id: 'restaurants',
        name: l10n.catRestaurants,
        icon: 'restaurant',
        kind: 'expense',
        color: '#EF4444', // Red
      ),
      _CategorySeed(
        id: 'transport',
        name: l10n.catTransport, // Updated to "Transporte y Combustible"
        icon: 'directions_car',
        kind: 'expense',
        color: '#64748B', // Slate
      ),
      // fuel removed (merged into transport)
      _CategorySeed(
        id: 'car_maint',
        name: l10n.catCarMaintenance,
        icon: 'build',
        kind: 'expense',
        color: '#475569', // Slate Dark
      ),
      _CategorySeed(
        id: 'health',
        name: l10n.catHealth, // Updated to "Salud y Farmacia"
        icon: 'favorite',
        kind: 'expense',
        color: '#06B6D4', // Cyan
      ),
      // pharmacy removed (merged into health)
      _CategorySeed(
        id: 'education',
        name: l10n.catEducation,
        icon: 'school',
        kind: 'expense',
        color: '#7C3AED', // Violet
      ),
      // credit_card removed
      _CategorySeed(
        id: 'debts',
        name: l10n.catDebts, // Updated to "Préstamos"
        icon: 'attach_money',
        kind: 'expense',
        color: '#E11D48', // Rose
      ),
      // fees removed
      _CategorySeed(
        id: 'subscriptions',
        name: l10n.catSubscriptions,
        icon: 'subscriptions',
        kind: 'expense',
        color: '#8B5CF6', // Purple
      ),
      _CategorySeed(
        id: 'personal',
        name: l10n.catPersonal,
        icon: 'face',
        kind: 'expense',
        color: '#EC4899', // Pink
      ),
      _CategorySeed(
        id: 'clothing',
        name: l10n.catClothing,
        icon: 'checkroom',
        kind: 'expense',
        color: '#14B8A6', // Teal
      ),
      _CategorySeed(
        id: 'work',
        name: l10n.catWork,
        icon: 'work',
        kind: 'expense',
        color: '#374151', // Gray
      ),
      _CategorySeed(
        id: 'taxes',
        name: l10n.catTaxes,
        icon: 'account_balance',
        kind: 'expense',
        color: '#94A3B8', // Gray Light
      ),
    ];

    for (var item in rawList) {
      if (selectionMap.containsKey(item.id)) {
        item.selected = selectionMap[item.id]!;
      }
    }
    _categorySeeds = rawList;
  }

  bool _canProceed() {
    if (_isSaving) return false;
    if (_step == 0) {
      // Logic for Step 1
      if (_selectedLanguage == null) return false;
      if (_selectedCountry == null) return false;
      if (_selectedCurrency == "OTHER") {
        // Validate custom input
        final custom = _customCurrencyController.text.trim();
        return custom.length >= 3 && custom.length <= 5;
      }
      return _selectedCurrency != null;
    }
    return true;
  }

  void _nextStep() {
    final l10n = AppLocalizations.of(context)!;

    // Extra validation if needed
    if (_step == 0) {
      if (!_canProceed()) return;
      _fetchBanks();
    }

    if (_step == 1) {
      if (_accountNameController.text.trim().isEmpty) {
        showStandardSnackbar(context, l10n.onboardingErrorNoAccount);
        return;
      }
    }

    if (_step < 2) {
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

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    final accountRepo = context.read<AccountRepository>();
    final transactionRepo = context.read<TransactionRepository>();
    final categoryRepo = context.read<CategoryRepository>();
    final l10n = AppLocalizations.of(context)!;

    try {
      final accountName = _accountNameController.text.trim();
      final initBalanceStr = _initialBalanceController.text;
      final initBalance = _parseMoney(initBalanceStr);
      final currency = _getEffectiveCurrency();

      // 1. Check or Create Account (Idempotent)
      final accounts = await accountRepo.list();
      final existingAccount = accounts.results.cast<Account?>().firstWhere(
        (a) => a?.name == accountName,
        orElse: () => null,
      );

      late final Account createdAccount;
      if (existingAccount != null) {
        createdAccount = existingAccount;
      } else {
        createdAccount = await accountRepo.create(
          name: accountName,
          type: _accountType,
          currency: currency,
          isActive: true,
          bankType: _accountType == 'bank' ? _selectedBankId : null,
        );
      }

      // 2. Create Initial Transaction (if applicable)
      if (initBalance != null && initBalance > 0) {
        // Check if balance transaction already exists to avoid duplicates on retry?
        // For simplicity, we create it. If we wanted to be super strict we could check.
        // But likely the user wants the balance.
        await transactionRepo.create({
          "note": l10n.debtsInitialBalance,
          "amount": initBalance,
          "date": DateTime.now().toIso8601String(),
          "toAccountId": createdAccount.id,
          "type": "income",
          "status": "cleared",
          "currency": currency,
        });
      }

      // 3. Create Categories
      await Future.wait(
        _categorySeeds
            .where((s) => s.selected)
            .map(
              (s) => categoryRepo.create(
                name: s.name,
                kind: s.kind,
                icon: s.icon,
                color: s.color,
                isActive: true,
              ),
            ),
      );

      // 4. Finalize
      await context.read<AccountsController>().load();
      await context.read<CategoriesController>().load();

      // ONLY set complete if everything above succeeded
      await context.read<OnboardingController>().complete();

      if (mounted) {
        context.go("/dashboard");
      }
    } catch (e) {
      if (mounted) showStandardSnackbar(context, "Error: $e");
      // Do NOT proceed to dashboard or set complete
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _CategorySeed {
  final String id;
  String name;
  final String kind;
  final String? icon;
  final String color;
  bool selected;

  _CategorySeed({
    required this.id,
    required this.name,
    required this.kind,
    this.icon,
    required this.color,
    this.selected = true,
  });
}

class _PreferencesStep extends StatelessWidget {
  final String? selectedLanguage;
  final String? selectedCurrency;
  final String? selectedCountry;
  final List<Country> countries;
  final bool isLoadingCountries;
  final TextEditingController customCurrencyController;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String> onCustomCurrencyChanged;

  const _PreferencesStep({
    required this.selectedLanguage,
    required this.selectedCurrency,
    required this.selectedCountry,
    required this.countries,
    required this.isLoadingCountries,
    required this.customCurrencyController,
    required this.onLanguageChanged,
    required this.onCurrencyChanged,
    required this.onCountryChanged,
    required this.onCustomCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingPreferencesTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.onboardingPreferencesDesc,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          DropdownButtonFormField<String>(
            value: selectedLanguage,
            decoration: InputDecoration(
              labelText: l10n.onboardingFieldLanguage,
            ),
            items: const [
              DropdownMenuItem(value: "pt", child: Text("Português")),
              DropdownMenuItem(value: "es", child: Text("Español")),
              DropdownMenuItem(value: "en", child: Text("English")),
            ],
            onChanged: onLanguageChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: selectedCountry,
            decoration: InputDecoration(
              labelText: l10n.onboardingFieldCountry,
            ),
            items: [
              ...countries.map(
                (c) => DropdownMenuItem(
                  value: c.code,
                  child: Text(c.name),
                ),
              ),
            ],
            onChanged: isLoadingCountries ? null : onCountryChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          CurrencyPickerField(
            label: l10n.onboardingFieldCurrency,
            value: selectedCurrency,
            onSelected: onCurrencyChanged,
          ),
          if (selectedCurrency == "OTHER") ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: customCurrencyController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 5,
              onChanged: onCustomCurrencyChanged,
              decoration: InputDecoration(
                labelText: l10n.currencyCustomLabel,
                hintText: l10n.currencyCustomHint,
                helperText: l10n.currencyInvalid,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController balanceController;
  final String accountType;
  final String currency;
  final ValueChanged<String> onTypeChanged;
  final List<Bank> banks;
  final String? selectedBankId;
  final ValueChanged<String?> onBankChanged;
  final bool isLoadingBanks;

  const _AccountStep({
    required this.nameController,
    required this.balanceController,
    required this.accountType,
    required this.currency,
    required this.onTypeChanged,
    required this.banks,
    required this.selectedBankId,
    required this.onBankChanged,
    required this.isLoadingBanks,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingCreateAccountTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.onboardingCreateAccountDesc,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          AccountForm(
            nameController: nameController,
            accountType: accountType,
            onTypeChanged: onTypeChanged,
            bankType: selectedBankId,
            onBankTypeChanged: onBankChanged,
            currency: currency,
            showCurrencySelector: false,
            showActiveSwitch: false,
            initialBalanceController: balanceController,
          ),
        ],
      ),
    );
  }
}

class _CategoriesStep extends StatelessWidget {
  final List<_CategorySeed> categories;
  final ValueChanged<int> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  const _CategoriesStep({
    required this.categories,
    required this.onToggle,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.onboardingCategoriesTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.onboardingCategoriesDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  TextButton(
                    onPressed: onSelectAll,
                    child: Text(l10n.onboardingActionSelectAll),
                  ),
                  TextButton(
                    onPressed: onDeselectAll,
                    child: Text(l10n.onboardingActionDeselectAll),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final item = categories[index];
              return CheckboxListTile(
                title: Text(item.name),
                secondary: Icon(
                  _getIconData(item.icon),
                  color: item.selected ? AppColors.primary : Colors.grey,
                ),
                value: item.selected,
                onChanged: (_) => onToggle(index),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String? name) {
    switch (name) {
      case 'home':
        return Icons.home;
      case 'bolt':
        return Icons.bolt;
      case 'wifi':
        return Icons.wifi;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'build':
        return Icons.build;
      case 'favorite':
        return Icons.favorite;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'school':
        return Icons.school;
      case 'credit_card':
        return Icons.credit_card;
      case 'attach_money':
        return Icons.attach_money;
      case 'percent':
        return Icons.percent;
      case 'subscriptions':
        return Icons.subscriptions;
      case 'face':
        return Icons.face;
      case 'checkroom':
        return Icons.checkroom;
      case 'work':
        return Icons.work;
      case 'account_balance':
        return Icons.account_balance;
      default:
        return Icons.category;
    }
  }
}

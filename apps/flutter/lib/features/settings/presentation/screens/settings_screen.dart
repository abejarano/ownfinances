import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/auth/application/controllers/session_controller.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/settings/application/controllers/settings_controller.dart";
import "package:ownfinances/core/utils/currency_utils.dart";
import "package:ownfinances/features/countries/application/controllers/countries_controller.dart";
import "package:ownfinances/features/countries/domain/entities/country.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoGenerateRecurring = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    context.read<CountriesController>().load();
  }

  Future<void> _loadSettings() async {
    try {
      final apiClient = context.read<ApiClient>();
      final result = await apiClient.get('/settings');
      setState(() {
        _autoGenerateRecurring =
            result['autoGenerateRecurring'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAutoGenerate(bool value) async {
    setState(() {
      _autoGenerateRecurring = value;
    });

    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.put('/settings', {'autoGenerateRecurring': value});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.successSettingsUpdate),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _autoGenerateRecurring = !value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorSettingsUpdate(e.toString()),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // 0. Gerenciar Shortcut (Moved Management here)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.grid_view,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.settingsManageShortcutTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.settingsManageShortcutDesc,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      return OutlinedButton(
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.settingsManageShortcutButton,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 1. Preferências Section
        _buildSectionTitle(
          context,
          AppLocalizations.of(context)!.settingsPreferences,
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              Consumer<SettingsController>(
                builder: (context, settings, child) {
                  return ListTile(
                    leading: const Icon(
                      Icons.monetization_on_outlined,
                      color: AppColors.textTertiary,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.settingsMainCurrency,
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.settingsMainCurrencyDesc,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 140),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSoft),
                          ),
                          child: Text(
                            _shortCurrencyLabel(settings.primaryCurrency),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                    onTap: () => _showCurrencyPicker(context, settings),
                  );
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              Consumer2<SettingsController, CountriesController>(
                builder: (context, settings, countriesController, child) {
                  final selectedCountry = _resolveCountry(
                    countriesController.countries,
                    settings.countryCode,
                  );
                  return ListTile(
                    leading: const Icon(
                      Icons.flag_outlined,
                      color: AppColors.textTertiary,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.settingsCountry,
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.settingsCountryDesc,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedCountry?.name ??
                              AppLocalizations.of(
                                context,
                              )!.settingsCountryPlaceholder,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                    onTap: () => _showCountryPicker(
                      context,
                      settings,
                      countriesController,
                    ),
                  );
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              Consumer<SettingsController>(
                builder: (context, settings, child) {
                  final currentLocale = settings.locale?.languageCode ?? "pt";
                  String languageLabel;
                  switch (currentLocale) {
                    case "en":
                      languageLabel = AppLocalizations.of(
                        context,
                      )!.languageEnglish;
                      break;
                    case "es":
                      languageLabel = AppLocalizations.of(
                        context,
                      )!.languageSpanish;
                      break;
                    default:
                      languageLabel = AppLocalizations.of(
                        context,
                      )!.languagePortuguese;
                  }

                  return ListTile(
                    leading: const Icon(
                      Icons.language_outlined,
                      color: AppColors.textTertiary,
                    ),
                    title: Text(AppLocalizations.of(context)!.settingsLanguage),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          languageLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                    onTap: () => _showLanguagePicker(context, settings),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Automação Section (Updated Copy)
        _buildSectionTitle(
          context,
          AppLocalizations.of(context)!.settingsAutomation,
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          // Uses standard SURFACE-1 from theme
          child: Column(
            children: [
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.settingsAutoGenerate),
                subtitle: Text(
                  AppLocalizations.of(context)!.settingsAutoGenerateDesc,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                value: _autoGenerateRecurring,
                onChanged: _isLoading ? null : _updateAutoGenerate,
                activeColor: Colors.white,
                activeTrackColor: AppColors.success,
                tileColor: Colors.transparent, // Uses card background
              ),
              if (_autoGenerateRecurring)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.settingsAutoGenerateInfo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 3. Conta Section
        _buildSectionTitle(
          context,
          AppLocalizations.of(context)!.settingsAccountSection,
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: Text(
                  AppLocalizations.of(context)!.drawerLogout,
                  style: const TextStyle(color: AppColors.danger),
                ),
                onTap: () async {
                  await context.read<SessionController>().logout();
                  if (context.mounted) {
                    context.go("/login");
                  }
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppColors.textTertiary,
                ),
                title: Text(AppLocalizations.of(context)!.settingsVersion),
                trailing: Text(
                  AppLocalizations.of(context)!.settingsVersionValue("1.0.0"),
                  style: const TextStyle(color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _showCurrencyPicker(
    BuildContext context,
    SettingsController controller,
  ) async {
    final current = controller.primaryCurrency;
    final pickerOptions = ["BRL", "COP", "VES", "USD", "EUR", "GBP", "USDT"];

    // Check if current is custom (not in options)
    final isCustom = !pickerOptions.contains(current);
    final customController = TextEditingController(
      text: isCustom ? current : "",
    );
    String? selected = isCustom ? "OTHER" : current;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.settingsMainCurrency),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...pickerOptions.map(
                      (opt) => RadioListTile<String>(
                        title: Text(CurrencyUtils.formatCurrencyLabel(opt)),
                        value: opt,
                        groupValue: selected,
                        onChanged: (val) {
                          setState(() => selected = val);
                        },
                        activeColor: AppColors.primary,
                      ),
                    ),
                    RadioListTile<String>(
                      title: Text(AppLocalizations.of(context)!.currencyOther),
                      value: "OTHER",
                      groupValue: selected,
                      onChanged: (val) {
                        setState(() => selected = val);
                      },
                      activeColor: AppColors.primary,
                    ),
                    if (selected == "OTHER")
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: customController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.currencyCustomLabel,
                            hintText: AppLocalizations.of(
                              context,
                            )!.currencyCustomHint,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}), // Refresh for val
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.commonCancel),
                ),
                TextButton(
                  onPressed: () {
                    String finalVal = selected!;
                    if (selected == "OTHER") {
                      finalVal = customController.text.trim().toUpperCase();
                      // Validation: 3-5 chars, A-Z only
                      if (!RegExp(r'^[A-Z]{3,5}$').hasMatch(finalVal)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.currencyInvalid,
                            ),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                    }
                    controller.setPrimaryCurrency(finalVal);
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.commonSave),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsController settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.settingsLanguage,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                context,
                settings,
                "pt",
                AppLocalizations.of(context)!.languagePortuguese,
              ),
              _buildLanguageOption(
                context,
                settings,
                "en",
                AppLocalizations.of(context)!.languageEnglish,
              ),
              _buildLanguageOption(
                context,
                settings,
                "es",
                AppLocalizations.of(context)!.languageSpanish,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    SettingsController settings,
    String code,
    String label,
  ) {
    final isSelected = (settings.locale?.languageCode ?? "pt") == code;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        settings.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  Country? _resolveCountry(List<Country> countries, String? code) {
    if (code == null) return null;
    for (final country in countries) {
      if (country.code == code) return country;
    }
    return null;
  }

  String _shortCurrencyLabel(String code) {
    switch (code) {
      case "BRL":
        return "R\$ · BRL";
      case "USD":
        return "\$ · USD";
      case "EUR":
        return "€ · EUR";
      case "GBP":
        return "£ · GBP";
      case "COP":
        return "COP";
      case "ARS":
        return "ARS";
      case "PYG":
        return "PYG";
      case "UYU":
        return "UYU";
      case "VES":
        return "VES";
      case "USDT":
        return "USDT";
      default:
        return code;
    }
  }

  void _showCountryPicker(
    BuildContext context,
    SettingsController settings,
    CountriesController countriesController,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.settingsCountry,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (countriesController.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )
              else
                ...countriesController.countries.map((country) {
                  final isSelected = settings.countryCode == country.code;
                  return ListTile(
                    title: Text(
                      country.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      settings.setCountryCode(country.code);
                      Navigator.pop(context);
                    },
                  );
                }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

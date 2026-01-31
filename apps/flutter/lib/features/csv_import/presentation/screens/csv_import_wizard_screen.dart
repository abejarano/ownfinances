import "dart:convert";
import "dart:io";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/csv_import/application/controllers/csv_import_controller.dart";
import "package:ownfinances/features/csv_import/application/csv_import_copy.dart";
import "package:ownfinances/l10n/app_localizations.dart";
import "package:provider/provider.dart";

import "../../../../core/presentation/components/fliter_chip.dart";
import "../../../../core/utils/formatters.dart";

class CsvImportWizardScreen extends StatefulWidget {
  const CsvImportWizardScreen({super.key});

  @override
  State<CsvImportWizardScreen> createState() => _CsvImportWizardScreenState();
}

class _CsvImportWizardScreenState extends State<CsvImportWizardScreen> {
  String? _fileName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountsController = context.read<AccountsController>();
      if (accountsController.state.items.isEmpty) {
        accountsController.load();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    context.read<CsvImportController>().setCopy(CsvImportCopy.fromL10n(l10n));
  }

  @override
  Widget build(BuildContext context) {
    final importController = context.watch<CsvImportController>();
    final accountsController = context.watch<AccountsController>();
    final accountsState = accountsController.state;

    // Filter only "bank" type accounts
    final bankAccounts = accountsState.items
        .where((acc) => acc.type == "bank")
        .toList();

    final accountItems = bankAccounts
        .map((acc) => PickerItem(id: acc.id, label: acc.name))
        .toList();

    final hasAccount = importController.state.selectedAccountId != null;
    final hasFile = importController.state.csvContent != null;
    final canContinue = hasAccount && hasFile;

    final l10n = AppLocalizations.of(context)!;

    final currentMonthLabel = formatMonth(
      DateTime(importController.state.year, importController.state.month, 1),
    ).toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionsActionImportCsv)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Selecione o mês, a conta bancária e o arquivo CSV para importar suas transações.",
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Account Selection
            if (accountsState.isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              CustomFilterChip(
                label: currentMonthLabel,
                icon: Icons.calendar_today,
                isActive: true, // Always show active for the main date filter
                onTap: () => pickMonth(context, (int year, int month) {
                  importController.setMonth(month);
                  importController.setYear(year);
                }),
              ),
              const SizedBox(height: 20),
              AccountPicker(
                label: "Conta",
                value: importController.state.selectedAccountId,
                items: accountItems,
                onSelected: (item) {
                  importController.selectAccount(item.id);
                },
              ),
              if (accountItems.isEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  "Nenhuma conta bancária encontrada. Crie uma conta tipo 'banco' primeiro.",
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ],

            const SizedBox(height: AppSpacing.xl),

            // File Selection
            InkWell(
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ["csv"],
                  withData: true,
                );
                if (result != null) {
                  final file = result.files.single;
                  setState(() => _fileName = file.name);

                  String content;
                  if (file.bytes != null) {
                    content = utf8.decode(file.bytes!);
                  } else if (file.path != null) {
                    content = await File(file.path!).readAsString();
                  } else {
                    return;
                  }

                  await importController.loadCsv(content);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasFile ? AppColors.primary : AppColors.muted,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: hasFile
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Column(
                  children: [
                    Icon(
                      hasFile ? Icons.check_circle : Icons.upload_file,
                      size: 48,
                      color: hasFile ? AppColors.primary : AppColors.muted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      hasFile
                          ? _fileName ?? "Arquivo selecionado"
                          : "Clique para selecionar o arquivo CSV",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: hasFile ? AppColors.primary : AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (hasFile) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        "Clique para alterar",
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Action Button
            if (importController.state.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              PrimaryButton(
                label: "Visualizar e Importar",
                onPressed: canContinue
                    ? () async {
                        await importController.import(context);
                      }
                    : null,
              ),

            if (importController.state.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                importController.state.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

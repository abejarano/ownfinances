import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import 'package:ownfinances/l10n/app_localizations.dart';

class CsvImportSuccessScreen extends StatelessWidget {
  const CsvImportSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l10n.csvImportSuccessTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Image.asset(
                  "images/sucess-send-file.png",
                  height: 240,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.csvImportSuccessMessage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.csvImportSuccessSubMessage,
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.csvImportSuccessButton,
                onPressed: () => context.go("/transactions"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

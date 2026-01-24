import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import 'package:ownfinances/l10n/app_localizations.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onStart;

  const OnboardingScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                l10n.appTagline,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.onboardingFeature1),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.onboardingFeature2),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.onboardingFeature3),
              const Spacer(),
              PrimaryButton(
                label: l10n.onboardingStartFast,
                onPressed: onStart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

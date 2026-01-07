import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onStart;

  const OnboardingScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                "Seu dinheiro claro",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text("• Registrar gasto em 3 toques"),
              const SizedBox(height: AppSpacing.sm),
              const Text("• Ver saldo real e planejado"),
              const SizedBox(height: AppSpacing.sm),
              const Text("• Tudo em um so lugar, sem jargao"),
              const Spacer(),
              PrimaryButton(label: "Comecar", onPressed: onStart),
            ],
          ),
        ),
      ),
    );
  }
}

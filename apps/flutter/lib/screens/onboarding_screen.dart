import "package:flutter/material.dart";
import "package:ownfinances/ui/components/buttons.dart";
import "package:ownfinances/ui/theme/app_theme.dart";

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onStart;

  const OnboardingScreen({
    super.key,
    required this.onStart,
  });

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
                "Tu dinero en claro",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text("• Registrar gasto en 3 taps"),
              const SizedBox(height: AppSpacing.sm),
              const Text("• Ver saldo real y planificado"),
              const SizedBox(height: AppSpacing.sm),
              const Text("• Todo en un solo lugar, sin jerga"),
              const Spacer(),
              PrimaryButton(label: "Empezar", onPressed: onStart),
            ],
          ),
        ),
      ),
    );
  }
}

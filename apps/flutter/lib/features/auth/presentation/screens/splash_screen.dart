import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/features/auth/application/state/auth_state.dart";
import "package:ownfinances/core/routing/onboarding_controller.dart";
import "package:ownfinances/features/accounts/domain/repositories/account_repository.dart";
import "package:ownfinances/features/categories/domain/repositories/category_repository.dart";

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthController>();
    if (auth.state.status != AuthStatus.authenticated) {
      if (mounted) context.go("/login");
      return;
    }

    final onboarding = context.read<OnboardingController>();
    final accountRepository = context.read<AccountRepository>();
    final categoryRepository = context.read<CategoryRepository>();
    if (!onboarding.loaded) {
      await onboarding.load();
    }
    if (!mounted) return;

    if (onboarding.completed) {
      context.go("/dashboard");
      return;
    }

    try {
      final accounts = await accountRepository.list(
        isActive: true,
      );
      final categories = await categoryRepository.list(
        isActive: true,
      );
      if (!mounted) return;

      final hasSetup =
          accounts.results.isNotEmpty || categories.results.isNotEmpty;
      if (hasSetup) {
        await onboarding.complete();
        if (!mounted) return;
        context.go("/dashboard");
        return;
      }
    } catch (_) {
      // If API fails, fall back to explicit onboarding.
    }

    if (mounted) context.go("/onboarding");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

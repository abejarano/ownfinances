import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.authRegisterTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.authRegisterQuick,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(AppLocalizations.of(context)!.authRegisterSubtitle),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authEmailLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authPasswordLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _isLoading
                    ? AppLocalizations.of(context)!.authLoadingRegister
                    : AppLocalizations.of(context)!.authButtonRegister,
                onPressed: _isLoading ? null : _onRegister,
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: AppLocalizations.of(context)!.authSwitchToLogin,
                onPressed: _isLoading ? null : () => context.go("/login"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRegister() async {
    setState(() => _isLoading = true);
    final controller = context.read<AuthController>();
    final error = await controller.register(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (error != null && mounted) {
      showStandardSnackbar(context, error);
    }
    if (error == null && mounted) {
      context.go("/splash");
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

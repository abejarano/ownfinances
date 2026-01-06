import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
    final state = ref.watch(authControllerProvider);
    final message = state.message;

    return Scaffold(
      appBar: AppBar(title: const Text("Entrar")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Acesse sua conta",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text("Email e senha. Sem complicações."),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(message),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Senha"),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _isLoading ? "Entrando..." : "Entrar",
                onPressed: _isLoading ? null : _onLogin,
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: "Criar conta",
                onPressed: _isLoading ? null : () => context.go("/register"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLogin() async {
    setState(() => _isLoading = true);
    final controller = ref.read(authControllerProvider.notifier);
    final error = await controller.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (error != null && mounted) {
      showStandardSnackbar(context, error);
    }
    if (mounted) {
      await controller.clearMessage();
      setState(() => _isLoading = false);
    }
  }
}

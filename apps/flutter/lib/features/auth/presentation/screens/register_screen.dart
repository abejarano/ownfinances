import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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
      appBar: AppBar(title: const Text("Criar conta")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Registro rápido",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text("Só email e senha. Em menos de 30s."),
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
                label: _isLoading ? "Criando..." : "Criar conta",
                onPressed: _isLoading ? null : _onRegister,
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: "Já tenho conta",
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
    final controller = ref.read(authControllerProvider);
    final error = await controller.register(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (error != null && mounted) {
      showStandardSnackbar(context, error);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

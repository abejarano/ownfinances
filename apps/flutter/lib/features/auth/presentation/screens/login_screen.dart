import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final state = context.watch<AuthController>().state;

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(title: const Text("Entrar")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Entrar", style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              const Text("Sem senha. Sem complicação."),

              const SizedBox(height: AppSpacing.lg),
              // Social Login
              PrimaryButton(
                label: "Continuar com Google",
                onPressed: _isLoading ? null : _onLoginGoogle,
                icon: Icons.g_mobiledata,
                backgroundColor: Colors.white,
                textColor: Colors.black,
              ),
              if (isIOS) ...[
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: "Continuar com Apple",
                  onPressed: _isLoading ? null : _onLoginApple,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  icon: Icons.apple,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("ou"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                label: "Entrar com e-mail",
                onPressed: _isLoading
                    ? null
                    : () {
                        // Toggle logic or navigation if needed, for now just show fields
                        // But PO said "Secondary button: Entrar com e-mail".
                        // Logic: Maybe expand the form below?
                        // For MVP, I'll keep the form visible below the "ou" but maybe hide it initially?
                        // The Request says: "Pantalla de Login... Botones principales... Separador... Botón secundario: Entrar com e-mail".
                        // It implies the email form is hidden or on a separate screen?
                        // "Alternativa: Entrar com e-mail (se mantiene, pero no es el camino principal)"
                        // Current implementation has the form visible.
                        // I will put the form below the button, perhaps in an ExpansionTile or just visible.
                        // I'll keep it simple: Social Buttons -> Divider -> Email Form (Title "Ou entre com email").
                        // Wait, the design requested "Button: Entrar com email". If clicked, maybe show form?
                        // Refactor: Hide form by default?
                        setState(() {
                          _showEmailForm = true;
                        });
                      },
              ),
              if (_showEmailForm) ...[
                const SizedBox(height: AppSpacing.md),
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
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: _isLoading ? "Entrando..." : "Entrar",
                  onPressed: _isLoading ? null : _onLogin,
                ),
              ],
              const Spacer(),
              const Center(
                child: Text(
                  "Usamos seu login apenas para acessar sua conta.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  bool _showEmailForm = false;

  Future<void> _onLoginGoogle() async {
    setState(() => _isLoading = true);
    final controller = context.read<AuthController>();
    final error = await controller.loginWithGoogle();
    _handleLoginResult(error);
  }

  Future<void> _onLoginApple() async {
    setState(() => _isLoading = true);
    final controller = context.read<AuthController>();
    final error = await controller.loginWithApple();
    _handleLoginResult(error);
  }

  void _handleLoginResult(String? error) {
    if (error != null && mounted) {
      showStandardSnackbar(context, error);
      setState(() => _isLoading = false);
    } else if (mounted) {
      context.go("/splash"); // Or dashboard
    }
  }

  Future<void> _onLogin() async {
    setState(() => _isLoading = true);
    final controller = context.read<AuthController>();
    final error = await controller.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    _handleLoginResult(error);
  }
}

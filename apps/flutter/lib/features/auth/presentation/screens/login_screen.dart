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
    // Colors from "Desquadra Dark Calm" spec
    const bg0 = Color(0xFF0B1220);
    const textPrimary = Color(0xFFE5E7EB);
    const textSecondary = Color.fromRGBO(229, 231, 235, 0.70);
    const dividerColor = Color.fromRGBO(255, 255, 255, 0.10);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: bg0,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 36),
                    // 1. Header
                    Image.asset(
                      "images/isotipo.png",
                      height: 104,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.account_balance_wallet,
                        size: 104,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      "Entrar",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        fontFamily:
                            "Manrope", // Assuming Manrope is loaded via GoogleFonts in AppTheme
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      height: 32,
                    ), // Subtitle -> Google CTA: 24px (used 32 for better breath)
                    // 2. Google CTA
                    _SocialButton(
                      label: "Continuar com Google",
                      onPressed: _isLoading ? null : _onLoginGoogle,
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF111827),
                      // TODO: Replace with official asset when available
                      icon: Icons.g_mobiledata_rounded,
                      isLoading: _isLoading,
                    ),

                    if (isIOS) ...[
                      const SizedBox(height: 16),
                      _SocialButton(
                        label: "Continuar com Apple",
                        onPressed: _isLoading ? null : _onLoginApple,
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                        icon: Icons.apple,
                        isLoading: _isLoading,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 3. Separator
                    Row(
                      children: [
                        Expanded(child: Divider(color: dividerColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "ou",
                            style: TextStyle(
                              color: const Color.fromRGBO(229, 231, 235, 0.60),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: dividerColor)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 4. Email CTA
                    if (!_showEmailForm)
                      _OutlineButton(
                        label: "Entrar com e-mail",
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _showEmailForm = true),
                      ),

                    if (_showEmailForm) ...[
                      // const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color.fromRGBO(255, 255, 255, 0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: textPrimary),
                              decoration: const InputDecoration(
                                labelText: "Email",
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const Divider(height: 24),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: textPrimary),
                              decoration: const InputDecoration(
                                labelText: "Senha",
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: _isLoading
                                  ? (_isRegistering
                                        ? "Criando conta..."
                                        : "Entrando...")
                                  : (_isRegistering ? "Criar conta" : "Entrar"),
                              onPressed: _isLoading ? null : _onLogin,
                              fullWidth: true,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(
                                      () => _isRegistering = !_isRegistering,
                                    ),
                              child: Text(
                                _isRegistering
                                    ? "Já tenho conta"
                                    : "Criar nova conta",
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 5. Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 16),
              child: Text(
                "Usamos seu login apenas para acessar sua conta.",
                style: TextStyle(
                  fontSize: 12,
                  color: const Color.fromRGBO(229, 231, 235, 0.50),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
      context.go("/splash");
    }
  }

  bool _isRegistering = false;

  Future<void> _onLogin() async {
    setState(() => _isLoading = true);
    final controller = context.read<AuthController>();
    final error = _isRegistering
        ? await controller.register(
            _emailController.text.trim(),
            _passwordController.text,
            _emailController.text.trim().split(
              "@",
            )[0], // Simple name derivation
          )
        : await controller.login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    _handleLoginResult(error);
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final bool isLoading;

  const _SocialButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: textColor,
                  ), // TODO: Use image asset here
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _OutlineButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE5E7EB),
          side: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

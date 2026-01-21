import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:provider/provider.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/di/providers.dart";
import "package:go_router/go_router.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("pt_BR");
  runApp(const OwnFinancesApp());
}

class WebSocketInitializer extends StatefulWidget {
  final Widget child;

  const WebSocketInitializer({super.key, required this.child});

  @override
  State<WebSocketInitializer> createState() => _WebSocketInitializerState();
}

class _WebSocketInitializerState extends State<WebSocketInitializer> {
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final wsClient = context.read<WebSocketClient>();
    //   wsClient.connect().catchError((error) {
    //     print("Error connecting WebSocket: $error");
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class OwnFinancesApp extends StatelessWidget {
  const OwnFinancesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: WebSocketInitializer(
        child: Builder(
          builder: (context) {
            final router = context.watch<GoRouter>();
            return MaterialApp.router(
              title: "Desquadra",
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkCalm(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale("pt", "BR")],
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}

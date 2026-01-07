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

class OwnFinancesApp extends StatelessWidget {
  const OwnFinancesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: Builder(
        builder: (context) {
          final router = context.watch<GoRouter>();
          return MaterialApp.router(
            title: "OwnFinances",
            theme: AppTheme.light(),
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
    );
  }
}

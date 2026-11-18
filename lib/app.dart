import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:aquawatt/state/occurrences_controller.dart';
import 'package:aquawatt/state/territory_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class AquaWattApp extends StatelessWidget {
  const AquaWattApp({
    super.key,
    required this.appState,
    required this.occurrences,
    required this.territory,
  });

  final AppState appState;
  final OccurrencesController occurrences;
  final TerritoryController territory;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<OccurrencesController>.value(value: occurrences),
        ChangeNotifierProvider<TerritoryController>.value(value: territory),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final highContrast = app.themeChoice == AppThemeChoice.highContrast;
    return MaterialApp(
      title: 'AquaWatt',
      debugShowCheckedModeBanner: false,
      theme: highContrast ? AppTheme.highContrast() : AppTheme.light(),
      darkTheme: highContrast ? AppTheme.highContrast() : AppTheme.dark(),
      themeMode: app.themeChoice.themeMode,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Tamanho de fonte: combina o ajuste do sistema com o ajuste do app.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scale = (media.textScaler.scale(1.0) * app.textScale).clamp(0.8, 2.2).toDouble();
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
      initialRoute: app.consentGiven ? AppRoutes.home : AppRoutes.consent,
      onGenerateRoute: AppRoutes.onGenerate,
    );
  }
}

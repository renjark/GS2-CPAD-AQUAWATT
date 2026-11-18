import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/ui/screens/alert_detail_screen.dart';
import 'package:aquawatt/ui/screens/consent_screen.dart';
import 'package:aquawatt/ui/screens/home_shell.dart';
import 'package:aquawatt/ui/screens/indicator_detail_screen.dart';
import 'package:aquawatt/ui/screens/occurrence_form_screen.dart';
import 'package:aquawatt/ui/screens/occurrences_screen.dart';
import 'package:aquawatt/ui/screens/privacy_screen.dart';
import 'package:aquawatt/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';

class IndicatorArgs {
  const IndicatorArgs({required this.metric, required this.regionId});

  final Metric metric;
  final String regionId;
}

class AlertArgs {
  const AlertArgs(this.alertId);

  final String alertId;
}

/// Rotas nomeadas do app. Parâmetros são passados por [RouteSettings.arguments].
class AppRoutes {
  const AppRoutes._();

  static const String consent = '/consent';
  static const String home = '/home';
  static const String indicator = '/indicator';
  static const String alert = '/alert';
  static const String occurrenceNew = '/occurrence/new';
  static const String occurrences = '/occurrences';
  static const String settings = '/settings';
  static const String privacy = '/privacy';

  static Route<dynamic> onGenerate(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case consent:
        page = const ConsentScreen();
      case indicator:
        page = IndicatorDetailScreen(args: settings.arguments! as IndicatorArgs);
      case alert:
        page = AlertDetailScreen(args: settings.arguments! as AlertArgs);
      case occurrenceNew:
        page = const OccurrenceFormScreen();
      case occurrences:
        page = const OccurrencesScreen();
      case AppRoutes.settings:
        page = const SettingsScreen();
      case privacy:
        page = const PrivacyScreen();
      case home:
      default:
        page = const HomeShell();
    }
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}

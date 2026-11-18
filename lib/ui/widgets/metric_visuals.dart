import 'package:aquawatt/domain/models.dart';
import 'package:flutter/material.dart';

IconData metricIcon(Metric metric) => switch (metric) {
      Metric.water => Icons.water_drop_outlined,
      Metric.energy => Icons.bolt_outlined,
      Metric.climate => Icons.wb_sunny_outlined,
    };

/// Cor de cada indicador, com contraste adequado em tema claro e escuro.
Color metricColor(BuildContext context, Metric metric) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (metric) {
    Metric.water => dark ? const Color(0xFF6CC4F5) : const Color(0xFF0B6BA8),
    Metric.energy => dark ? const Color(0xFFFFC857) : const Color(0xFFA85A00),
    Metric.climate => dark ? const Color(0xFF5EE0C8) : const Color(0xFF0A7466),
  };
}

IconData severityIcon(Severity? severity) => switch (severity) {
      Severity.high => Icons.report_outlined,
      Severity.medium => Icons.warning_amber_outlined,
      Severity.low => Icons.info_outline,
      null => Icons.check_circle_outline,
    };

/// Cores suaves (chips e fundos). Nunca é a única pista: sempre há ícone e texto.
({Color bg, Color fg}) severityColors(ColorScheme s, Severity? severity) => switch (severity) {
      Severity.high => (bg: s.errorContainer, fg: s.onErrorContainer),
      Severity.medium => (bg: s.tertiaryContainer, fg: s.onTertiaryContainer),
      Severity.low => (bg: s.secondaryContainer, fg: s.onSecondaryContainer),
      null => (bg: s.primaryContainer, fg: s.onPrimaryContainer),
    };

/// Cores fortes (marcadores do mapa).
({Color bg, Color fg}) severityStrongColors(ColorScheme s, Severity? severity) =>
    switch (severity) {
      Severity.high => (bg: s.error, fg: s.onError),
      Severity.medium => (bg: s.tertiary, fg: s.onTertiary),
      Severity.low => (bg: s.secondary, fg: s.onSecondary),
      null => (bg: s.primary, fg: s.onPrimary),
    };

String confidenceLabel(double value) {
  if (value < 0.4) return 'baixa';
  if (value < 0.7) return 'média';
  return 'alta';
}

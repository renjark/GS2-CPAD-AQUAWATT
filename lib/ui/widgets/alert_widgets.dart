import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:aquawatt/ui/widgets/metric_visuals.dart';
import 'package:flutter/material.dart';

/// Severidade com ícone + texto (não depende só de cor).
class SeverityChip extends StatelessWidget {
  const SeverityChip({super.key, required this.severity});

  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final colors = severityColors(Theme.of(context).colorScheme, severity);
    return Semantics(
      label: 'Severidade ${severity.label.toLowerCase()}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(severityIcon(severity), size: 16, color: colors.fg),
            const SizedBox(width: 4),
            Text(
              'Severidade ${severity.label}',
              style: TextStyle(color: colors.fg, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    final label = 'Confiança $percent% (${confidenceLabel(value)})';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: value, minHeight: 8),
          ),
        ],
      ),
    );
  }
}

/// Item de lista de alertas.
class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, this.decision, required this.onTap});

  final AlertItem alert;
  final HumanDecision? decision;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final region = regionName(alert.regionId);
    final decided = decision == null ? 'sem decisão registrada' : decision!.status.label;
    return AppCard(
      onTap: onTap,
      semanticLabel: '${alert.title}. $region. Severidade ${alert.severity.label}. '
          'Confiança ${(alert.confidence * 100).round()}%. $decided. Toque para ver detalhes.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metricIcon(alert.metric), color: metricColor(context, alert.metric)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SeverityChip(severity: alert.severity),
                    Text(region, style: theme.textTheme.labelMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(alert.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Confiança ${(alert.confidence * 100).round()}% · $decided',
                  style: theme.textTheme.bodySmall,
                ),
                Text('Gerado em ${fmtDateTime(alert.createdAt)}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

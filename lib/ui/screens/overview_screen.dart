import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/state/territory_controller.dart';
import 'package:aquawatt/ui/widgets/alert_widgets.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:aquawatt/ui/widgets/metric_visuals.dart';
import 'package:aquawatt/ui/widgets/metric_widgets.dart';
import 'package:aquawatt/ui/widgets/status_widgets.dart';
import 'package:aquawatt/ui/widgets/territory_gate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Visão geral: benefício social, alertas principais e situação por bairro.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.onSeeAlerts});

  final VoidCallback onSeeAlerts;

  @override
  Widget build(BuildContext context) {
    return TerritoryGate(builder: (context, t) {
      final top = t.alerts.take(3).toList();
      return RefreshIndicator(
        onRefresh: () => t.load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
          children: [
            const DisclaimerBanner(),
            if (t.weatherFromCache && t.weatherUpdatedAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              InfoBanner(
                message: 'Modo offline: clima salvo em ${fmtDateTime(t.weatherUpdatedAt!)}. '
                    'Consumo e ocorrências continuam disponíveis.',
              ),
            ],
            if (t.weatherError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              InfoBanner(message: t.weatherError!),
            ],
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('Benefício social estimado'),
            AdaptiveWrap(children: [
              KpiTile(
                label: 'Água acima do esperado',
                value: fmtInt(t.excessWaterM3PerDay),
                unit: 'm³/dia',
                icon: Icons.water_drop_outlined,
                caption: 'Potencial de economia se a causa for investigada e corrigida.',
              ),
              KpiTile(
                label: 'População monitorada',
                value: fmtInt(t.monitoredPopulation),
                unit: 'habitantes',
                icon: Icons.groups_outlined,
                caption: '${kRegions.length} bairros (estimativa sintética).',
              ),
              KpiTile(
                label: 'Alertas revisados por pessoas',
                value: fmtPct(t.reviewedShare, signed: false),
                icon: Icons.how_to_reg_outlined,
                caption: '${t.reviewedAlerts} de ${t.alerts.length} com decisão registrada.',
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              'Alertas ativos (${t.alerts.length})',
              trailing: TextButton(onPressed: onSeeAlerts, child: const Text('Ver todos')),
            ),
            if (top.isEmpty)
              const AppCard(
                child: Text('Nenhum alerta ativo: os indicadores estão dentro dos limiares.'),
              )
            else
              for (final alert in top)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AlertTile(
                    alert: alert,
                    decision: t.decisionFor(alert.id),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.alert,
                        arguments: AlertArgs(alert.id)),
                  ),
                ),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader('Situação por bairro'),
            for (final profile in kProfiles)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _RegionCard(region: profile.region),
              ),
          ],
        ),
      );
    });
  }
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({required this.region});

  final Region region;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritoryController>();
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(region.name, style: theme.textTheme.titleMedium),
          Text('${fmtInt(region.population)} habitantes (estimativa sintética)',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          _MetricRow(region: region, metric: Metric.water, deviation: t.summaryFor(region.id, Metric.water)?.deviation),
          _MetricRow(region: region, metric: Metric.energy, deviation: t.summaryFor(region.id, Metric.energy)?.deviation),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.region, required this.metric, required this.deviation});

  final Region region;
  final Metric metric;

  /// Desvio da média de 7 dias em relação à linha de base.
  final double? deviation;

  @override
  Widget build(BuildContext context) {
    final deviation = this.deviation;
    final label = deviation == null
        ? '${metric.label} em ${region.name}: sem dados. Abrir detalhe.'
        : '${metric.label} em ${region.name}: ${fmtPct(deviation)} em relação à linha de base. Abrir detalhe.';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.indicator,
          arguments: IndicatorArgs(metric: metric, regionId: region.id),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(metricIcon(metric), color: metricColor(context, metric)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(metric.label)),
              if (deviation != null) TrendBadge(fraction: deviation) else const Text('—'),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

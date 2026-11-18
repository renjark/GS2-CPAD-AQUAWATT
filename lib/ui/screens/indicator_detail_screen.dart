import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/ui/widgets/alert_widgets.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:aquawatt/ui/widgets/metric_visuals.dart';
import 'package:aquawatt/ui/widgets/metric_widgets.dart';
import 'package:aquawatt/ui/widgets/status_widgets.dart';
import 'package:aquawatt/ui/widgets/territory_gate.dart';
import 'package:flutter/material.dart';

/// Detalhe de um indicador (métrica + bairro), recebido por parâmetros de rota.
class IndicatorDetailScreen extends StatelessWidget {
  const IndicatorDetailScreen({super.key, required this.args});

  final IndicatorArgs args;

  @override
  Widget build(BuildContext context) {
    final region = regionById(args.regionId);
    return Scaffold(
      appBar: AppBar(title: Text('${args.metric.label} — ${region.name}')),
      body: TerritoryGate(
        builder: (context, t) {
          final theme = Theme.of(context);
          final color = metricColor(context, args.metric);
          final alerts = t.alertsFor(regionId: region.id, metric: args.metric);
          final children = <Widget>[const DisclaimerBanner(), const SizedBox(height: AppSpacing.md)];

          if (args.metric == Metric.climate) {
            final outlook = t.outlookFor(region.id);
            final series = t.weatherSeries(region.id, precipitation: false);
            if (outlook == null || series == null) {
              return ErrorView(
                message: t.weatherError ?? 'Sem dados de clima para este bairro.',
                onRetry: () => t.load(silent: true),
              );
            }
            children.addAll([
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Temperatura máxima diária', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    MetricChart(
                      series: series,
                      color: color,
                      semanticLabel: 'Gráfico da temperatura máxima em ${region.name}. '
                          'Hoje: ${fmt(outlook.todayMax)} °C.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const ChartLegend(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const SectionHeader('Próximos dias'),
              AppCard(
                child: Column(
                  children: [
                    for (final day in outlook.upcoming)
                      _StatRow(
                        label: fmtDate(day.date),
                        value: '${fmt(day.tMax)} °C · ${fmt(day.precipitation)} mm',
                      ),
                  ],
                ),
              ),
            ]);
          } else {
            final summary = t.summaryFor(region.id, args.metric);
            final series = t.consumptionSeries(region.id, args.metric);
            if (summary == null || series == null) {
              return const EmptyView(message: 'Sem dados suficientes para este indicador.');
            }
            final unit = args.metric.unit;
            final sign = summary.slope >= 0 ? '+' : '';
            children.addAll([
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Últimos 30 dias e projeção de 3 dias', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    MetricChart(
                      series: series,
                      color: color,
                      height: 260,
                      decimals: args.metric == Metric.water ? 0 : 1,
                      semanticLabel: 'Gráfico do consumo de ${args.metric.label.toLowerCase()} '
                          'em ${region.name}. Média dos últimos 7 dias: '
                          '${fmt(summary.recentMean)} $unit; variação '
                          '${fmtPct(summary.deviation)} sobre a linha de base.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const ChartLegend(hasBaseline: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const SectionHeader('Números por trás do gráfico'),
              AppCard(
                child: Column(
                  children: [
                    _StatRow(label: 'Média dos últimos 7 dias', value: '${fmt(summary.recentMean)} $unit'),
                    _StatRow(
                      label: 'Linha de base (${summary.baselineDays} dias)',
                      value: '${fmt(summary.baseMean)} $unit',
                    ),
                    _StatRow(label: 'Variação sobre a base', value: fmtPct(summary.deviation, decimals: 1)),
                    _StatRow(label: 'Tendência (14 dias)', value: '$sign${fmt(summary.slope, 2)} $unit/dia'),
                    _StatRow(label: 'Ajuste linear (R²)', value: fmt(summary.r2, 2)),
                    _StatRow(label: 'Projeção em 3 dias', value: '${fmt(summary.forecast(3))} $unit'),
                    _StatRow(
                      label: 'Confiança estimada',
                      value: '${(summary.confidence * 100).round()}% (${confidenceLabel(summary.confidence)})',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Text(
                  'Como lemos este indicador: comparamos a média dos últimos 7 dias com a média '
                  'dos dias anteriores (linha de base) e ajustamos uma reta aos últimos 14 dias '
                  'para projetar os próximos 3. É um modelo simples e transparente, e não '
                  'captura sazonalidade nem eventos pontuais. Dados sintéticos de demonstração.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ]);
          }

          children
            ..add(const SizedBox(height: AppSpacing.lg))
            ..add(const SectionHeader('Alertas relacionados'));
          if (alerts.isEmpty) {
            children.add(const AppCard(child: Text('Nenhum alerta ativo para este indicador.')));
          } else {
            for (final alert in alerts) {
              children.add(Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AlertTile(
                  alert: alert,
                  decision: t.decisionFor(alert.id),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.alert,
                      arguments: AlertArgs(alert.id)),
                ),
              ));
            }
          }
          return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: children);
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

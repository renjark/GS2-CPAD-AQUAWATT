import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:aquawatt/state/territory_controller.dart';
import 'package:aquawatt/ui/widgets/alert_widgets.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:aquawatt/ui/widgets/metric_visuals.dart';
import 'package:aquawatt/ui/widgets/metric_widgets.dart';
import 'package:aquawatt/ui/widgets/region_selector.dart';
import 'package:aquawatt/ui/widgets/status_widgets.dart';
import 'package:aquawatt/ui/widgets/territory_gate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Três dashboards distintos: Água, Energia e Clima.
class DashboardsScreen extends StatelessWidget {
  const DashboardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TerritoryGate(
      builder: (context, t) => DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(tabs: [
              Tab(icon: Icon(Icons.water_drop_outlined), text: 'Água'),
              Tab(icon: Icon(Icons.bolt_outlined), text: 'Energia'),
              Tab(icon: Icon(Icons.wb_sunny_outlined), text: 'Clima'),
            ]),
            const Expanded(
              child: TabBarView(children: [
                _ConsumptionDashboard(metric: Metric.water),
                _ConsumptionDashboard(metric: Metric.energy),
                _ClimateDashboard(),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

const _listPadding = EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96);

class _ConsumptionDashboard extends StatelessWidget {
  const _ConsumptionDashboard({required this.metric});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritoryController>();
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final region = app.selectedRegion;
    final summary = t.summaryFor(region.id, metric);
    final series = t.consumptionSeries(region.id, metric);
    final color = metricColor(context, metric);
    final alerts = t.alertsFor(regionId: region.id, metric: metric);

    return RefreshIndicator(
      onRefresh: () => t.load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _listPadding,
        children: [
          const RegionSelector(),
          const SizedBox(height: AppSpacing.md),
          if (summary == null || series == null)
            const EmptyView(message: 'Sem dados suficientes para este bairro.')
          else ...[
            AdaptiveWrap(children: [
              KpiTile(
                label: 'Média dos últimos 7 dias',
                value: fmt(summary.recentMean),
                unit: metric.unit,
                trend: summary.deviation,
                icon: metricIcon(metric),
                color: color,
                onTap: () => _openDetail(context, region.id),
              ),
              KpiTile(
                label: 'Linha de base',
                value: fmt(summary.baseMean),
                unit: metric.unit,
                caption: '${summary.baselineDays} dias anteriores',
              ),
              KpiTile(
                label: 'Projeção em 3 dias',
                value: fmt(summary.forecast(3)),
                unit: metric.unit,
                caption: 'Modelo linear; veja as limitações.',
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Histórico e projeção — ${region.name}', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  MetricChart(
                    series: series,
                    color: color,
                    decimals: metric == Metric.water ? 0 : 1,
                    semanticLabel: 'Gráfico de linha do consumo de ${metric.label.toLowerCase()} '
                        'em ${region.name} nos últimos 30 dias, com projeção de 3 dias. '
                        'Média dos últimos 7 dias: ${fmt(summary.recentMean)} ${metric.unit}, '
                        'variação ${fmtPct(summary.deviation)} sobre a linha de base.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const ChartLegend(hasBaseline: true),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _openDetail(context, region.id),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Ver detalhes do indicador'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('Comparação entre bairros'),
            _RankingCard(metric: metric),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('Alertas deste indicador'),
            if (alerts.isEmpty)
              const AppCard(child: Text('Nenhum alerta ativo para este bairro e indicador.'))
            else
              for (final alert in alerts)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AlertTile(
                    alert: alert,
                    decision: t.decisionFor(alert.id),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.alert,
                        arguments: AlertArgs(alert.id)),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, String regionId) => Navigator.pushNamed(
        context,
        AppRoutes.indicator,
        arguments: IndicatorArgs(metric: metric, regionId: regionId),
      );
}

/// Ranking dos bairros pelo desvio da média de 7 dias. Tocar seleciona o bairro.
class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.metric});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritoryController>();
    final app = context.read<AppState>();
    final rows = <({Region region, double deviation})>[
      for (final p in kProfiles)
        if (t.summaryFor(p.region.id, metric) != null)
          (region: p.region, deviation: t.summaryFor(p.region.id, metric)!.deviation),
    ]..sort((a, b) => b.deviation.compareTo(a.deviation));

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (final row in rows)
            Semantics(
              button: true,
              label: '${row.region.name}: ${fmtPct(row.deviation)} sobre a linha de base. '
                  'Toque para selecionar o bairro.',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => app.selectRegion(row.region.id),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(child: Text(row.region.name)),
                        TrendBadge(fraction: row.deviation),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClimateDashboard extends StatelessWidget {
  const _ClimateDashboard();

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritoryController>();
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final region = app.selectedRegion;
    final color = metricColor(context, Metric.climate);
    final outlook = t.outlookFor(region.id);
    final temps = t.weatherSeries(region.id, precipitation: false);
    final rain = t.weatherSeries(region.id, precipitation: true);
    final alerts = t.alertsFor(regionId: kTerritoryId);

    return RefreshIndicator(
      onRefresh: () => t.load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _listPadding,
        children: [
          const RegionSelector(),
          const SizedBox(height: AppSpacing.md),
          if (outlook == null || temps == null || rain == null)
            SizedBox(
              height: 320,
              child: ErrorView(
                message: t.weatherError ?? 'Sem dados de clima para este bairro.',
                onRetry: () => t.load(silent: true),
              ),
            )
          else ...[
            if (t.weatherFromCache && t.weatherUpdatedAt != null) ...[
              InfoBanner(message: 'Modo offline: clima salvo em ${fmtDateTime(t.weatherUpdatedAt!)}.'),
              const SizedBox(height: AppSpacing.md),
            ],
            AdaptiveWrap(children: [
              KpiTile(
                label: 'Máxima hoje',
                value: fmt(outlook.todayMax),
                unit: '°C',
                icon: Icons.thermostat_outlined,
                color: color,
              ),
              KpiTile(
                label: 'Máxima em 3 dias',
                value: fmt(outlook.maxNext3),
                unit: '°C',
                caption: 'Maior valor previsto',
              ),
              KpiTile(
                label: 'Chuva em 3 dias',
                value: fmt(outlook.rainNext3),
                unit: 'mm',
                icon: Icons.umbrella_outlined,
                color: color,
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Temperatura máxima — ${region.name}', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  MetricChart(
                    series: temps,
                    color: color,
                    semanticLabel: 'Gráfico de linha da temperatura máxima diária em ${region.name}: '
                        '14 dias passados e 7 de previsão. Hoje: ${fmt(outlook.todayMax)} °C.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const ChartLegend(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chuva diária (mm) — ${region.name}', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  MetricChart(
                    series: rain,
                    color: metricColor(context, Metric.water),
                    decimals: 1,
                    semanticLabel: 'Gráfico de linha da chuva diária em ${region.name}: '
                        'acumulado previsto de ${fmt(outlook.rainNext3)} mm em 3 dias.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const ChartLegend(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('Previsão por bairro (3 dias)'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  for (final p in kProfiles) _ClimateRow(region: p.region),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('Alertas climáticos'),
            if (alerts.isEmpty)
              const AppCard(child: Text('Nenhum alerta climático: previsões abaixo dos limiares.'))
            else
              for (final alert in alerts)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AlertTile(
                    alert: alert,
                    decision: t.decisionFor(alert.id),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.alert,
                        arguments: AlertArgs(alert.id)),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _ClimateRow extends StatelessWidget {
  const _ClimateRow({required this.region});

  final Region region;

  @override
  Widget build(BuildContext context) {
    final outlook = context.watch<TerritoryController>().outlookFor(region.id);
    final text = outlook == null
        ? 'sem dados'
        : 'máx. ${fmt(outlook.maxNext3)} °C · chuva ${fmt(outlook.rainNext3)} mm';
    return Semantics(
      label: '${region.name}: $text',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: Text(region.name)),
              Flexible(child: Text(text, textAlign: TextAlign.end)),
            ],
          ),
        ),
      ),
    );
  }
}

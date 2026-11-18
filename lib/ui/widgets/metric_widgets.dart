import 'dart:math' as math;

import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Seta + variação percentual. [upIsBad] indica se subir é ruim (consumo, calor).
class TrendBadge extends StatelessWidget {
  const TrendBadge({super.key, required this.fraction, this.upIsBad = true});

  final double fraction;
  final bool upIsBad;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final flat = fraction.abs() < 0.02;
    final up = fraction > 0;
    final bad = upIsBad ? up : !up;
    final color = flat ? scheme.onSurfaceVariant : (bad ? scheme.error : scheme.primary);
    final icon = flat ? Icons.trending_flat : (up ? Icons.trending_up : Icons.trending_down);
    final text = flat ? 'Estável' : fmtPct(fraction);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Indicador numérico (KPI) com rótulo, valor, unidade, tendência e legenda.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.trend,
    this.upIsBad = true,
    this.icon,
    this.color,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final String? unit;
  final double? trend;
  final bool upIsBad;
  final IconData? icon;
  final Color? color;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitText = unit == null ? '' : ' $unit';
    final trendText = trend == null ? '' : ', variação ${fmtPct(trend!)}';
    final captionText = caption == null ? '' : '. $caption';
    return AppCard(
      onTap: onTap,
      semanticLabel: '$label: $value$unitText$trendText$captionText',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: color),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (unit != null) Text(unit!, style: theme.textTheme.bodySmall),
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.xs),
            TrendBadge(fraction: trend!, upIsBad: upIsBad),
          ],
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(caption!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Gráfico de linha com histórico (sólido), previsão (tracejado) e linha de base.
class MetricChart extends StatelessWidget {
  const MetricChart({
    super.key,
    required this.series,
    required this.color,
    required this.semanticLabel,
    this.decimals = 0,
    this.height = 220,
  });

  final ChartSeries series;
  final Color color;
  final String semanticLabel;
  final int decimals;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall;
    final values = series.values;
    final n = values.length;
    if (n < 2) return const SizedBox.shrink();

    final solidEnd = math.min(series.forecastStart, n);
    final solid = [for (var i = 0; i < solidEnd; i++) FlSpot(i.toDouble(), values[i])];
    final dashed = solidEnd < n
        ? [for (var i = math.max(solidEnd - 1, 0); i < n; i++) FlSpot(i.toDouble(), values[i])]
        : <FlSpot>[];
    final step = n > 14 ? 7 : 3;

    final data = LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: solid,
          color: color,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
        ),
        if (dashed.isNotEmpty)
          LineChartBarData(
            spots: dashed,
            color: color,
            barWidth: 3,
            dashArray: [6, 4],
            dotData: const FlDotData(show: true),
          ),
      ],
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(horizontalLines: [
        if (series.baseline != null)
          HorizontalLine(
            y: series.baseline!,
            color: scheme.onSurfaceVariant,
            strokeWidth: 1.5,
            dashArray: [2, 4],
          ),
      ]),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, meta) => Text(
              fmt(value, decimals),
              style: labelStyle,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final i = value.round();
              if (i < 0 || i >= n || (n - 1 - i) % step != 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(fmtDate(series.dates[i]), style: labelStyle, maxLines: 1, softWrap: false),
              );
            },
          ),
        ),
      ),
    );

    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(height: height, child: LineChart(data)),
    );
  }
}

/// Legenda do gráfico: observado, previsão e linha de base.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, this.hasForecast = true, this.hasBaseline = false});

  final bool hasForecast;
  final bool hasBaseline;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget item(Widget mark, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [mark, const SizedBox(width: 6), Text(text, style: style)],
        );
    Widget bar(double width) =>
        Container(width: width, height: 3, color: color);
    return ExcludeSemantics(
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          item(bar(20), 'Observado'),
          if (hasForecast)
            item(Row(children: [bar(8), const SizedBox(width: 4), bar(8)]), 'Previsão'),
          if (hasBaseline)
            item(Row(children: [bar(4), const SizedBox(width: 4), bar(4)]), 'Linha de base'),
        ],
      ),
    );
  }
}

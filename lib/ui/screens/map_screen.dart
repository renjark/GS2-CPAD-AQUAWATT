import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:aquawatt/state/territory_controller.dart';
import 'package:aquawatt/ui/widgets/alert_widgets.dart';
import 'package:aquawatt/ui/widgets/metric_visuals.dart';
import 'package:aquawatt/ui/widgets/territory_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Mapa dos bairros: cor, ícone e número indicam a maior severidade e a quantidade de alertas.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TerritoryGate(builder: (context, t) {
      final scheme = Theme.of(context).colorScheme;
      return Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(-23.575, -46.63),
                initialZoom: 10.5,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'br.fiap.aquawatt',
                ),
                MarkerLayer(markers: [
                  for (final p in kProfiles) _marker(context, t, p.region),
                ]),
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              'Toque em um bairro para ver os alertas. Sem internet, o mapa-base pode não '
              'carregar, mas os marcadores continuam disponíveis.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    });
  }

  Marker _marker(BuildContext context, TerritoryController t, Region region) {
    final scheme = Theme.of(context).colorScheme;
    final severity = t.maxSeverityFor(region.id);
    final count = t.alertsFor(regionId: region.id).length;
    final colors = severityStrongColors(scheme, severity);
    final severityText = severity == null ? 'sem alertas' : 'severidade ${severity.label.toLowerCase()}';
    return Marker(
      point: LatLng(region.lat, region.lng),
      width: 64,
      height: 64,
      child: Semantics(
        button: true,
        label: '${region.name}: $count alertas, $severityText. Toque para abrir.',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => _showRegionSheet(context, region),
          child: Container(
            decoration: BoxDecoration(
              color: colors.bg,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 3),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(severityIcon(severity), color: colors.fg, size: 22),
                Text('$count',
                    style: TextStyle(color: colors.fg, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRegionSheet(BuildContext context, Region region) {
    context.read<AppState>().selectRegion(region.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _RegionSheet(region: region),
    );
  }
}

class _RegionSheet extends StatelessWidget {
  const _RegionSheet({required this.region});

  final Region region;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritoryController>();
    final theme = Theme.of(context);
    final alerts = t.alertsFor(regionId: region.id);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          shrinkWrap: true,
          children: [
            Text(region.name, style: theme.textTheme.titleLarge),
            Text('${fmtInt(region.population)} habitantes (estimativa sintética)',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final metric in [Metric.water, Metric.energy])
                  OutlinedButton.icon(
                    icon: Icon(metricIcon(metric)),
                    label: Text(metric.label),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.indicator,
                        arguments: IndicatorArgs(metric: metric, regionId: region.id),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Alertas (${alerts.length})', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (alerts.isEmpty)
              const Text('Nenhum alerta ativo neste bairro.')
            else
              for (final alert in alerts)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AlertTile(
                    alert: alert,
                    decision: t.decisionFor(alert.id),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.alert,
                          arguments: AlertArgs(alert.id));
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:aquawatt/ui/widgets/alert_widgets.dart';
import 'package:aquawatt/ui/widgets/status_widgets.dart';
import 'package:aquawatt/ui/widgets/territory_gate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Lista de alertas com filtros (severidade local; bairro vem do estado global).
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Severity? _severity;
  bool _onlySelectedRegion = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return TerritoryGate(builder: (context, t) {
      final filtered = [
        for (final a in t.alerts)
          if ((_severity == null || a.severity == _severity) &&
              (!_onlySelectedRegion ||
                  a.regionId == app.selectedRegionId ||
                  a.regionId == kTerritoryId))
            a,
      ];
      return RefreshIndicator(
        onRefresh: () => t.load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
          children: [
            const DisclaimerBanner(),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _severity == null,
                  onSelected: (_) => setState(() => _severity = null),
                ),
                for (final s in Severity.values.reversed)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _severity == s,
                    onSelected: (_) => setState(() => _severity = s),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _onlySelectedRegion,
              onChanged: (v) => setState(() => _onlySelectedRegion = v),
              title: Text('Somente ${app.selectedRegion.name}'),
              subtitle: const Text('Inclui alertas de todo o território'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.lg),
                child: EmptyView(
                  icon: Icons.notifications_off_outlined,
                  message: 'Nenhum alerta para os filtros escolhidos.',
                ),
              )
            else
              for (final alert in filtered)
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
        ),
      );
    });
  }
}

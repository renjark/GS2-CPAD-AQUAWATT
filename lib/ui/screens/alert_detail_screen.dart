import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/core/validators.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:aquawatt/state/territory_controller.dart';
import 'package:aquawatt/ui/widgets/alert_widgets.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:aquawatt/ui/widgets/app_text_field.dart';
import 'package:aquawatt/ui/widgets/status_widgets.dart';
import 'package:aquawatt/ui/widgets/territory_gate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Detalhe do alerta: evidências, confiança, limitações e registro da decisão humana.
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.args});

  final AlertArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: TerritoryGate(builder: (context, t) {
        final alert = t.alertById(args.alertId);
        if (alert == null) {
          return const EmptyView(
            icon: Icons.search_off,
            message: 'Alerta não encontrado. Ele pode ter deixado de valer porque os dados '
                'ou os limiares mudaram.',
          );
        }
        return _AlertBody(alert: alert, territory: t);
      }),
    );
  }
}

class _AlertBody extends StatelessWidget {
  const _AlertBody({required this.alert, required this.territory});

  final AlertItem alert;
  final TerritoryController territory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.read<AppState>();
    final regionId = alert.regionId == kTerritoryId ? app.selectedRegionId : alert.regionId;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const DisclaimerBanner(emphasized: true),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SeverityChip(severity: alert.severity),
            Text(regionName(alert.regionId), style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          header: true,
          child: Text(alert.title, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(alert.summary, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        _Section(title: 'Por que este alerta? (evidências)', items: alert.evidence),
        const SizedBox(height: AppSpacing.md),
        const SectionHeader('Nível de confiança'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConfidenceBar(value: alert.confidence),
              const SizedBox(height: AppSpacing.sm),
              Text(alert.confidenceNote, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Section(title: 'Limitações e quando não confiar', items: alert.limitations),
        const SizedBox(height: AppSpacing.md),
        const SectionHeader('Ação sugerida (a decidir por uma pessoa)'),
        AppCard(child: Text(alert.suggestedAction)),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.indicator,
            arguments: IndicatorArgs(metric: alert.metric, regionId: regionId),
          ),
          icon: const Icon(Icons.insights_outlined),
          label: const Text('Ver o indicador'),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader('Decisão humana'),
        _DecisionPanel(alertId: alert.id, territory: territory),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6, right: AppSpacing.sm),
                        child: Icon(Icons.circle, size: 6),
                      ),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Registro da decisão de um gestor. Só grava o parecer; nenhuma ação automática é executada.
class _DecisionPanel extends StatefulWidget {
  const _DecisionPanel({required this.alertId, required this.territory});

  final String alertId;
  final TerritoryController territory;

  @override
  State<_DecisionPanel> createState() => _DecisionPanelState();
}

class _DecisionPanelState extends State<_DecisionPanel> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _decide(DecisionStatus status) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    await widget.territory.decide(widget.alertId, status, _noteController.text);
    if (!mounted) return;
    setState(() => _editing = false);
    messenger.showSnackBar(SnackBar(content: Text('Decisão registrada: ${status.label}.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decision = widget.territory.decisionFor(widget.alertId);

    if (decision != null && !_editing) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_reg_outlined),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(decision.status.label, style: theme.textTheme.titleSmall)),
              ],
            ),
            Text('Registrada em ${fmtDateTime(decision.decidedAt)}', style: theme.textTheme.bodySmall),
            if (decision.note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Nota: ${decision.note}'),
            ],
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () {
                _noteController.text = decision.note;
                setState(() => _editing = true);
              },
              child: const Text('Alterar decisão'),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('O app apenas registra o seu parecer. Nenhuma ação é executada '
                'automaticamente.'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Nota (opcional)',
              controller: _noteController,
              maxLines: 3,
              maxLength: 200,
              validator: Validators.optionalNote,
              helper: 'Não inclua dados pessoais.',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: () => _decide(DecisionStatus.confirmed),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar para análise'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _decide(DecisionStatus.dismissed),
                  icon: const Icon(Icons.close),
                  label: const Text('Dispensar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

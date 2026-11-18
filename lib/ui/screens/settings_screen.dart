import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/core/validators.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:aquawatt/state/occurrences_controller.dart';
import 'package:aquawatt/state/territory_controller.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:aquawatt/ui/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Aparência, tamanho do texto, limiares de alerta (formulário) e dados locais.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _water;
  late final TextEditingController _energy;
  late final TextEditingController _heat;
  late final TextEditingController _rain;

  @override
  void initState() {
    super.initState();
    final t = context.read<AppState>().thresholds;
    _water = TextEditingController(text: _text(t.waterPct));
    _energy = TextEditingController(text: _text(t.energyPct));
    _heat = TextEditingController(text: _text(t.heatC));
    _rain = TextEditingController(text: _text(t.rainMm));
  }

  @override
  void dispose() {
    _water.dispose();
    _energy.dispose();
    _heat.dispose();
    _rain.dispose();
    super.dispose();
  }

  String _text(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

  void _fill(Thresholds t) {
    _water.text = _text(t.waterPct);
    _energy.text = _text(t.energyPct);
    _heat.text = _text(t.heatC);
    _rain.text = _text(t.rainMm);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    await context.read<AppState>().setThresholds(Thresholds(
          waterPct: Validators.parseNumber(_water.text),
          energyPct: Validators.parseNumber(_energy.text),
          heatC: Validators.parseNumber(_heat.text),
          rainMm: Validators.parseNumber(_rain.text),
        ));
    messenger.showSnackBar(
      const SnackBar(content: Text('Limiares salvos. Os alertas foram recalculados.')),
    );
  }

  Future<void> _restoreDefaults() async {
    const defaults = Thresholds();
    _fill(defaults);
    await context.read<AppState>().setThresholds(defaults);
  }

  Future<void> _revoke() async {
    final app = context.read<AppState>();
    final occurrences = context.read<OccurrencesController>();
    final territory = context.read<TerritoryController>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revogar consentimento?'),
        content: const Text('Todas as ocorrências, decisões e preferências salvas neste '
            'dispositivo serão apagadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apagar e revogar'),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    await app.revokeConsent();
    occurrences.reset();
    territory.resetDecisions();
    navigator.pushNamedAndRemoveUntil(AppRoutes.consent, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Aparência', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final choice in AppThemeChoice.values)
                ChoiceChip(
                  label: Text(choice.label),
                  selected: app.themeChoice == choice,
                  onSelected: (_) => app.setTheme(choice),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Tamanho do texto: ${(app.textScale * 100).round()}%',
              style: theme.textTheme.titleSmall),
          Slider(
            value: app.textScale,
            min: 0.85,
            max: 1.6,
            divisions: 15,
            label: '${(app.textScale * 100).round()}%',
            semanticFormatterCallback: (v) => 'Tamanho do texto ${(v * 100).round()} por cento',
            onChanged: app.setTextScale,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Limiares de alerta', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Defina a partir de quando o app deve sinalizar um alerta. Os alertas são '
            'recalculados ao salvar.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Água: aumento sobre a linha de base',
                    controller: _water,
                    suffix: '%',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.numberInRange(v, min: 5, max: 50, label: 'o percentual de água'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Energia: aumento sobre a linha de base',
                    controller: _energy,
                    suffix: '%',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.numberInRange(v, min: 5, max: 50, label: 'o percentual de energia'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Calor: temperatura máxima prevista',
                    controller: _heat,
                    suffix: '°C',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.numberInRange(v, min: 28, max: 42, label: 'a temperatura'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Chuva: acumulado previsto em 3 dias',
                    controller: _rain,
                    suffix: 'mm',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.numberInRange(v, min: 10, max: 100, label: 'o volume de chuva'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Salvar limiares'),
                      ),
                      OutlinedButton(
                        onPressed: _restoreDefaults,
                        child: const Text('Restaurar padrão'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Dados e privacidade', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.privacy),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Ver política de privacidade'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _revoke,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Revogar consentimento e apagar dados'),
          ),
        ],
      ),
    );
  }
}

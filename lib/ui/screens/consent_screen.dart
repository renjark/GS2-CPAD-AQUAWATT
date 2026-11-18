import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Primeira tela: consentimento explícito antes de usar o app.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;

  Future<void> _continue() async {
    final navigator = Navigator.of(context);
    await context.read<AppState>().giveConsent();
    navigator.pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Semantics(
                  label: 'AquaWatt, painel de inteligência territorial',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.water_drop, color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AquaWatt',
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            Text('Inteligência territorial para água e energia',
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text('Antes de começar', style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: AppSpacing.sm),
                const AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bullet('Não pedimos nome, e-mail, telefone nem localização exata.'),
                      _Bullet('As ocorrências que você registrar são anônimas e ficam apenas '
                          'neste dispositivo.'),
                      _Bullet('Os dados de consumo são sintéticos (demonstração). O clima vem da '
                          'API pública Open-Meteo, consultada pelo ponto central dos bairros, '
                          'não pela sua posição.'),
                      _Bullet('Os alertas apoiam, mas não substituem, a decisão humana.'),
                      _Bullet('Você pode revogar o consentimento e apagar os dados locais a '
                          'qualquer momento em Configurações.'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  value: _accepted,
                  onChanged: (v) => setState(() => _accepted = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Li e concordo com o uso dos dados descrito acima.'),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: _accepted ? _continue : null,
                  child: const Text('Continuar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.privacy),
                  child: const Text('Ler a política de privacidade completa'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

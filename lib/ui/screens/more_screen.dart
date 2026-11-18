import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/state/occurrences_controller.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Atalhos: ocorrências, configurações, privacidade e sobre o app.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<OccurrencesController>().count;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AquaWatt', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(kTerritoryTitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Antecipa desperdício de água e energia e eventos climáticos para apoiar '
                'gestores públicos e cidadãos. Projeto acadêmico FIAP, Global Solution 2026.2.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Tile(
          icon: Icons.add_comment_outlined,
          title: 'Registrar ocorrência',
          subtitle: 'Relato anônimo de vazamento, falta de água ou energia',
          route: AppRoutes.occurrenceNew,
        ),
        _Tile(
          icon: Icons.list_alt_outlined,
          title: 'Minhas ocorrências',
          subtitle: '$count registradas neste dispositivo',
          route: AppRoutes.occurrences,
        ),
        const _Tile(
          icon: Icons.tune,
          title: 'Configurações e limiares',
          subtitle: 'Tema, tamanho do texto e limiares de alerta',
          route: AppRoutes.settings,
        ),
        const _Tile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacidade e acessibilidade',
          subtitle: 'Como protegemos seus dados',
          route: AppRoutes.privacy,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => Navigator.pushNamed(context, route),
        semanticLabel: '$title. $subtitle.',
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

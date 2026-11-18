import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/state/occurrences_controller.dart';
import 'package:aquawatt/ui/widgets/app_card.dart';
import 'package:aquawatt/ui/widgets/status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Ocorrências salvas localmente (funciona sem conexão).
class OccurrencesScreen extends StatelessWidget {
  const OccurrencesScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Occurrence occurrence) async {
    final controller = context.read<OccurrencesController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir ocorrência?'),
        content: const Text('O relato será apagado deste dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok ?? false) await controller.remove(occurrence.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<OccurrencesController>().items;
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas ocorrências')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.occurrenceNew),
        icon: const Icon(Icons.add),
        label: const Text('Nova ocorrência'),
      ),
      body: items.isEmpty
          ? EmptyView(
              icon: Icons.inbox_outlined,
              message: 'Você ainda não registrou nenhuma ocorrência.',
              action: FilledButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.occurrenceNew),
                child: const Text('Registrar a primeira'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final o = items[index];
                return AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.category.label, style: Theme.of(context).textTheme.titleSmall),
                            Text('${regionName(o.regionId)} · ${fmtDateTime(o.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text(o.description),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Excluir ocorrência de ${o.category.label}',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, o),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

import 'package:aquawatt/core/theme/app_theme.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Seletor de bairro ligado ao estado global (compartilhado entre telas).
class RegionSelector extends StatelessWidget {
  const RegionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final region in kRegions)
          ChoiceChip(
            label: Text(region.name),
            selected: region.id == app.selectedRegionId,
            onSelected: (_) => app.selectRegion(region.id),
          ),
      ],
    );
  }
}

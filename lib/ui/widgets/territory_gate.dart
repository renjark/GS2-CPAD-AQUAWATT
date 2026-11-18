import 'package:aquawatt/state/territory_controller.dart';
import 'package:aquawatt/ui/widgets/status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Trata carregamento e erro do estado global antes de mostrar o conteúdo.
class TerritoryGate extends StatelessWidget {
  const TerritoryGate({super.key, required this.builder});

  final Widget Function(BuildContext context, TerritoryController territory) builder;

  @override
  Widget build(BuildContext context) {
    final territory = context.watch<TerritoryController>();
    return switch (territory.status) {
      LoadStatus.idle || LoadStatus.loading => const LoadingView(),
      LoadStatus.error => ErrorView(
          message: territory.errorMessage ?? 'Erro inesperado.',
          onRetry: () => territory.load(),
        ),
      LoadStatus.ready => builder(context, territory),
    };
  }
}

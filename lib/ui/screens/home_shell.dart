import 'package:aquawatt/core/routes.dart';
import 'package:aquawatt/state/territory_controller.dart';
import 'package:aquawatt/ui/screens/alerts_screen.dart';
import 'package:aquawatt/ui/screens/dashboards_screen.dart';
import 'package:aquawatt/ui/screens/map_screen.dart';
import 'package:aquawatt/ui/screens/more_screen.dart';
import 'package:aquawatt/ui/screens/overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Casca com navegação inferior entre as 5 seções principais.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _titles = ['Visão geral', 'Painéis', 'Alertas', 'Mapa', 'Mais'];
  static const _mapIndex = 3;
  static const _moreIndex = 4;

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TerritoryController>().load(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          OverviewScreen(onSeeAlerts: () => setState(() => _index = 2)),
          const DashboardsScreen(),
          const AlertsScreen(),
          const MapScreen(),
          const MoreScreen(),
        ],
      ),
      floatingActionButton: (_index == _mapIndex || _index == _moreIndex)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.occurrenceNew),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Registrar ocorrência'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Visão geral',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Painéis',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}

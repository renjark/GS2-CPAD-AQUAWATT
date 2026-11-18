import 'package:aquawatt/app.dart';
import 'package:aquawatt/data/prefs_repository.dart';
import 'package:aquawatt/data/synthetic_data_service.dart';
import 'package:aquawatt/data/weather_service.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:aquawatt/state/occurrences_controller.dart';
import 'package:aquawatt/state/territory_controller.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await PrefsRepository.open();
  final appState = AppState(prefs);
  final occurrences = OccurrencesController(prefs);
  final territory = TerritoryController(
    prefs: prefs,
    app: appState,
    occurrences: occurrences,
    dataService: const SyntheticDataService(),
    weatherService: WeatherService(),
  );

  // Dados do território não são pessoais: podem carregar enquanto o usuário vê o consentimento.
  territory.load();

  runApp(AquaWattApp(appState: appState, occurrences: occurrences, territory: territory));
}

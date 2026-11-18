import 'dart:math' as math;

import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/data/prefs_repository.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/data/synthetic_data_service.dart';
import 'package:aquawatt/data/weather_service.dart';
import 'package:aquawatt/domain/alert_engine.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:aquawatt/state/app_state.dart';
import 'package:aquawatt/state/occurrences_controller.dart';
import 'package:flutter/foundation.dart';

enum LoadStatus { idle, loading, ready, error }

/// Estado global dos dados do território: consumo, clima, alertas e decisões humanas.
class TerritoryController extends ChangeNotifier {
  TerritoryController({
    required PrefsRepository prefs,
    required AppState app,
    required OccurrencesController occurrences,
    required SyntheticDataService dataService,
    required WeatherService weatherService,
  })  : _prefs = prefs,
        _app = app,
        _occurrences = occurrences,
        _data = dataService,
        _weatherService = weatherService,
        _decisions = {for (final d in prefs.loadDecisions()) d.alertId: d} {
    _app.addListener(_onInputsChanged);
    _occurrences.addListener(_onInputsChanged);
    _signature = _computeSignature();
  }

  final PrefsRepository _prefs;
  final AppState _app;
  final OccurrencesController _occurrences;
  final SyntheticDataService _data;
  final WeatherService _weatherService;

  static const AlertEngine _engine = AlertEngine();

  LoadStatus status = LoadStatus.idle;
  String? errorMessage;

  Map<String, List<DailyReading>> _readings = {};
  Map<String, List<WeatherDay>> _weather = {};
  Map<String, HumanDecision> _decisions;
  List<AlertItem> alerts = [];
  String _signature = '';

  DateTime? weatherUpdatedAt;
  bool weatherFromCache = false;
  String? weatherError;

  Map<String, HumanDecision> get decisions => Map.unmodifiable(_decisions);

  // ---------------------------------------------------------------- carga

  Future<void> load({bool silent = false}) async {
    if (!silent || status != LoadStatus.ready) {
      status = LoadStatus.loading;
      errorMessage = null;
      notifyListeners();
    }
    try {
      _readings = await _data.fetchReadings();
    } catch (_) {
      status = LoadStatus.error;
      errorMessage = 'Não foi possível carregar os dados do território.';
      notifyListeners();
      return;
    }
    await _loadWeather();
    _rebuildAlerts();
    status = LoadStatus.ready;
    notifyListeners();
  }

  /// Clima real (Open-Meteo); sem conexão, usa o último cache salvo.
  Future<void> _loadWeather() async {
    final cached = _prefs.loadWeatherCache();
    try {
      final entries = await Future.wait([
        for (final region in kRegions)
          _weatherService.fetch(region).then((days) => MapEntry(region.id, days)),
      ]);
      _weather = Map.fromEntries(entries);
      weatherUpdatedAt = DateTime.now();
      weatherFromCache = false;
      weatherError = null;
      await _prefs.saveWeatherCache(_weather, weatherUpdatedAt!);
    } catch (_) {
      if (cached != null) {
        _weather = cached.data;
        weatherUpdatedAt = cached.updatedAt;
        weatherFromCache = true;
        weatherError = null;
      } else {
        _weather = {};
        weatherUpdatedAt = null;
        weatherFromCache = false;
        weatherError = 'Sem conexão e sem dados de clima salvos. Conecte-se para ver o clima.';
      }
    }
  }

  // --------------------------------------------------------------- alertas

  void _rebuildAlerts() {
    alerts = _engine.generate(
      regions: kRegions,
      readings: _readings,
      weather: _weather,
      thresholds: _app.thresholds,
      occurrences: _occurrences.items,
      now: DateTime.now(),
      weatherUpdatedAt: weatherFromCache ? weatherUpdatedAt : null,
    );
  }

  String _computeSignature() => '${_app.thresholds.hashCode}|${_occurrences.count}';

  void _onInputsChanged() {
    if (status != LoadStatus.ready) return;
    final next = _computeSignature();
    if (next == _signature) return;
    _signature = next;
    _rebuildAlerts();
    notifyListeners();
  }

  List<AlertItem> alertsFor({String? regionId, Metric? metric}) => [
        for (final a in alerts)
          if ((regionId == null || a.regionId == regionId) && (metric == null || a.metric == metric))
            a,
      ];

  AlertItem? alertById(String id) {
    for (final a in alerts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Severity? maxSeverityFor(String regionId) {
    Severity? max;
    for (final a in alerts) {
      if (a.regionId == regionId && (max == null || a.severity.index > max.index)) {
        max = a.severity;
      }
    }
    return max;
  }

  // ------------------------------------------------------ decisão humana

  HumanDecision? decisionFor(String alertId) => _decisions[alertId];

  Future<void> decide(String alertId, DecisionStatus status, String note) async {
    _decisions = {
      ..._decisions,
      alertId: HumanDecision(
        alertId: alertId,
        status: status,
        note: note.trim(),
        decidedAt: DateTime.now(),
      ),
    };
    notifyListeners();
    await _prefs.saveDecisions(_decisions.values.toList());
  }

  /// Limpa a memória após o apagamento dos dados locais.
  void resetDecisions() {
    _decisions = {};
    notifyListeners();
  }

  // ------------------------------------------------------------ consultas

  List<DailyReading> readingsFor(String regionId) => _readings[regionId] ?? const [];

  ConsumptionSummary? summaryFor(String regionId, Metric metric) {
    final data = readingsFor(regionId);
    if (data.isEmpty) return null;
    return ConsumptionSummary.from(
      [for (final r in data) metric == Metric.water ? r.water : r.energy],
    );
  }

  /// Histórico de 30 dias + projeção linear de 3 dias.
  ChartSeries? consumptionSeries(String regionId, Metric metric) {
    final data = readingsFor(regionId);
    final summary = summaryFor(regionId, metric);
    if (data.isEmpty || summary == null) return null;
    final last = data.last.date;
    final history = [for (final r in data) metric == Metric.water ? r.water : r.energy];
    return ChartSeries(
      dates: [
        for (final r in data) r.date,
        for (var k = 1; k <= 3; k++) DateTime(last.year, last.month, last.day + k),
      ],
      values: [...history, for (var k = 1; k <= 3; k++) summary.forecast(k)],
      forecastStart: history.length,
      baseline: summary.baseMean,
    );
  }

  List<WeatherDay> weatherFor(String regionId) => _weather[regionId] ?? const [];

  ChartSeries? weatherSeries(String regionId, {required bool precipitation}) {
    final days = weatherFor(regionId);
    if (days.isEmpty) return null;
    final today = dateOnly(DateTime.now());
    final firstForecast = days.indexWhere((d) => !d.date.isBefore(today));
    return ChartSeries(
      dates: [for (final d in days) d.date],
      values: [for (final d in days) precipitation ? d.precipitation : d.tMax],
      forecastStart: firstForecast < 0 ? days.length : firstForecast,
    );
  }

  WeatherOutlook? outlookFor(String regionId) {
    final days = weatherFor(regionId);
    final today = dateOnly(DateTime.now());
    final upcoming = days.where((d) => !d.date.isBefore(today)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (upcoming.isEmpty) return null;
    final next = upcoming.take(3).toList();
    return WeatherOutlook(
      todayMax: upcoming.first.tMax,
      maxNext3: next.map((d) => d.tMax).reduce(math.max),
      rainNext3: next.fold<double>(0, (sum, d) => sum + d.precipitation),
      upcoming: upcoming,
    );
  }

  // ------------------------------------------------ indicadores de impacto

  /// Água consumida acima da linha de base, somada nos bairros (m³/dia).
  double get excessWaterM3PerDay {
    var total = 0.0;
    for (final p in kProfiles) {
      final s = summaryFor(p.region.id, Metric.water);
      if (s != null && s.deviation > 0) {
        total += (s.recentMean - s.baseMean) * p.region.population / 1000;
      }
    }
    return total;
  }

  int get monitoredPopulation => kRegions.fold<int>(0, (sum, r) => sum + r.population);

  int get reviewedAlerts => alerts.where((a) => _decisions.containsKey(a.id)).length;

  double get reviewedShare => alerts.isEmpty ? 0 : reviewedAlerts / alerts.length;

  @override
  void dispose() {
    _app.removeListener(_onInputsChanged);
    _occurrences.removeListener(_onInputsChanged);
    super.dispose();
  }
}

import 'package:flutter/foundation.dart' show immutable;

/// Identificador do "território inteiro" (alertas que não são de um bairro só).
const String kTerritoryId = 'territorio';
const String kTerritoryName = 'Todo o território';

enum Metric { water, energy, climate }

extension MetricX on Metric {
  String get label => switch (this) {
        Metric.water => 'Água',
        Metric.energy => 'Energia',
        Metric.climate => 'Clima',
      };

  String get unit => switch (this) {
        Metric.water => 'L/hab/dia',
        Metric.energy => 'kWh/hab/dia',
        Metric.climate => '°C',
      };
}

enum Severity { low, medium, high }

extension SeverityX on Severity {
  String get label => switch (this) {
        Severity.low => 'Baixa',
        Severity.medium => 'Média',
        Severity.high => 'Alta',
      };
}

enum DecisionStatus { confirmed, dismissed }

extension DecisionStatusX on DecisionStatus {
  String get label => switch (this) {
        DecisionStatus.confirmed => 'Confirmado para análise',
        DecisionStatus.dismissed => 'Dispensado',
      };
}

enum OccurrenceCategory { waterLeak, waterWaste, waterShortage, powerOutage, energyWaste, other }

extension OccurrenceCategoryX on OccurrenceCategory {
  String get label => switch (this) {
        OccurrenceCategory.waterLeak => 'Vazamento de água',
        OccurrenceCategory.waterWaste => 'Desperdício de água',
        OccurrenceCategory.waterShortage => 'Falta de água',
        OccurrenceCategory.powerOutage => 'Queda de energia',
        OccurrenceCategory.energyWaste => 'Desperdício de energia',
        OccurrenceCategory.other => 'Outro',
      };
}

class Region {
  const Region({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.population,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final int population;
}

class DailyReading {
  const DailyReading({required this.date, required this.water, required this.energy});

  final DateTime date;

  /// Consumo de água em L/hab/dia.
  final double water;

  /// Consumo de energia em kWh/hab/dia.
  final double energy;
}

class WeatherDay {
  const WeatherDay({required this.date, required this.tMax, required this.precipitation});

  final DateTime date;
  final double tMax;
  final double precipitation;

  Map<String, dynamic> toJson() => {'d': date.toIso8601String(), 't': tMax, 'p': precipitation};

  factory WeatherDay.fromJson(Map<String, dynamic> json) => WeatherDay(
        date: DateTime.parse(json['d'] as String),
        tMax: (json['t'] as num).toDouble(),
        precipitation: (json['p'] as num).toDouble(),
      );
}

class WeatherOutlook {
  const WeatherOutlook({
    required this.todayMax,
    required this.maxNext3,
    required this.rainNext3,
    required this.upcoming,
  });

  final double todayMax;
  final double maxNext3;
  final double rainNext3;
  final List<WeatherDay> upcoming;
}

/// Limiares configuráveis pelo gestor.
@immutable
class Thresholds {
  const Thresholds({this.waterPct = 10, this.energyPct = 10, this.heatC = 33, this.rainMm = 30});

  /// Desvio (%) acima da linha de base que dispara alerta de água.
  final double waterPct;
  final double energyPct;
  final double heatC;
  final double rainMm;

  double get waterFraction => waterPct / 100;
  double get energyFraction => energyPct / 100;

  Thresholds copyWith({double? waterPct, double? energyPct, double? heatC, double? rainMm}) =>
      Thresholds(
        waterPct: waterPct ?? this.waterPct,
        energyPct: energyPct ?? this.energyPct,
        heatC: heatC ?? this.heatC,
        rainMm: rainMm ?? this.rainMm,
      );

  Map<String, dynamic> toJson() => {'w': waterPct, 'e': energyPct, 'h': heatC, 'r': rainMm};

  factory Thresholds.fromJson(Map<String, dynamic> json) => Thresholds(
        waterPct: (json['w'] as num).toDouble(),
        energyPct: (json['e'] as num).toDouble(),
        heatC: (json['h'] as num).toDouble(),
        rainMm: (json['r'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is Thresholds &&
      other.waterPct == waterPct &&
      other.energyPct == energyPct &&
      other.heatC == heatC &&
      other.rainMm == rainMm;

  @override
  int get hashCode => Object.hash(waterPct, energyPct, heatC, rainMm);
}

class AlertItem {
  const AlertItem({
    required this.id,
    required this.regionId,
    required this.metric,
    required this.severity,
    required this.title,
    required this.summary,
    required this.evidence,
    required this.confidence,
    required this.confidenceNote,
    required this.limitations,
    required this.suggestedAction,
    required this.createdAt,
  });

  final String id;
  final String regionId;
  final Metric metric;
  final Severity severity;
  final String title;
  final String summary;

  /// Evidências numéricas que justificam o alerta.
  final List<String> evidence;

  /// Confiança entre 0 e 1 (heurística documentada, não probabilidade calibrada).
  final double confidence;
  final String confidenceNote;
  final List<String> limitations;
  final String suggestedAction;
  final DateTime createdAt;
}

class HumanDecision {
  const HumanDecision({
    required this.alertId,
    required this.status,
    required this.note,
    required this.decidedAt,
  });

  final String alertId;
  final DecisionStatus status;
  final String note;
  final DateTime decidedAt;

  Map<String, dynamic> toJson() => {
        'a': alertId,
        's': status.name,
        'n': note,
        't': decidedAt.toIso8601String(),
      };

  factory HumanDecision.fromJson(Map<String, dynamic> json) => HumanDecision(
        alertId: json['a'] as String,
        status: DecisionStatus.values.byName(json['s'] as String),
        note: json['n'] as String,
        decidedAt: DateTime.parse(json['t'] as String),
      );
}

/// Ocorrência registrada pelo cidadão. Não guarda nome, contato nem localização exata.
class Occurrence {
  const Occurrence({
    required this.id,
    required this.regionId,
    required this.category,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String regionId;
  final OccurrenceCategory category;
  final String description;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'i': id,
        'r': regionId,
        'c': category.name,
        'd': description,
        't': createdAt.toIso8601String(),
      };

  factory Occurrence.fromJson(Map<String, dynamic> json) => Occurrence(
        id: json['i'] as String,
        regionId: json['r'] as String,
        category: OccurrenceCategory.values.byName(json['c'] as String),
        description: json['d'] as String,
        createdAt: DateTime.parse(json['t'] as String),
      );
}

/// Série para gráficos: pontos a partir de [forecastStart] são projeção/previsão.
class ChartSeries {
  const ChartSeries({
    required this.dates,
    required this.values,
    required this.forecastStart,
    this.baseline,
  });

  final List<DateTime> dates;
  final List<double> values;
  final int forecastStart;
  final double? baseline;
}

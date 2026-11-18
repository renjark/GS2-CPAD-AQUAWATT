import 'package:aquawatt/domain/alert_engine.dart';
import 'package:aquawatt/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const region = Region(id: 'r1', name: 'Bairro Teste', lat: 0, lng: 0, population: 1000);
  final now = DateTime(2026, 11, 16, 12);
  const engine = AlertEngine();

  /// 30 dias de água em [base] L/hab/dia; nos últimos 7 dias, multiplicado por [lastWeekFactor].
  Map<String, List<DailyReading>> readings(double lastWeekFactor) => {
        'r1': List.generate(
          30,
          (i) => DailyReading(
            date: DateTime(2026, 10, 18 + i),
            water: i >= 23 ? 100 * lastWeekFactor : 100,
            energy: 5,
          ),
        ),
      };

  List<AlertItem> run({
    required Map<String, List<DailyReading>> data,
    Map<String, List<WeatherDay>> weather = const {},
    List<Occurrence> occurrences = const [],
    Thresholds thresholds = const Thresholds(),
  }) =>
      engine.generate(
        regions: const [region],
        readings: data,
        weather: weather,
        thresholds: thresholds,
        occurrences: occurrences,
        now: now,
      );

  group('consumo', () {
    test('série estável não gera alerta', () {
      expect(run(data: readings(1.0)), isEmpty);
    });

    test('aumento de 25% gera alerta de severidade alta com justificativa', () {
      final alerts = run(data: readings(1.25));
      expect(alerts, hasLength(1));
      final alert = alerts.single;
      expect(alert.metric, Metric.water);
      expect(alert.severity, Severity.high);
      expect(alert.confidence, inInclusiveRange(0.1, 0.95));
      expect(alert.evidence, isNotEmpty);
      expect(alert.limitations, isNotEmpty);
      expect(alert.suggestedAction, isNotEmpty);
    });

    test('aumento de 12% com limiar de 10% gera severidade média', () {
      final alerts = run(data: readings(1.12));
      expect(alerts.single.severity, Severity.medium);
    });

    test('limiar maior que o aumento não gera alerta', () {
      final alerts = run(
        data: readings(1.12),
        thresholds: const Thresholds(waterPct: 20),
      );
      expect(alerts, isEmpty);
    });
  });

  group('ocorrências', () {
    Occurrence leak(int daysAgo, String id) => Occurrence(
          id: id,
          regionId: 'r1',
          category: OccurrenceCategory.waterLeak,
          description: 'Vazamento na calçada',
          createdAt: now.subtract(Duration(days: daysAgo)),
        );

    test('um relato não gera alerta', () {
      expect(run(data: readings(1.0), occurrences: [leak(1, 'a')]), isEmpty);
    });

    test('dois relatos na semana geram alerta de baixa severidade e baixa confiança', () {
      final alerts = run(data: readings(1.0), occurrences: [leak(1, 'a'), leak(2, 'b')]);
      expect(alerts.single.severity, Severity.low);
      expect(alerts.single.confidence, lessThanOrEqualTo(0.6));
    });

    test('relatos com mais de 7 dias não contam', () {
      final alerts = run(data: readings(1.0), occurrences: [leak(10, 'a'), leak(11, 'b')]);
      expect(alerts, isEmpty);
    });
  });

  group('clima', () {
    Map<String, List<WeatherDay>> weather(double tMax, double rain) => {
          'r1': [
            for (var i = 0; i < 3; i++)
              WeatherDay(date: DateTime(2026, 11, 16 + i), tMax: tMax, precipitation: rain),
          ],
        };

    test('calor acima do limiar gera alerta do território', () {
      final alerts = run(data: readings(1.0), weather: weather(36, 0));
      expect(alerts.single.regionId, kTerritoryId);
      expect(alerts.single.metric, Metric.climate);
      expect(alerts.single.severity, Severity.high);
    });

    test('temperatura e chuva abaixo dos limiares não geram alerta', () {
      expect(run(data: readings(1.0), weather: weather(28, 2)), isEmpty);
    });

    test('chuva acumulada acima do limiar gera alerta', () {
      final alerts = run(data: readings(1.0), weather: weather(25, 15));
      expect(alerts.single.title, contains('Chuva'));
    });
  });
}

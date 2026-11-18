import 'dart:math' as math;

import 'package:aquawatt/core/formatters.dart';
import 'package:aquawatt/data/regions_seed.dart';
import 'package:aquawatt/domain/models.dart';

/// Serviço simulado (substitui uma API municipal): gera 30 dias de consumo
/// sintético, determinístico por bairro, com latência artificial.
class SyntheticDataService {
  const SyntheticDataService({this.latency = const Duration(milliseconds: 800)});

  final Duration latency;
  static const int _days = 30;

  Future<Map<String, List<DailyReading>>> fetchReadings({DateTime? today}) async {
    await Future<void>.delayed(latency);
    final end = dateOnly(today ?? DateTime.now());
    return {for (final p in kProfiles) p.region.id: _series(p, end)};
  }

  List<DailyReading> _series(RegionProfile profile, DateTime end) {
    final random = math.Random(profile.seed);
    return List.generate(_days, (i) {
      final date = DateTime(end.year, end.month, end.day - (_days - 1 - i));
      final weekly = math.sin(2 * math.pi * i / 7) * 0.03;
      final noiseWater = (random.nextDouble() * 2 - 1) * 0.025;
      final noiseEnergy = (random.nextDouble() * 2 - 1) * 0.025;
      final ramp = i >= 20 ? (i - 19).toDouble() : 0.0;
      return DailyReading(
        date: date,
        water: profile.baseWater * (1 + weekly + noiseWater + profile.waterTrend * ramp),
        energy: profile.baseEnergy * (1 + weekly * 0.5 + noiseEnergy + profile.energyTrend * ramp),
      );
    });
  }
}

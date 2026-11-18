import 'package:aquawatt/domain/models.dart';

/// Perfil sintético de um bairro: consumo-base e tendência de alta recente.
class RegionProfile {
  const RegionProfile({
    required this.region,
    required this.baseWater,
    required this.baseEnergy,
    required this.waterTrend,
    required this.energyTrend,
    required this.seed,
  });

  final Region region;

  /// Consumo médio de água (L/hab/dia) e energia (kWh/hab/dia).
  final double baseWater;
  final double baseEnergy;

  /// Aumento relativo diário aplicado nos últimos 10 dias (0,02 = +2% por dia).
  final double waterTrend;
  final double energyTrend;
  final int seed;
}

const String kTerritoryTitle = 'São Paulo — 5 bairros monitorados';

/// Populações são estimativas aproximadas para fins de demonstração.
const List<RegionProfile> kProfiles = [
  RegionProfile(
    region: Region(id: 'pinheiros', name: 'Pinheiros', lat: -23.5667, lng: -46.6917, population: 65000),
    baseWater: 165, baseEnergy: 5.2, waterTrend: 0, energyTrend: 0.002, seed: 11,
  ),
  RegionProfile(
    region: Region(id: 'itaquera', name: 'Itaquera', lat: -23.5400, lng: -46.4570, population: 200000),
    baseWater: 140, baseEnergy: 3.8, waterTrend: 0.028, energyTrend: 0.004, seed: 22,
  ),
  RegionProfile(
    region: Region(id: 'santo-amaro', name: 'Santo Amaro', lat: -23.6500, lng: -46.7160, population: 70000),
    baseWater: 150, baseEnergy: 4.4, waterTrend: 0.004, energyTrend: 0.020, seed: 33,
  ),
  RegionProfile(
    region: Region(id: 'freguesia', name: 'Freguesia do Ó', lat: -23.4880, lng: -46.6910, population: 142000),
    baseWater: 135, baseEnergy: 3.6, waterTrend: 0.012, energyTrend: 0, seed: 44,
  ),
  RegionProfile(
    region: Region(id: 'mooca', name: 'Mooca', lat: -23.5590, lng: -46.5990, population: 78000),
    baseWater: 155, baseEnergy: 4.9, waterTrend: 0, energyTrend: 0, seed: 55,
  ),
];

final List<Region> kRegions = [for (final p in kProfiles) p.region];

Region regionById(String id) =>
    kRegions.firstWhere((r) => r.id == id, orElse: () => kRegions.first);

String regionName(String id) => id == kTerritoryId ? kTerritoryName : regionById(id).name;

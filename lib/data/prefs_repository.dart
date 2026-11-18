import 'dart:convert';

import 'package:aquawatt/domain/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherCache {
  const WeatherCache(this.updatedAt, this.data);

  final DateTime updatedAt;
  final Map<String, List<WeatherDay>> data;
}

/// Persistência local (shared_preferences). Leituras toleram dados corrompidos.
class PrefsRepository {
  PrefsRepository(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsRepository> open() async =>
      PrefsRepository(await SharedPreferences.getInstance());

  static const _kConsent = 'consent';
  static const _kTheme = 'theme';
  static const _kScale = 'textScale';
  static const _kRegion = 'region';
  static const _kThresholds = 'thresholds';
  static const _kOccurrences = 'occurrences';
  static const _kDecisions = 'decisions';
  static const _kWeather = 'weatherCache';

  bool get consent => _prefs.getBool(_kConsent) ?? false;
  Future<void> saveConsent(bool value) => _prefs.setBool(_kConsent, value);

  String? get theme => _prefs.getString(_kTheme);
  Future<void> saveTheme(String value) => _prefs.setString(_kTheme, value);

  double get textScale => _prefs.getDouble(_kScale) ?? 1.0;
  Future<void> saveTextScale(double value) => _prefs.setDouble(_kScale, value);

  String? get selectedRegion => _prefs.getString(_kRegion);
  Future<void> saveSelectedRegion(String value) => _prefs.setString(_kRegion, value);

  Thresholds loadThresholds() {
    final raw = _prefs.getString(_kThresholds);
    if (raw == null) return const Thresholds();
    try {
      return Thresholds.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const Thresholds();
    }
  }

  Future<void> saveThresholds(Thresholds value) =>
      _prefs.setString(_kThresholds, jsonEncode(value.toJson()));

  List<Occurrence> loadOccurrences() => _decodeList(_kOccurrences, Occurrence.fromJson);

  Future<void> saveOccurrences(List<Occurrence> items) =>
      _prefs.setString(_kOccurrences, jsonEncode([for (final i in items) i.toJson()]));

  List<HumanDecision> loadDecisions() => _decodeList(_kDecisions, HumanDecision.fromJson);

  Future<void> saveDecisions(List<HumanDecision> items) =>
      _prefs.setString(_kDecisions, jsonEncode([for (final i in items) i.toJson()]));

  WeatherCache? loadWeatherCache() {
    final raw = _prefs.getString(_kWeather);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final data = (json['data'] as Map<String, dynamic>).map(
        (id, days) => MapEntry(id, [
          for (final d in days as List) WeatherDay.fromJson(d as Map<String, dynamic>),
        ]),
      );
      return WeatherCache(DateTime.parse(json['at'] as String), data);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWeatherCache(Map<String, List<WeatherDay>> data, DateTime at) =>
      _prefs.setString(
        _kWeather,
        jsonEncode({
          'at': at.toIso8601String(),
          'data': data.map((id, days) => MapEntry(id, [for (final d in days) d.toJson()])),
        }),
      );

  /// Apaga tudo (revogação de consentimento).
  Future<void> clearAll() => _prefs.clear();

  List<T> _decodeList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return [for (final e in jsonDecode(raw) as List) fromJson(e as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }
}

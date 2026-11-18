import 'dart:convert';

import 'package:aquawatt/domain/models.dart';
import 'package:http/http.dart' as http;

class WeatherException implements Exception {
  const WeatherException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Cliente da API pública Open-Meteo (sem chave): 14 dias passados + 7 de previsão.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<WeatherDay>> fetch(Region region) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': region.lat.toString(),
      'longitude': region.lng.toString(),
      'daily': 'temperature_2m_max,precipitation_sum',
      'past_days': '14',
      'forecast_days': '7',
      'timezone': 'America/Sao_Paulo',
    });
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw WeatherException('Open-Meteo respondeu HTTP ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = body['daily'] as Map<String, dynamic>;
    final times = (daily['time'] as List).cast<String>();
    final temps = daily['temperature_2m_max'] as List;
    final rain = daily['precipitation_sum'] as List;
    return [
      for (var i = 0; i < times.length; i++)
        WeatherDay(
          date: DateTime.parse(times[i]),
          tMax: (temps[i] as num?)?.toDouble() ?? 0,
          precipitation: (rain[i] as num?)?.toDouble() ?? 0,
        ),
    ];
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/ocf_forecast.dart';

class OcfApiException implements Exception {
  OcfApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OcfApiService {
  OcfApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://maps.weather.gov.hk/ocf/dat';

  final http.Client _client;

  Future<OcfForecast> fetchHkoForecast() {
    return fetchForecast(kStationId);
  }

  Future<OcfForecast> fetchForecast(String stationId) async {
    final normalizedStation = stationId.trim().toUpperCase();
    if (normalizedStation.isEmpty) {
      throw OcfApiException('Station ID is required.');
    }

    final uri = Uri.parse('$_baseUrl/$normalizedStation.xml');
    http.Response response;

    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 20));
    } catch (error) {
      try {
        response = await _client.get(uri).timeout(const Duration(seconds: 20));
      } catch (_) {
        throw OcfApiException('Network error while fetching forecast: $error');
      }
    }

    if (response.statusCode != 200) {
      throw OcfApiException(
        'Failed to fetch forecast for $normalizedStation (HTTP ${response.statusCode}).',
      );
    }

    try {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return OcfForecast.fromJson(jsonMap);
    } on FormatException catch (error) {
      throw OcfApiException('Invalid forecast response: ${error.message}');
    }
  }

  void dispose() {
    _client.close();
  }
}

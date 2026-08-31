import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app13_hk_weather/models/ocf_forecast.dart';
import 'package:app13_hk_weather/services/ocf_api_service.dart';
import 'package:app13_hk_weather/services/ocf_export_service.dart';

void main() {
  group('parseForecastHour', () {
    test('parses YYYYMMDDHH into local DateTime', () {
      final parsed = parseForecastHour('2026083111');

      expect(parsed.year, 2026);
      expect(parsed.month, 8);
      expect(parsed.day, 31);
      expect(parsed.hour, 11);
    });

    test('throws on invalid length', () {
      expect(() => parseForecastHour('20260831'), throwsFormatException);
    });
  });

  group('OcfForecast.fromJson', () {
    late Map<String, dynamic> fixture;

    setUp(() {
      final file = File('test/fixtures/hko_ocf.json');
      fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('deserializes fixture and extracts temperature points', () {
      final forecast = OcfForecast.fromJson(fixture);
      final points = forecast.temperaturePoints();

      expect(forecast.stationCode, 'HKO');
      expect(forecast.hourlyForecasts.isNotEmpty, isTrue);
      expect(points.length, greaterThan(200));
      expect(points.first.temperatureC, isA<double>());
      expect(points.first.forecastTime, parseForecastHour('2026083111'));
    });
  });

  group('OcfExportService', () {
    test('exports CSV and JSON formats', () {
      final points = [
        TemperaturePoint(
          forecastTime: DateTime(2026, 8, 31, 11),
          temperatureC: 29.3,
        ),
        TemperaturePoint(
          forecastTime: DateTime(2026, 8, 31, 12),
          temperatureC: 27.7,
        ),
      ];

      final service = OcfExportService();
      final csv = service.toCsv(points);
      final json = service.toJson(points);

      expect(csv, contains('forecast_time,temperature_c'));
      expect(csv, contains('2026-08-31 11:00,29.3'));
      expect(json, contains('"temperatureC": 29.3'));
      expect(json, contains('"forecastTime": "2026-08-31T11:00:00.000"'));
    });
  });

  test('live fetch for HKO', () async {
    final service = OcfApiService();
    addTearDown(service.dispose);

    final forecast = await service.fetchForecast('HKO');
    final points = forecast.temperaturePoints();

    expect(forecast.stationCode, 'HKO');
    expect(points.length, greaterThan(200));
  }, skip: true);
}

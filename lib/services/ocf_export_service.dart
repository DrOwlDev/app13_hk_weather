import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ocf_forecast.dart';

class OcfExportService {
  static final _displayFormatter = DateFormat('yyyy-MM-dd HH:mm');

  String toCsv(List<TemperaturePoint> points) {
    final buffer = StringBuffer('forecast_time,temperature_c\n');
    for (final point in points) {
      buffer.writeln(
        '${_displayFormatter.format(point.forecastTime)},${point.temperatureC}',
      );
    }
    return buffer.toString();
  }

  String toJson(List<TemperaturePoint> points) {
    final payload = points.map((point) => point.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<File> saveCsv(List<TemperaturePoint> points, String stationCode) {
    return _saveFile(
      contents: toCsv(points),
      stationCode: stationCode,
      extension: 'csv',
    );
  }

  Future<File> saveJson(List<TemperaturePoint> points, String stationCode) {
    return _saveFile(
      contents: toJson(points),
      stationCode: stationCode,
      extension: 'json',
    );
  }

  Future<File> _saveFile({
    required String contents,
    required String stationCode,
    required String extension,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${stationCode.toLowerCase()}_temperature_$timestamp.$extension';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(contents);
    return file;
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models/ocf_forecast.dart';
import '../services/ocf_api_service.dart';
import '../services/ocf_export_service.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final _apiService = OcfApiService();
  final _exportService = OcfExportService();
  final _timeFormatter = DateFormat('yyyy-MM-dd HH:mm');

  bool _isLoading = false;
  String? _errorMessage;
  OcfForecast? _forecast;
  List<TemperaturePoint> _temperaturePoints = const [];

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _fetchForecast() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final forecast = await _apiService.fetchHkoForecast();
      if (!mounted) {
        return;
      }

      setState(() {
        _forecast = forecast;
        _temperaturePoints = forecast.temperaturePoints();
        _isLoading = false;
      });
    } on OcfApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _forecast = null;
        _temperaturePoints = const [];
        _isLoading = false;
      });
    }
  }

  Future<void> _copyJson() async {
    if (_temperaturePoints.isEmpty) {
      return;
    }

    final payload = _exportService.toJson(_temperaturePoints);
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON copied to clipboard')),
    );
  }

  Future<void> _exportCsv() async {
    await _exportPoints(
      label: 'CSV',
      export: () => _exportService.saveCsv(
        _temperaturePoints,
        _forecast!.stationCode,
      ),
    );
  }

  Future<void> _exportJson() async {
    await _exportPoints(
      label: 'JSON',
      export: () => _exportService.saveJson(
        _temperaturePoints,
        _forecast!.stationCode,
      ),
    );
  }

  Future<void> _exportPoints({
    required String label,
    required Future<File> Function() export,
  }) async {
    if (_forecast == null || _temperaturePoints.isEmpty) {
      return;
    }

    try {
      final file = await export();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label saved to ${file.path}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export $label: $error')),
      );
    }
  }

  String _summaryText() {
    if (_isLoading && _forecast == null) {
      return 'Loading forecast for $kStationId...';
    }

    final forecast = _forecast;
    if (forecast == null) {
      return 'No forecast loaded for $kStationId.';
    }

    final lastModified = parseCompactTimestamp(forecast.lastModified);
    final modelTime = parseCompactTimestamp(forecast.modelTime);
    final lastModifiedText = lastModified == null
        ? forecast.lastModified.toString()
        : _timeFormatter.format(lastModified);
    final modelTimeText = modelTime == null
        ? forecast.modelTime.toString()
        : _timeFormatter.format(modelTime);

    return 'Station ${forecast.stationCode} | '
        '${_temperaturePoints.length} temperature points | '
        'Model $modelTimeText | '
        'Updated $lastModifiedText';
  }

  @override
  Widget build(BuildContext context) {
    final hasPoints = _temperaturePoints.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HKO OCF Temperature'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hong Kong Observatory ($kStationId)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton(
                  onPressed: _isLoading ? null : _fetchForecast,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_summaryText()),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: hasPoints ? _exportCsv : null,
                  child: const Text('Export CSV'),
                ),
                OutlinedButton(
                  onPressed: hasPoints ? _exportJson : null,
                  child: const Text('Export JSON'),
                ),
                OutlinedButton(
                  onPressed: hasPoints ? _copyJson : null,
                  child: const Text('Copy JSON'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: hasPoints
                  ? SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('#')),
                            DataColumn(label: Text('Time')),
                            DataColumn(label: Text('Temp (°C)')),
                          ],
                          rows: [
                            for (var index = 0; index < _temperaturePoints.length; index++)
                              DataRow(
                                cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(
                                    Text(
                                      _timeFormatter.format(
                                        _temperaturePoints[index].forecastTime,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _temperaturePoints[index].temperatureC.toStringAsFixed(1),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        _isLoading
                            ? 'Loading temperature forecast for $kStationId...'
                            : 'No temperature data available for $kStationId.',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TemperaturePoint {
  const TemperaturePoint({
    required this.forecastTime,
    required this.temperatureC,
  });

  final DateTime forecastTime;
  final double temperatureC;

  Map<String, dynamic> toJson() => {
        'forecastTime': forecastTime.toIso8601String(),
        'temperatureC': temperatureC,
      };
}

class HourlyForecast {
  const HourlyForecast({
    required this.forecastHour,
    this.temperatureC,
    this.relativeHumidity,
    this.windDirection,
    this.windSpeed,
    this.weatherCode,
  });

  final String forecastHour;
  final double? temperatureC;
  final double? relativeHumidity;
  final double? windDirection;
  final double? windSpeed;
  final int? weatherCode;

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      forecastHour: json['ForecastHour'] as String,
      temperatureC: _toDouble(json['ForecastTemperature']),
      relativeHumidity: _toDouble(json['ForecastRelativeHumidity']),
      windDirection: _toDouble(json['ForecastWindDirection']),
      windSpeed: _toDouble(json['ForecastWindSpeed']),
      weatherCode: json['ForecastWeather'] as int?,
    );
  }

  TemperaturePoint? toTemperaturePoint() {
    final temperature = temperatureC;
    if (temperature == null) {
      return null;
    }

    return TemperaturePoint(
      forecastTime: parseForecastHour(forecastHour),
      temperatureC: temperature,
    );
  }
}

class DailyForecast {
  const DailyForecast({
    required this.forecastDate,
    this.chanceOfRain,
    this.dailyWeather,
    this.maximumTemperatureC,
    this.minimumTemperatureC,
  });

  final String forecastDate;
  final String? chanceOfRain;
  final int? dailyWeather;
  final double? maximumTemperatureC;
  final double? minimumTemperatureC;

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      forecastDate: json['ForecastDate'] as String,
      chanceOfRain: json['ForecastChanceOfRain'] as String?,
      dailyWeather: json['ForecastDailyWeather'] as int?,
      maximumTemperatureC: _toDouble(json['ForecastMaximumTemperature']),
      minimumTemperatureC: _toDouble(json['ForecastMinimumTemperature']),
    );
  }
}

class OcfForecast {
  const OcfForecast({
    required this.lastModified,
    required this.stationCode,
    required this.latitude,
    required this.longitude,
    required this.modelTime,
    required this.hourlyForecasts,
    required this.dailyForecasts,
  });

  final int lastModified;
  final String stationCode;
  final double latitude;
  final double longitude;
  final int modelTime;
  final List<HourlyForecast> hourlyForecasts;
  final List<DailyForecast> dailyForecasts;

  factory OcfForecast.fromJson(Map<String, dynamic> json) {
    final hourlyJson = json['HourlyWeatherForecast'] as List<dynamic>? ?? [];
    final dailyJson = json['DailyForecast'] as List<dynamic>? ?? [];

    return OcfForecast(
      lastModified: json['LastModified'] as int,
      stationCode: json['StationCode'] as String,
      latitude: (json['Latitude'] as num).toDouble(),
      longitude: (json['Longitude'] as num).toDouble(),
      modelTime: json['ModelTime'] as int,
      hourlyForecasts: hourlyJson
          .map((item) => HourlyForecast.fromJson(item as Map<String, dynamic>))
          .toList(),
      dailyForecasts: dailyJson
          .map((item) => DailyForecast.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  List<TemperaturePoint> temperaturePoints() {
    return hourlyForecasts
        .map((hourly) => hourly.toTemperaturePoint())
        .whereType<TemperaturePoint>()
        .toList();
  }
}

DateTime parseForecastHour(String forecastHour) {
  if (forecastHour.length != 10) {
    throw FormatException('Expected YYYYMMDDHH, got "$forecastHour"');
  }

  final year = int.parse(forecastHour.substring(0, 4));
  final month = int.parse(forecastHour.substring(4, 6));
  final day = int.parse(forecastHour.substring(6, 8));
  final hour = int.parse(forecastHour.substring(8, 10));

  return DateTime(year, month, day, hour);
}

DateTime? parseCompactTimestamp(int value) {
  final text = value.toString();
  if (text.length == 10) {
    return parseForecastHour(text);
  }
  if (text.length == 12) {
    final year = int.parse(text.substring(0, 4));
    final month = int.parse(text.substring(4, 6));
    final day = int.parse(text.substring(6, 8));
    final hour = int.parse(text.substring(8, 10));
    final minute = int.parse(text.substring(10, 12));
    return DateTime(year, month, day, hour, minute);
  }
  return null;
}

double? _toDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

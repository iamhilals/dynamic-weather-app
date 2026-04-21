import 'package:flutter/material.dart';

// --- 1. SAATLİK TAHMİN ---
class HourlyForecast {
  final String time;
  final double temp;
  final String condition;

  HourlyForecast({
    required this.time,
    required this.temp,
    required this.condition,
  });
}

// --- 2. GÜNLÜK TAHMİN ---
class ForecastEntity {
  final String dayName;
  final double temp;
  final String condition;
  final double humidity;
  final double windSpeed;
  final List<HourlyForecast> hourly;

  ForecastEntity({
    required this.dayName,
    required this.temp,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.hourly,
  });
}

// --- 3. ANA HAVA DURUMU MODELİ ---
class WeatherEntity {
  final String cityName;
  final double temperature;
  final String condition;
  final IconData conditionIcon;
  final List<ForecastEntity> forecast;

  WeatherEntity({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.conditionIcon,
    required this.forecast,
  });

  factory WeatherEntity.fromJson(Map<String, dynamic> json) {
    // API'den gelen ana liste
    final List list = json['list'];
    final String city = json['city']['name'];

    // Tahmin listesini oluştur (Her 8. kayıt bir sonrakin günü temsil eder)
    List<ForecastEntity> forecastList = [];
    for (int i = 0; i < list.length; i += 8) {
      final dayData = list[i];
      forecastList.add(ForecastEntity(
        dayName: _getFormattedDay(dayData['dt_txt']),
        temp: (dayData['main']['temp'] as num).toDouble(),
        condition: dayData['weather'][0]['description'] ?? '',
        humidity: (dayData['main']['humidity'] as num).toDouble(),
        windSpeed: (dayData['wind']['speed'] as num).toDouble(),
        hourly: [], // Boş liste şimdilik kalsın, hata vermez
      ));
    }

    return WeatherEntity(
      cityName: city,
      temperature: (list[0]['main']['temp'] as num).toDouble(),
      condition: list[0]['weather'][0]['description'] ?? '',
      conditionIcon: _getIcon(list[0]['weather'][0]['main']),
      forecast: forecastList,
    );
  }

  static IconData _getIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'clouds': return Icons.cloud;
      case 'rain': return Icons.umbrella;
      case 'snow': return Icons.ac_unit;
      case 'clear': return Icons.wb_sunny;
      default: return Icons.wb_cloudy_outlined;
    }
  }

  static String _getFormattedDay(String dateText) {
    try {
      DateTime date = DateTime.parse(dateText);
      return ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"][date.weekday - 1];
    } catch (e) {
      return "Bugün";
    }
  }
}
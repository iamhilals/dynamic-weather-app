import 'package:flutter/material.dart';
import '../../domain/entities/weather_entity.dart';

class WeatherModel extends WeatherEntity {
  WeatherModel({
    required super.cityName,
    required super.temperature,
    required super.condition,
    required super.conditionIcon,
    required super.forecast,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final List list = json['list'];
    final Map<String, List<dynamic>> groupedByDay = {};

    // Günlere göre gruplama
    for (var item in list) {
      final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000).toLocal();
      final key = "${dt.year}-${dt.month}-${dt.day}";

      if (!groupedByDay.containsKey(key)) {
        groupedByDay[key] = [];
      }
      groupedByDay[key]!.add(item);
    }

    final List<ForecastEntity> forecastList = [];
    final keys = groupedByDay.keys.take(7);

    for (var key in keys) {
      final dayItems = groupedByDay[key]!;
      final first = dayItems.first;
      final dt = DateTime.fromMillisecondsSinceEpoch(first['dt'] * 1000).toLocal();

      final List<HourlyForecast> hourly = dayItems.map((item) {
        final d = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000).toLocal();

        return HourlyForecast(
          time: "${d.hour.toString().padLeft(2, '0')}:00",
          temp: (item['main']['temp'] as num).toDouble(),
          condition: item['weather'][0]['main'],
        );
      }).toList();

      forecastList.add(
        ForecastEntity(
          dayName: _getDayName(dt.weekday),
          temp: (first['main']['temp'] as num).toDouble(),
          condition: first['weather'][0]['main'],
          humidity: (first['main']['humidity'] as num).toDouble(),
          windSpeed: (first['wind']['speed'] as num).toDouble(),
          hourly: hourly,
        ),
      );
    }

    return WeatherModel(
      cityName: json['city']['name'] ?? "Bilinmiyor",
      temperature: (list[0]['main']['temp'] as num).toDouble(),
      condition: list[0]['weather'][0]['main'],
      conditionIcon: _getIconByCondition(list[0]['weather'][0]['main']),
      forecast: forecastList,
    );
  }

  // --- KRİTİK DÜZELTME: toEntity Sınıfın İçine Alındı ---
  WeatherEntity toEntity() {
    return WeatherEntity(
      cityName: cityName,
      temperature: temperature, // 'temp' değil, sendeki adı 'temperature'
      condition: condition,
      conditionIcon: conditionIcon,
      forecast: forecast,
    );
  }

  static IconData _getIconByCondition(String condition) {
    String cond = condition.toLowerCase();
    if (cond.contains("cloud")) return Icons.wb_cloudy_rounded;
    if (cond.contains("rain")) return Icons.beach_access_rounded;
    if (cond.contains("clear")) return Icons.wb_sunny_rounded;
    if (cond.contains("snow")) return Icons.ac_unit_rounded;
    return Icons.wb_cloudy_outlined;
  }

  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return "Pazartesi";
      case 2: return "Salı";
      case 3: return "Çarşamba";
      case 4: return "Perşembe";
      case 5: return "Cuma";
      case 6: return "Cumartesi";
      case 7: return "Pazar";
      default: return "";
    }
  }
}
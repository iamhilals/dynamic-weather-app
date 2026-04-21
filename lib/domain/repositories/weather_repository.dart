import '../entities/weather_entity.dart';

abstract class WeatherRepository {
  Future<WeatherEntity> getCurrentWeather(double lat, double lon);
  // Bu bir 'abstract class' ise sadece bu satırı ekle:
  Future<WeatherEntity> getWeatherByCity(String cityName);
}
import 'package:dynamic_weather_app/data/datasources/weather_remote_data_source.dart';

import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_data_source.dart';
// import 'dart:convert'; // Artık burada ihtiyacımız yok, DataSource halledecek
// import '../../data/models/weather_model.dart'; // Artık burada ihtiyacımız yok

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource;

  WeatherRepositoryImpl(this.remoteDataSource);

  @override
  Future<WeatherEntity> getCurrentWeather(double lat, double lon) async {
    try {
      // Mevcut konum fonksiyonun
      final weatherModel = await remoteDataSource.getWeatherByLocation(lat, lon);
      return weatherModel;
    } catch (e) {
      throw Exception("Konum verisi çekilirken hata oluştu: $e");
    }
  }

  @override
  Future<WeatherEntity> getWeatherByCity(String cityName) async {
    try {
      // YENİ: Şehir arama işini de DataSource'a yaptırıyoruz
      // toEntity() sayesinde Model'i Entity'ye çevirip döndürüyoruz
      final weatherModel = await remoteDataSource.getWeatherByCityName(cityName);
      return weatherModel; 
    } catch (e) {
      throw Exception("Şehir verisi çekilirken hata oluştu: $e");
    }
  }
}

extension on WeatherRemoteDataSource {
  Future getWeatherByCityName(String cityName) {
    throw UnimplementedError('This method should not be called on the extension');
  }
}
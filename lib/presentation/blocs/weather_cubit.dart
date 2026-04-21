import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/entities/weather_entity.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// --- STATES (Durumlar) ---
abstract class WeatherState {}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final WeatherEntity weather;
  WeatherLoaded(this.weather);
}

class WeatherError extends WeatherState {
  final String message;
  WeatherError(this.message);
}

// --- CUBIT (Yönetici) ---
class WeatherCubit extends Cubit<WeatherState> {
  final WeatherRepository repository; // Değişken adın 'repository'

  WeatherCubit(this.repository) : super(WeatherInitial());

  Future<void> fetchWeatherByCity(String cityName) async {
  try {
    emit(WeatherLoading());

final String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? "";
    String cleanName = cityName.trim();
    
    // ÖNEMLİ: Kars için ismi 'Kars,TR' olarak zorlayalım ve 
    // forecast yerine 'weather' (anlık) API'sini test amaçlı deneyelim.
    // Çünkü 'weather' API'si her zaman daha kararlı çalışır.
    
// Cubit içindeki URL'yi tam olarak bu şekilde güncelle:
// Cubit içindeki URL'yi tam olarak bu şekilde güncelle:
final String url = "https://api.openweathermap.org/data/2.5/forecast?q=${Uri.encodeComponent(cityName.trim())},TR&units=metric&lang=tr&appid=$apiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Eğer forecast kullanmak zorundaysan ve anlık veri geliyorsa, 
      // Entity'de ufak bir düzenleme ile sahte forecast oluşturabiliriz.
      final weather = WeatherEntity.fromJson(data); 
      emit(WeatherLoaded(weather));
      print("DEBUG: SONUNDA BAŞARDIK! Kars verisi geldi.");
    } else {
      print("DEBUG: API Hala 404 Veriyor: ${response.body}");
      emit(WeatherError("Şehir bulunamadı."));
    }
  } catch (e) {
    print("DEBUG: Catch hatası: $e");
    emit(WeatherError("Bağlantı hatası."));
  }
}
  
Future<void> fetchWeatherByLocation(double lat, double lon) async {
  try {
    emit(WeatherLoading());

    final String apiKey = "9e4aa558c3ef100e619d662fb42b5120";
    // URL'de q= yerine lat= ve lon= kullanıyoruz
    final url = "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&lang=tr&appid=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final weather = WeatherEntity.fromJson(data);
      emit(WeatherLoaded(weather));
    } else {
      emit(WeatherError("Konum bilgisi alınamadı."));
    }
  } catch (e) {
    emit(WeatherError("Konum hatası: $e"));
  }
}
  

  void emitLoading() {}
}
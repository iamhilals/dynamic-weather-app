import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherRemoteDataSource {
  final String apiKey = "9e4aa558c3ef100e619d662fb42b5120";

  // 1. Koordinat ile Arama
  Future<WeatherModel> getWeatherByLocation(double lat, double lon) async {
    final url =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=tr";

    print("Konum İsteği Atılan URL: $url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(json.decode(response.body));
    } else {
      print("API Hatası (Konum): ${response.statusCode} - ${response.body}");
      throw Exception("Hava durumu çekilemedi (Kod: ${response.statusCode})");
    }
  }

  // 2. Şehir İsmi ile Arama (YENİ EKLENDİ)
Future<WeatherModel> getWeatherByCityName(String cityName) async {
  // Şehir ismindeki Türkçe karakterleri ve boşlukları URL uyumlu yapar
  final encodedCity = Uri.encodeComponent(cityName);
  
final url = "https://api.openweathermap.org/data/2.5/forecast?q=$encodedCity&appid=9e4aa558c3ef100e619d662fb42b5120&units=metric&lang=tr";  
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception("Şehir bulunamadı. Lütfen ismi kontrol edin.");
    } else {
      throw Exception("Sunucu hatası: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Bağlantı hatası: $e");
  }
}
}
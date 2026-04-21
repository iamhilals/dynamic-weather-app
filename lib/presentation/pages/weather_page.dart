import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../blocs/weather_cubit.dart';
import '../../domain/entities/weather_entity.dart';
import '../../data/datasources/location_service.dart';

// --- MERKEZİ TEMA YAPISI ---
class WeatherTheme {
  final String bgAsset;
  final String lottieAsset;
  final String advice;
  final Color accentColor;
  final String conditionText;

  WeatherTheme({
    required this.bgAsset,
    required this.lottieAsset,
    required this.advice,
    required this.accentColor,
    required this.conditionText,
  });
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.easeInOut));
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    _fetchInitialWeather();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchInitialWeather() async {
    // Önce yükleniyor ekranını gösterelim ki "Hata" yazısı çıkmasın
    context.read<WeatherCubit>().emitLoading();

    try {
      final position = await LocationService().getCurrentLocation();
      if (mounted) {
        context
            .read<WeatherCubit>()
            .fetchWeatherByLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      // Konum alınamazsa varsayılan olarak İstanbul'u getir
      if (mounted) {
        context.read<WeatherCubit>().fetchWeatherByCity("İstanbul");
      }
    }
  }

// --- ARAMA MOTORU (KARS HATASINI ÇÖZEN VE DAHA SAĞLAM HALE GETİRİLEN KISIM) ---
  Future<List<String>> _getCitySuggestions(String pattern) async {
    if (pattern.length < 2) return [];

    // Limit değerini 5 yaptık ki seçenekler net olsun
    final url =
        "http://api.openweathermap.org/geo/1.0/direct?q=${Uri.encodeComponent(pattern)}&limit=5&appid=9e4aa558c3ef100e619d662fb42b5120";

    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        return data
            .map((item) {
              final name = item['name'];
              final country = item['country'];
              // Kars Merkez gibi detaylar kafa karıştırmasın diye sadece Şehir ve Ülke kodu
              return "$name, $country";
            })
            .toSet()
            .toList(); // Aynı isimli şehirleri teke düşürür
      }
    } catch (e) {
      debugPrint("API Hatası: $e");
    }
    return [];
  }

// --- TEMA VE UYUM MOTORU (TUTARSIZLIĞI GİDEREN GÜNCELLEME) ---
// ignore: unused_element
  WeatherTheme _getWeatherTheme(double temp, String condition) {
    String cond = condition.toLowerCase();

    // Önce en baskın hava durumuna bakıyoruz (Kar > Yağmur > Bulut > Açık)
    if (cond.contains('snow') || cond.contains('kar')) {
      return WeatherTheme(
        conditionText: "Karlı",
        bgAsset: "assets/images/snow_bg.jpg",
        lottieAsset: "assets/lottie/cold.json", // Kar için soğuk animasyonu
        advice: "Hava dondurucu! ❄️ Kalın kaban ve atkı şart.",
        accentColor: Colors.lightBlueAccent,
      );
    }

    if (cond.contains('rain') ||
        cond.contains('shower') ||
        cond.contains('drizzle')) {
      return WeatherTheme(
        conditionText: "Yağmurlu",
        bgAsset: "assets/images/rainy_bg.jpg",
        lottieAsset: "assets/lottie/rainy.json",
        advice: temp < 10
            ? "Soğuk ve yağmurlu. ☔ Sıkı giyin ve şemsiyeni al."
            : "Ilık bir yağmur var. 🌧️ Şemsiye gerekebilir.",
        accentColor: Colors.blueAccent,
      );
    }

    if (cond.contains('cloud') ||
        cond.contains('overcast') ||
        cond.contains('mist') ||
        cond.contains('fog')) {
      return WeatherTheme(
        conditionText: "Bulutlu",
        bgAsset: "assets/images/cloudy_bg.jpg",
        lottieAsset: temp < 12
            ? "assets/lottie/cold.json"
            : "assets/lottie/sunny.json", // Soğuksa titreyen, ılıksa sakin bulut
        advice: temp < 15
            ? "Hava gri ve serin. 🧥 Ceketini almayı unutma."
            : "Hava kapalı ama yumuşak. ☁️ Rahat bir şeyler giy.",
        accentColor: Colors.blueGrey,
      );
    }

    // Varsayılan: Güneşli/Açık
    return WeatherTheme(
      conditionText: "Güneşli",
      bgAsset: "assets/images/sunny_bg.jpg",
      lottieAsset: "assets/lottie/sunny.json",
      advice: "Hava harika! ☀️ Güneş gözlüğünü tak ve günün tadını çıkar.",
      accentColor: Colors.amberAccent,
    );
  }

// --- ONSELECTED VE ONSUBMITTED KISMINDAKİ KRİTİK DÜZELTME ---
// Bu iki fonksiyonda da context.read<WeatherCubit>().fetchWeatherByCity(cleanName);
// çağırmadan önce cleanName'in sadece ilk parçasını aldığından emin ol:
// final cleanName = suggestion.split(',')[0].trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: BlocBuilder<WeatherCubit, WeatherState>(
          builder: (context, state) {
            // 1. DURUM: Yükleniyor veya Uygulama Yeni Açılıyor
            if (state is WeatherLoading || state is WeatherInitial) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            // 2. DURUM: Veri Başarıyla Yüklendi
            // WeatherPage.dart içinde state is WeatherLoaded olduğunda:
if (state is WeatherLoaded) {
  final weather = state.weather;
  
  // Eğer liste boşsa 0. indexe erişmek uygulamayı dondurur!
  if (weather.forecast.isEmpty) {
    return const Center(child: Text("Hava durumu verisi eksik"));
  }

  // Güvenli erişim
  final selected = weather.forecast.length > _selectedIndex 
      ? weather.forecast[_selectedIndex] 
      : weather.forecast[0];

  final theme = _getWeatherTheme(selected.temp.toDouble(), selected.condition);

              return Stack(
                children: [
                  // Arka Plan Resmi
                  Positioned.fill(
                      child: Image.asset(theme.bgAsset, fit: BoxFit.cover)),
                  // Bulanıklaştırma Efekti
                  Positioned.fill(
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child:
                              Container(color: Colors.black.withOpacity(0.3)))),

                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          _buildSearchField(), // Arama Motoru
                          const SizedBox(height: 20),
                          _buildHeader(weather.cityName, selected.dayName),
                          const SizedBox(height: 30),
                          _buildMainTemp(weather.conditionIcon, selected.temp),
                          const SizedBox(height: 20),
                          _buildHourlyList(selected.hourly),
                          const SizedBox(height: 25),
                          _buildForecastList(weather.forecast),
                          const SizedBox(height: 25),
                          _buildDetailGrid(selected, theme),
                          const SizedBox(height: 30),
                          _buildRichRecommendationCard(selected, theme),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // 3. DURUM: Hata Oluştu (Kars bulunamadı vb.)
            if (state is WeatherError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      onPressed: () => _fetchInitialWeather(),
                      child: const Text("Tekrar Dene",
                          style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              );
            }

            // Beklenmedik bir şey olursa boş dön
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // --- WIDGET BİLEŞENLERİ ---

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TypeAheadField<String>(
        suggestionsCallback: _getCitySuggestions,
        builder: (context, controller, focusNode) => TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Şehir ara...",
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
          // --- DÜZELTME 1: Klavyeden Enter'a basınca ---
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              // "Kars, Merkez, TR" gelse bile sadece "Kars" kısmını alıyoruz
              final cleanName = val.split(',')[0].trim();
              context.read<WeatherCubit>().fetchWeatherByCity(cleanName);
            }
          },
        ),
        itemBuilder: (context, suggestion) => ListTile(
          title: Text(suggestion, style: const TextStyle(color: Colors.black)),
        ),
        // --- DÜZELTME 2: Listeden bir şehre tıklayınca ---
        // WeatherPage.dart içinde
        onSelected: (suggestion) {
          // Öneri ne gelirse gelsin sadece virgülden öncesini temizleyip yolla
          final clean = suggestion.split(',')[0].trim();
          context.read<WeatherCubit>().fetchWeatherByCity(clean);
        },
      ),
    );
  }

  Widget _buildHeader(String city, String day) {
    return Column(
      children: [
        Text(city.toUpperCase(),
            style: GoogleFonts.poppins(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 3)),
        Text(day,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildMainTemp(IconData icon, double temp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 70, color: Colors.white),
        const SizedBox(width: 15),
        Text("${temp.round()}°",
            style: GoogleFonts.poppins(
                fontSize: 90,
                color: Colors.white,
                fontWeight: FontWeight.w200)),
      ],
    );
  }

  Widget _buildHourlyList(List<HourlyForecast>? hourly) {
    if (hourly == null || hourly.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 25),
        itemCount: hourly.length,
        itemBuilder: (context, index) {
          final item = hourly[index];
          return Container(
            width: 75,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.time,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 8),
                const Icon(Icons.wb_cloudy_outlined,
                    color: Colors.white, size: 22),
                const SizedBox(height: 8),
                Text("${item.temp.round()}°",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForecastList(List<ForecastEntity> forecast) {
    return SizedBox(
      height: 115,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 25),
        itemCount: forecast.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedIndex == index;
          final item = forecast[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 85,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.dayName,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  const SizedBox(height: 8),
                  const Icon(Icons.wb_sunny_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(height: 8),
                  Text("${item.temp.round()}°",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailGrid(ForecastEntity selected, WeatherTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          Row(
            children: [
              _buildDetailCard("Nem", "%${selected.humidity.round()}",
                  Icons.water_drop_outlined),
              const SizedBox(width: 15),
              _buildDetailCard("Rüzgar", "${selected.windSpeed.round()} km/s",
                  Icons.air_rounded),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildDetailCard("Hissedilen", "${(selected.temp - 2).round()}°",
                  Icons.thermostat_outlined),
              const SizedBox(width: 15),
              _buildDetailCard(
                  "Durum", theme.conditionText, Icons.cloud_queue_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildRichRecommendationCard(
      ForecastEntity selected, WeatherTheme theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage(theme.bgAsset),
                fit: BoxFit.cover,
                opacity: 0.3),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
                color: theme.accentColor.withOpacity(0.4), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                        width: 80,
                        height: 80,
                        child: Lottie.asset(theme.lottieAsset,
                            fit: BoxFit.contain)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("GÜNÜN STİLİ",
                              style: GoogleFonts.poppins(
                                  color: theme.accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                          const SizedBox(height: 6),
                          Text(theme.advice,
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



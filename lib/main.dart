import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/utils/injection_container.dart' as di; // Dependency Injection
import 'presentation/blocs/weather_cubit.dart';
import 'presentation/pages/weather_page.dart';

void main() async {
  // 1. Flutter motorunu başlat
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Dependency Injection'ı başlat (sl'nin çalışması için şart)
  await di.init(); 

  // 3. .env dosyasındaki API anahtarını belleğe yükle
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dinamik Hava Durumu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      // Cubit'i tüm uygulamaya sağlıyoruz
      home: BlocProvider(
        create: (_) => di.sl<WeatherCubit>(),
        child: const WeatherPage(),
      ),
    );
  }
}
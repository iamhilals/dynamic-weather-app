import 'package:dynamic_weather_app/domain/repositories/weather_repository_impl.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/weather_remote_data_source.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../presentation/blocs/weather_cubit.dart';

final sl = GetIt.instance; // sl: Service Locator

Future<void> init() async {
  // BLoC / Cubit
  sl.registerFactory(() => WeatherCubit(sl()));

  // Repository
  sl.registerLazySingleton<WeatherRepository>(
    () => WeatherRepositoryImpl(sl()),
  );

  // Data Sources
  sl.registerLazySingleton(() => WeatherRemoteDataSource());
}
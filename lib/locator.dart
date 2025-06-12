import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:urban_match_assignment/core/network/network_info.dart';
import 'package:urban_match_assignment/features/events/data/datasources/event_remote_data_source.dart';
import 'package:urban_match_assignment/features/events/data/repositories/event_repository_impl.dart';
import 'package:urban_match_assignment/features/events/domain/usecases/get_events.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.allowReassignment = true;

  // Core
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<Connectivity>()),
  );

  // External
  getIt.registerLazySingleton<Dio>(() => Dio());

  // Data
  getIt.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<EventRepositoryImpl>(
    () => EventRepositoryImpl(
      remote: getIt<EventRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );

  // Domain
  getIt.registerLazySingleton<GetEventsUseCase>(
    () => GetEventsUseCase(getIt<EventRepositoryImpl>()),
  );
}

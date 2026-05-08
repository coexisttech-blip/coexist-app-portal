import 'package:coexist_app_portal/features/app_configs/di/app_config_injection.dart';
import 'package:coexist_app_portal/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:coexist_app_portal/features/events/di/events_injection.dart';
import 'package:coexist_app_portal/features/pickups/di/pickups_injection.dart';
import 'package:coexist_app_portal/features/tree_planting/di/tree_planting_injection.dart';
import 'package:coexist_app_portal/features/waste_categories/di/waste_categories_injection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/repositories/user_profile_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/user_profile_repository.dart';

// Service locator
final sl = GetIt.instance;

/// Initialize dependencies
Future<void> init() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  sl.registerSingleton<Dio>(Dio());
  sl.registerSingleton<Connectivity>(Connectivity());
  sl.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // Core
  sl.registerSingleton<ApiClient>(ApiClient(sl<Dio>()));
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl<Connectivity>()));

  // Feature: Auth
  _initAuthDependencies();

  _initAppConfigDependencies();

  _initEventDependencies();

  _initPickupDependencies();

  _initWasteCategoryDependencies();

  _initTreePlantingDependencies();
}

/// Initialize Auth dependencies
void _initAuthDependencies() {
  // Data sources
  sl.registerLazySingleton<AuthLocalDatasource>(
    () => AuthLocalDatasourceImpl(sharedPreferences: sl<SharedPreferences>()),
  );

  // Repositories
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(
      supabaseClient: sl<SupabaseClient>(),
      localDatasource: sl<AuthLocalDatasource>(),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      supabaseClient: sl<SupabaseClient>(),
      localDatasource: sl<AuthLocalDatasource>(),
      userProfileRepository: sl<UserProfileRepository>(),
    ),
  );

  // BLoCs
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
}

/// Initialize App Config dependencies
void _initAppConfigDependencies() {
  registerAppConfigDependencies(sl);
}

void _initEventDependencies() {
  // Register Event-related dependencies here
  registerEventDependencies(sl);
}

void _initPickupDependencies() {
  registerPickupDependencies(sl);
}

void _initWasteCategoryDependencies() {
  registerWasteCategoryDependencies(sl);
}

void _initTreePlantingDependencies() {
  registerTreePlantingDependencies(sl);
}

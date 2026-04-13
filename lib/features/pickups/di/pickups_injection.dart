import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/pickup_repository_impl.dart';
import '../domain/repositories/pickup_repository.dart';
import '../presentation/bloc/pickup_bloc.dart';

void registerPickupDependencies(GetIt sl) {
  // Repository
  sl.registerLazySingleton<PickupRepository>(
    () => PickupRepositoryImpl(supabaseClient: sl<SupabaseClient>()),
  );

  // BLoC
  sl.registerFactory(
    () => PickupBloc(pickupRepository: sl<PickupRepository>()),
  );
}

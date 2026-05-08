import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/tree_planting_repository_impl.dart';
import '../domain/repositories/tree_planting_repository.dart';
import '../presentation/bloc/tree_planting_bloc.dart';

void registerTreePlantingDependencies(GetIt sl) {
  sl.registerLazySingleton<TreePlantingRepository>(
    () => TreePlantingRepositoryImpl(
      supabaseClient: Supabase.instance.client,
    ),
  );

  sl.registerFactory<TreePlantingBloc>(
    () => TreePlantingBloc(repository: sl<TreePlantingRepository>()),
  );
}

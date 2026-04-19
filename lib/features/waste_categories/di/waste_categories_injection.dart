import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/waste_category_repository_impl.dart';
import '../domain/repositories/waste_category_repository.dart';
import '../presentation/bloc/waste_category_bloc.dart';

void registerWasteCategoryDependencies(GetIt sl) {
  sl.registerLazySingleton<WasteCategoryRepository>(
    () => WasteCategoryRepositoryImpl(
      supabaseClient: Supabase.instance.client,
    ),
  );

  sl.registerFactory<WasteCategoryBloc>(
    () => WasteCategoryBloc(repository: sl<WasteCategoryRepository>()),
  );
}

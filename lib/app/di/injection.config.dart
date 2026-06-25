// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../core/audio/audio_service.dart' as _i172;
import '../../core/audio/audio_service_impl.dart' as _i27;
import '../../core/database/app_database.dart' as _i50;
import '../../features/game/data/datasources/game_local_datasource.dart'
    as _i502;
import '../../features/game/data/datasources/game_local_datasource_impl.dart'
    as _i821;
import '../../features/game/data/repositories/game_repository_impl.dart'
    as _i33;
import '../../features/game/data/seeders/case_seeder.dart' as _i766;
import '../../features/game/domain/repositories/game_repository.dart' as _i32;
import '../../features/game/domain/usecases/initialize_local_catalog.dart'
    as _i984;
import '../../features/game/presentation/cubit/game_cubit.dart' as _i192;
import '../router/app_router.dart' as _i81;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i81.AppRouter>(() => _i81.AppRouter());
    gh.lazySingleton<_i50.AppDatabase>(() => _i50.AppDatabase());
    gh.lazySingleton<_i172.AudioService>(() => _i27.SafeAudioService());
    gh.lazySingleton<_i502.GameLocalDatasource>(
      () => _i821.GameLocalDatasourceImpl(gh<_i50.AppDatabase>()),
    );
    gh.lazySingleton<_i766.CaseSeeder>(
      () => _i766.CaseSeeder(gh<_i502.GameLocalDatasource>()),
    );
    gh.lazySingleton<_i32.GameRepository>(
      () => _i33.GameRepositoryImpl(
        gh<_i502.GameLocalDatasource>(),
        gh<_i766.CaseSeeder>(),
      ),
    );
    gh.factory<_i192.GameCubit>(
      () =>
          _i192.GameCubit(gh<_i32.GameRepository>(), gh<_i172.AudioService>()),
    );
    gh.factory<_i984.InitializeLocalCatalog>(
      () => _i984.InitializeLocalCatalog(gh<_i32.GameRepository>()),
    );
    return this;
  }
}

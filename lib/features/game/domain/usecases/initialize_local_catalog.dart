import 'package:injectable/injectable.dart';

import '../repositories/game_repository.dart';

@injectable
class InitializeLocalCatalog {
  const InitializeLocalCatalog(this._repository);

  final GameRepository _repository;

  Future<void> call() => _repository.initializeLocalCatalog();
}

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;
bool _dependenciesConfigured = false;

@InjectableInit(preferRelativeImports: true)
void configureDependencies() {
  if (!_dependenciesConfigured) {
    getIt.init();
    _dependenciesConfigured = true;
  }
}

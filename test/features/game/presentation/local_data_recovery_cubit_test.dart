import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/audio/audio_service.dart';
import 'package:mafmof/core/errors/local_data_failure.dart';
import 'package:mafmof/features/game/domain/entities/app_settings_entity.dart';
import 'package:mafmof/features/game/domain/entities/case_entity.dart';
import 'package:mafmof/features/game/domain/entities/case_variant_entity.dart';
import 'package:mafmof/features/game/domain/entities/content_visibility_tier.dart';
import 'package:mafmof/features/game/domain/repositories/game_repository.dart';
import 'package:mafmof/features/game/presentation/cubit/game_cubit.dart';
import 'package:mafmof/features/game/presentation/cubit/game_state.dart';

void main() {
  group('GameCubit local-data recovery', () {
    test('bootstrap blocks case entry on first-run seed failure', () async {
      final cubit = GameCubit(
        _FakeGameRepository(
          initializeError: const LocalDataFailure(
            type: LocalDataFailureType.invalidSeed,
            message: 'تعذر تجهيز بيانات القضية المحلية.',
            canRetry: true,
          ),
        ),
        _FakeAudioService(),
      );

      await cubit.bootstrap();

      expect(cubit.state.catalogStatus, CatalogStatus.failure);
      expect(cubit.state.errorMessage, 'تعذر تجهيز بيانات القضية المحلية.');
      expect(cubit.state.canRetryCatalogLoad, isTrue);
      expect(cubit.state.availableCases, isEmpty);
    });

    test('bootstrap preserves fallback catalog on later seed failure', () async {
      final fallbackCases = [
        const CaseEntity(
          id: 'case01_farah_eltagamoa',
          title: 'قضية فرح التجمع',
          subtitle: 'ليلة تتغير فيها الروايات',
          summary: 'ملف غامض يقود المضيف خلال أدلة متصاعدة.',
          coverAssetPath: 'assets/images/case01/cover.webp',
          isActive: true,
          seedVersion: 1,
          supportedPlayerCounts: [5, 6, 7, 8],
        ),
      ];

      final cubit = GameCubit(
        _FakeGameRepository(
          initializeError: const LocalDataFailure(
            type: LocalDataFailureType.invalidSeed,
            message: 'تم الاحتفاظ بآخر نسخة محلية صالحة.',
            canRetry: true,
            hasFallbackCatalog: true,
          ),
          activeCases: fallbackCases,
        ),
        _FakeAudioService(),
      );

      await cubit.bootstrap();

      expect(cubit.state.catalogStatus, CatalogStatus.ready);
      expect(cubit.state.hasFallbackCatalog, isTrue);
      expect(cubit.state.availableCases, hasLength(1));
      expect(cubit.state.errorMessage, 'تم الاحتفاظ بآخر نسخة محلية صالحة.');
    });

    test('unsupported player counts surface a clear setup error', () async {
      final cubit = GameCubit(
        _FakeGameRepository(
          initializeError: null,
          activeCases: const [
            CaseEntity(
              id: 'case01_farah_eltagamoa',
              title: 'قضية فرح التجمع',
              subtitle: 'ليلة تتغير فيها الروايات',
              summary: 'ملف غامض يقود المضيف خلال أدلة متصاعدة.',
              coverAssetPath: 'assets/images/case01/cover.webp',
              isActive: true,
              seedVersion: 1,
              supportedPlayerCounts: [5, 6, 7, 8],
            ),
          ],
          variantError: const LocalDataFailure(
            type: LocalDataFailureType.unsupportedPlayerCount,
            message: 'عدد اللاعبين المدعوم يجب أن يكون بين 5 و8.',
          ),
        ),
        _FakeAudioService(),
      );

      await cubit.bootstrap();
      await cubit.prepareVariantForSetup('case01_farah_eltagamoa', 4);

      expect(cubit.state.catalogStatus, CatalogStatus.ready);
      expect(cubit.state.errorMessage, 'عدد اللاعبين المدعوم يجب أن يكون بين 5 و8.');
      expect(cubit.state.preparedVariant, isNull);
    });
  });
}

class _FakeGameRepository implements GameRepository {
  _FakeGameRepository({
    this.initializeError,
    this.variantError,
    this.activeCases = const [],
  });

  final LocalDataFailure? initializeError;
  final LocalDataFailure? variantError;
  final List<CaseEntity> activeCases;
  static const AppSettingsEntity _settings = AppSettingsEntity(
    id: 1,
    soundEnabled: true,
    soundVolume: 0.7,
  );

  @override
  Future<List<CaseEntity>> getActiveCases() async => activeCases;

  @override
  Future<AppSettingsEntity> getAppSettings() async => _settings;

  @override
  Future<CaseEntity?> getCaseById(String caseId) async {
    for (final item in activeCases) {
      if (item.id == caseId) {
        return item;
      }
    }

    return null;
  }

  @override
  Future<CaseVariantEntity?> getVariantByPlayerCount(
    String caseId,
    int playerCount, {
    ContentVisibilityTier visibility = ContentVisibilityTier.private,
  }) async {
    if (variantError != null) {
      throw variantError!;
    }
    return null;
  }

  @override
  Future<List<CaseVariantEntity>> getVariantsForCase(
    String caseId, {
    ContentVisibilityTier visibility = ContentVisibilityTier.summary,
  }) async {
    return const [];
  }

  @override
  Future<void> initializeLocalCatalog() async {
    if (initializeError != null) {
      throw initializeError!;
    }
  }

  @override
  Future<AppSettingsEntity> updateSoundSettings({
    bool? soundEnabled,
    double? soundVolume,
  }) async {
    return AppSettingsEntity(
      id: _settings.id,
      soundEnabled: soundEnabled ?? _settings.soundEnabled,
      soundVolume: soundVolume ?? _settings.soundVolume,
    );
  }
}

class _FakeAudioService implements AudioService {
  bool _isEnabled = true;
  double _volume = 0.7;

  @override
  bool get isEnabled => _isEnabled;

  @override
  double get volume => _volume;

  @override
  Future<void> playSfx(String key) async {}

  @override
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/constants/database_constants.dart';

void main() {
  test('registers the bundled case catalog under flutter assets', () {
    final lines = File('pubspec.yaml').readAsLinesSync();

    final flutterStart = lines.indexWhere((line) => line == 'flutter:');
    expect(flutterStart, isNonNegative);

    var inAssets = false;
    var foundCaseCatalogDir = false;

    for (final line in lines.skip(flutterStart + 1)) {
      if (line.isNotEmpty && !line.startsWith(' ')) {
        break;
      }
      if (!inAssets) {
        if (line.trim() == 'assets:' && line.startsWith('  ')) {
          inAssets = true;
        }
        continue;
      }
      if (!line.startsWith('    - ')) {
        if (line.trim().isEmpty || line.trimLeft().startsWith('#')) {
          continue;
        }
        break;
      }
      if (line.trim() == '- assets/data/cases/') {
        foundCaseCatalogDir = true;
      }
    }

    expect(foundCaseCatalogDir, isTrue);
  });

  test('registered case seed assets exist on disk', () {
    for (final assetPath in DatabaseConstants.caseSeedAssetPaths) {
      expect(File(assetPath).existsSync(), isTrue, reason: assetPath);
    }
  });
}

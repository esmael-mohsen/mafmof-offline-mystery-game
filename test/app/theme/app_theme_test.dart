import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/app/theme/app_text_styles.dart';
import 'package:mafmof/app/theme/app_theme.dart';

void main() {
  test('dark theme uses bundled local font families', () {
    final theme = AppTheme.dark();

    expect(theme.textTheme.bodyLarge?.fontFamily, 'Cairo');
    expect(theme.textTheme.titleLarge?.fontFamily, 'Cairo');
    expect(theme.textTheme.displaySmall?.fontFamily, 'Cairo');
  });

  testWidgets('special Arabic title styles use local font families',
      (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      AppTextStyles.heroSignatureTitle(capturedContext).fontFamily,
      'Aref Ruqaa Ink',
    );
    expect(
      AppTextStyles.sectionAmiriTitle(capturedContext).fontFamily,
      'Amiri',
    );
  });
}

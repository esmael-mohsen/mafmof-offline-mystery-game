import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/app/theme/app_colors.dart';
import 'package:mafmof/app/theme/app_theme.dart';
import 'package:mafmof/features/game/presentation/widgets/cinematic_button.dart';
import 'package:mafmof/features/game/presentation/widgets/cinematic_card.dart';
import 'package:mafmof/features/game/presentation/widgets/cinematic_screen_shell.dart';

void main() {
  test('dark theme uses the cinematic black and red palette', () {
    final theme = AppTheme.dark();

    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.crimson);
    expect(theme.colorScheme.surface, AppColors.surface);
  });

  testWidgets('cinematic primitives render with shared styling',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const CinematicScreenShell(
          title: 'ماف موف',
          child: CinematicCard(
            child: CinematicButton(
              label: 'ابدأ',
              onPressed: null,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CinematicScreenShell), findsOneWidget);
    expect(find.byType(CinematicCard), findsOneWidget);
    expect(find.byType(CinematicButton), findsOneWidget);
    expect(find.text('ماف موف'), findsOneWidget);
    expect(find.text('ابدأ'), findsOneWidget);
  });
}

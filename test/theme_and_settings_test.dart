import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siqi/core/models/app_models.dart';
import 'package:siqi/core/theme/app_theme.dart';
import 'package:siqi/core/theme/siqi_design.dart';
import 'package:siqi/shared/page_top_bar.dart';

void main() {
  test('foreground awake defaults on and survives settings round trip', () {
    const settings = AppSettings();
    expect(settings.keepScreenAwake, isTrue);
    expect(AppSettings.fromJson({}).keepScreenAwake, isTrue);
    expect(
      AppSettings.fromJson(
        settings.copyWith(keepScreenAwake: false).toJson(),
      ).keepScreenAwake,
      isFalse,
    );
  });
  for (final dark in [false, true]) {
    testWidgets(
      'minimal ${dark ? 'dark' : 'light'} theme and rounded back control',
      (tester) async {
        final theme = dark
            ? AppTheme.dark(const AppSettings())
            : AppTheme.light(const AppSettings());
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        appBar: SiqiPageBar(title: Text('Settings')),
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(BackButton), findsOneWidget);
        expect(find.byType(SiqiTopControl), findsOneWidget);
        expect(SiqiRadius.surface, 20);
        expect(
          theme.colorScheme.onSurface.computeLuminance(),
          dark ? greaterThan(.6) : lessThan(.1),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsOneWidget);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siqi/core/models/app_models.dart';
import 'package:siqi/core/theme/app_theme.dart';
import 'package:siqi/l10n/app_localizations.dart';
import 'package:siqi/ui/chat/input_field.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('320px composer: dark=$dark text=$scale', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = TextEditingController();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark
                ? AppTheme.dark(const AppSettings())
                : AppTheme.light(const AppSettings()),
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: Align(
                    alignment: Alignment.bottomCenter,
                    child: ChatInputField(
                      controller: controller,
                      attachments: const [],
                      multimodal: false,
                      sending: false,
                      cancelling: false,
                      recording: false,
                      transcribing: false,
                      recognizingImage: false,
                      onAttach: () {},
                      onVoice: () {},
                      onOcr: () {},
                      onCamera: () {},
                      onRemove: (_) {},
                      onSend: () {},
                      onStop: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsOneWidget);
        final send = tester.widget<IconButton>(find.byType(IconButton).last);
        expect(send.onPressed, isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }
}

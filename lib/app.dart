import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/models/app_models.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/shell/home_shell.dart';
import 'l10n/app_localizations.dart';

class SiqiApp extends ConsumerWidget {
  const SiqiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = switch (settings.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      locale: settings.localeCode == 'zh_TW'
          ? const Locale('zh', 'TW')
          : Locale(settings.localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: AppTheme.light(settings),
      darkTheme: AppTheme.dark(settings),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(settings.fontScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: settings.onboardingComplete
          ? const HomeShell()
          : const OnboardingPage(),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/models/app_models.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/shell/home_shell.dart';
import 'l10n/app_localizations.dart';

class SiqiApp extends ConsumerStatefulWidget {
  const SiqiApp({super.key});

  @override
  ConsumerState<SiqiApp> createState() => _SiqiAppState();
}

class _SiqiAppState extends ConsumerState<SiqiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Android does not always emit a resumed callback for the first frame.
    // Apply the persisted foreground policy explicitly so a fresh launch is
    // never exposed to the system screen timeout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyKeepAwake());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _applyKeepAwake();
  }

  void _applyKeepAwake() {
    if (!mounted) return;
    final state = WidgetsBinding.instance.lifecycleState;
    final keepAwake =
        ref.read(settingsProvider).keepScreenAwake &&
        (state == null || state == AppLifecycleState.resumed);
    final log = ref.read(appLogServiceProvider);
    unawaited(
      ref.read(platformServiceProvider).setKeepScreenOn(keepAwake).catchError((
        Object error,
      ) {
        unawaited(
          log.warning('screen-awake-policy', error.runtimeType.toString()),
        );
        return false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final settings = ref.watch(settingsProvider);
    ref.listen<bool>(
      settingsProvider.select((value) => value.keepScreenAwake),
      (_, __) => _applyKeepAwake(),
    );
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

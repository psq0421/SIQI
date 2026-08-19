import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({required this.detail, super.key});

  final String detail;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    home: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.appName)),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.startupFailureTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.startupFailureBody),
            const SizedBox(height: 20),
            SelectableText(detail),
          ],
        ),
      ),
    ),
  );
}

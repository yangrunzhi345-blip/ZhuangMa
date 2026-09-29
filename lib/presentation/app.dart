import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'widgets/shell.dart';

class MyApp extends ZhuangMaApp {
  const MyApp({super.key, super.initialLocale});
}

class ZhuangMaApp extends StatelessWidget {
  final Locale? initialLocale;
  const ZhuangMaApp({super.key, this.initialLocale});

  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'ZhuangMa',
    locale: initialLocale ?? const Locale('en'),
    supportedLocales: const [Locale('en'), Locale('zh', 'Hans')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    home: const Shell(),
  );
}

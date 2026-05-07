import 'package:flutter/material.dart';

import 'showcase_app.dart';

void main() {
  runApp(const TurfShowcaseApp());
}

class TurfShowcaseApp extends StatelessWidget {
  const TurfShowcaseApp({super.key});

  static const _seed = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(seedColor: _seed);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'turf_dart Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: lightScheme.surface,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: darkScheme.surface,
      ),
      home: const ShowcaseHome(),
    );
  }
}

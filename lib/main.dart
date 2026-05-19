import 'package:flutter/material.dart';
import 'pages/api_page.dart';

void main() {
  runApp(const TurfShowcaseApp());
}

class TurfShowcaseApp extends StatelessWidget {
  const TurfShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'turf_dart API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFF30363D)),
        ),
      ),
      home: const ApiPage(),
    );
  }
}
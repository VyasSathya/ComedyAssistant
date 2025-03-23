import 'package:flutter/material.dart';
import 'package:comedy_assistant/utils/theme.dart';
import 'package:comedy_assistant/views/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:comedy_assistant/controllers/app_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart' if (dart.library.js) '';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comedy Assistant',
      theme: AppTheme.lightTheme, // Use the theme from theme.dart
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
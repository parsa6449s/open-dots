import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  runApp(OpenDotsApp(config: config));
}

class OpenDotsApp extends StatelessWidget {
  const OpenDotsApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Dots',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.cyan,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => HomeScreen(baseUrl: config.baseUrl),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

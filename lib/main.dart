import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'database/database_helper.dart';
import 'pages/home_page.dart';
import 'repositories/poem_repository.dart';
import 'services/settings_service.dart';
import 'theme/design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DatabaseHelper.initFfi();

  final settingsService = SettingsService();
  await settingsService.loadSettings();

  final repository = PoemRepository();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(393, 852));

    windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(MyApp(
    settingsService: settingsService,
    repository: repository,
  ));
}

class MyApp extends StatelessWidget {
  final SettingsService settingsService;
  final PoemRepository repository;

  const MyApp({
    super.key,
    required this.settingsService,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsService,
      builder: (context, child) {
        final lightColors = AppColors.getThemeColors(
          isDark: false,
          accentIndex: settingsService.accentColorIndex,
        );
        final darkColors = AppColors.getThemeColors(
          isDark: true,
          accentIndex: settingsService.accentColorIndex,
        );

        return MaterialApp(
          title: 'የግጥም መደብ',
          debugShowCheckedModeBanner: false,
          themeMode: settingsService.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: lightColors.background,
            extensions: [lightColors],
            colorScheme: ColorScheme.fromSeed(
              seedColor: lightColors.accent,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: darkColors.background,
            extensions: [darkColors],
            colorScheme: ColorScheme.fromSeed(
              seedColor: darkColors.accent,
              brightness: Brightness.dark,
            ),
          ),
          home: HomePage(
            repository: repository,
            settingsService: settingsService,
          ),
        );
      },
    );
  }
}

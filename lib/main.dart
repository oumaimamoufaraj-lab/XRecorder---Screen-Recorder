import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_config.dart';
import 'controllers/theme_controller.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

final themeController = ThemeController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const NowRecorderApp());
}

class NowRecorderApp extends StatelessWidget {
  const NowRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: themeController,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return MaterialApp(
            title: AppConfig.appDisplayName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

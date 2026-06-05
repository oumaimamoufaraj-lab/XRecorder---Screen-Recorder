import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_config.dart';
import 'controllers/theme_controller.dart';
import 'screens/splash/splash_screen.dart';
import 'services/ads_bootstrap_service.dart';
import 'services/app_open_ad_manager.dart';
import 'theme/app_theme.dart';

final themeController = ThemeController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  await AdsBootstrapService.prefetchConfig();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AzRecorderApp());
}

class AzRecorderApp extends StatefulWidget {
  const AzRecorderApp({super.key});

  @override
  State<AzRecorderApp> createState() => _AzRecorderAppState();
}

class _AzRecorderAppState extends State<AzRecorderApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppOpenAdManager.instance.tryShowOnResume();
    }
  }

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

import 'package:creatorio/app_launcher.dart';
import 'package:creatorio/common/navigator_key.dart';
import 'package:creatorio/common/theme/app_theme.dart';
import 'package:creatorio/common/theme/theme_provider.dart';
import 'package:creatorio/core/network/dio_client.dart';
import 'package:creatorio/features/image/controller/image_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/common/provider/unsplash_provider.dart';
import '/features/auth/controller/auth_controller.dart';
import '/features/auth/controller/profile_controller.dart';
import '/router.dart';
import 'package:creatorio/core/services/analytics_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
    ),
  );
  DioClient.initializeInterceptors();

  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (context) => ProfileController()),
        ChangeNotifierProvider(create: (context) => UnsplashProvider()),
        ChangeNotifierProvider(create: (context) => ImageController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: "Creator.io",
        themeMode: themeProvider.themeMode,
        darkTheme: AppTheme.darkTheme,
        theme: AppTheme.lightTheme,
        onGenerateRoute: onGenerateRoute,
        navigatorObservers: [
          if (AnalyticsService.observer != null) AnalyticsService.observer!
        ],
        home: const AppLauncher(),
      ),
    );
  }
}

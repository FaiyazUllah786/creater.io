import 'package:creatorio/app_launcher.dart';
import 'package:creatorio/common/navigator_key.dart';
import 'package:creatorio/common/theme/app_theme.dart';
import 'package:creatorio/common/theme/theme_provider.dart';
import 'package:creatorio/core/network/dio_client.dart';
import 'package:creatorio/features/Image/controller/image_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '/common/provider/unsplash_provider.dart';
import '/features/auth/controller/user_controller.dart';
import '/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
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
        ChangeNotifierProvider(create: (context) => UserController()),
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
        home: const AppLauncher(),
      ),
    );
  }
}

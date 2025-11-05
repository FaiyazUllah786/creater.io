import 'package:creatorio/features/Image/controller/image_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '/common/provider/unsplash_provider.dart';
import '/common/theme/colors.dart';
import '/common/theme/fonts.dart';
import '/features/auth/controller/tokens_controller.dart';
import '/features/auth/controller/user_controller.dart';
import '/router.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserController()),
        ChangeNotifierProvider(create: (context) => TokensController()),
        ChangeNotifierProvider(create: (context) => UnsplashProvider()),
        ChangeNotifierProvider(create: (context) => ImageController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Creator.io",
        theme: ThemeData(
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            shape: CircleBorder(),
            backgroundColor: whiteColor,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
            foregroundColor: whiteColor,
            backgroundColor: blackColor,
            minimumSize: Size(size.width, 50),
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          )),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: whiteColor,
            foregroundColor: blackColor,
            surfaceTintColor: whiteColor,
            titleTextStyle: TextStyle(
              fontFamily: "Nunito",
              fontSize: 20,
              color: blackColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          scaffoldBackgroundColor: whiteColor,
          textTheme: textTheme,
          bottomSheetTheme:
              const BottomSheetThemeData(backgroundColor: whiteColor),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: whiteColor,
            selectedItemColor: blackColor,
            unselectedItemColor: blackColor,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
          ),
        ),
        onGenerateRoute: onGenerateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}

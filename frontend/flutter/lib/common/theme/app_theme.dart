import 'package:flutter/material.dart';
import 'colors.dart';
import 'fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    iconTheme: IconThemeData(color: blackColor),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: CircleBorder(),
      backgroundColor: whiteColor,
      foregroundColor: blackColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: whiteColor,
        backgroundColor: blackColor,
        textStyle: const TextStyle(fontSize: 16, color: whiteColor),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      leadingWidth: 30,
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
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: whiteColor,
      shape: ContinuousRectangleBorder(
        side: BorderSide(color: blackColor, width: 2),
        borderRadius: BorderRadiusGeometry.only(
            topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: whiteColor,
      selectedItemColor: brownColor,
      unselectedItemColor: greyColor,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: whiteColor),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(
        color: blackColor,
      ),
      floatingLabelStyle: TextStyle(
        color: blackColor,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide(
          color: Color(0xFFBFC9D1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        borderSide: BorderSide(
          color: blackColor,
          width: 2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: whiteColor,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    // Main background
    scaffoldBackgroundColor: oledBlack,

    iconTheme: IconThemeData(color: whiteColor),

    // AppBar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      leadingWidth: 30,
      backgroundColor: oledBlack,
      foregroundColor: primaryTextDark,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: "Nunito",
        fontSize: 20,
        color: primaryTextDark,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Floating Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: CircleBorder(),
      backgroundColor: blackColor,
      foregroundColor: primaryTextDark,
      elevation: 8,
    ),
    // Bottom Navigation

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: glassBlack,
      selectedItemColor: brownColor,
      unselectedItemColor: blackColor,
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: blackColor,
        backgroundColor: primaryTextDark,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    ),

    // Text Theme
    textTheme: textTheme.apply(
      bodyColor: primaryTextDark,
      displayColor: primaryTextDark,
    ),

    // Bottom Sheet (Glassy Dark)
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: glassBlack,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: glassBlack,
      shape: ContinuousRectangleBorder(
        side: BorderSide(
          color: borderDark,
          width: 1.5,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: cardBlack,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: borderDark,
        ),
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: cardBlack,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: borderDark,
        ),
      ),
    ),

    // Input Fields
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: glassBlack,
      labelStyle: TextStyle(
        color: secondaryTextDark,
      ),
      floatingLabelStyle: TextStyle(
        color: primaryTextDark,
      ),
      hintStyle: TextStyle(
        color: secondaryTextDark,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(30),
        ),
        borderSide: BorderSide(
          color: borderDark,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(30),
        ),
        borderSide: BorderSide(
          color: primaryTextDark,
          width: 1.5,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(30),
        ),
      ),
    ),

    // Divider
    dividerColor: borderDark,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: primaryTextDark,
      secondary: secondaryTextDark,
      surface: cardBlack,
      onPrimary: blackColor,
      onSurface: primaryTextDark,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: blackColor,
    ),
  );
}

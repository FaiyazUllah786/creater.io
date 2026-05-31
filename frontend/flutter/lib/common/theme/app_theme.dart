import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    iconTheme: IconThemeData(color: blackColor),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: CircleBorder(),
      backgroundColor: brownColor,
      foregroundColor: whiteColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        fixedSize: Size(double.maxFinite, 50),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
      centerTitle: false,
    ),
    scaffoldBackgroundColor: whiteColor,
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      headlineLarge: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        color: greyColor,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: whiteColor,
      modalBackgroundColor: whiteColor,
      shape: ContinuousRectangleBorder(
        side: BorderSide(color: blackColor, width: 2),
        borderRadius: BorderRadiusGeometry.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 10,
      backgroundColor: whiteColor,
      selectedItemColor: brownColor,
      unselectedItemColor: blackColor,
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
      color: whiteColor,
      shadowColor: blackColor,
      elevation: 10,
      height: 60,
      padding: EdgeInsets.all(0),
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
    ),

    // Floating Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: CircleBorder(),
      backgroundColor: brownColor,
      foregroundColor: whiteColor,
      elevation: 8,
    ),
    // Bottom Navigation

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: glassBlack,
      selectedItemColor: brownColor,
      unselectedItemColor: whiteColor,
    ),

    bottomAppBarTheme: BottomAppBarThemeData(
      color: glassBlack,
      shadowColor: whiteColor,
      elevation: 10,
      height: 60,
      padding: EdgeInsets.all(0),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        fixedSize: Size(double.maxFinite, 50),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        foregroundColor: whiteColor,
        backgroundColor: blackColor,
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
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      headlineLarge: GoogleFonts.poppins(
        color: whiteColor,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: GoogleFonts.poppins(
        color: whiteColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.poppins(
        color: whiteColor,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      labelMedium: GoogleFonts.poppins(
        color: whiteColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.poppins(
        color: whiteColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: GoogleFonts.poppins(
        color: whiteColor,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        color: greyColor,
      ),
    ),

    // // Bottom Sheet (Glassy Dark)
    // bottomSheetTheme: const BottomSheetThemeData(
    //   surfaceTintColor: Colors.transparent,
    //   modalBackgroundColor: glassBlack,
    //   shape: ContinuousRectangleBorder(
    //     side: BorderSide(
    //       color: borderDark,
    //       width: 1.5,
    //     ),
    //     borderRadius: BorderRadius.only(
    //       topLeft: Radius.circular(32),
    //       topRight: Radius.circular(32),
    //     ),
    //   ),
    // ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: glassBlack,
      modalBackgroundColor: oledBlack,
      shape: ContinuousRectangleBorder(
        side: BorderSide(color: whiteColor, width: 2),
        borderRadius: BorderRadiusGeometry.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
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
      backgroundColor: oledBlack,
    ),
  );
}

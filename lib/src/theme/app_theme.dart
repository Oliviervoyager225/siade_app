import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const lightBackground = Color(0xffFFFFFF);
  static const lightPrimary = Color(0xff1976D2);
  static const lightSecondary = Color(0xff42A5F5);
  static const lightAccent = Color(0xffEF5350);
  static const lightCardBg = Color(0xffF5F5F5);
  static const lightTextPrimary = Color(0xff1A1A1A);
  static const lightTextSecondary = Color(0xff757575);
  
  // Dark Theme Colors (votre thème actuel)
  static const darkBackground = Color(0xff040126);
  static const darkPrimary = Color(0xff07026F);
  static const darkSecondary = Color(0xff2E8AF6);
  static const darkAccent = Color(0xffA01E38);
  static const darkCardBg = Color(0xff1F0D68);
  static const darkTextPrimary = Color(0xffFFFFFF);
  static const darkTextSecondary = Color(0xffA995CE);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: lightPrimary,
    colorScheme: ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightCardBg,
      error: lightAccent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: lightCardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: lightTextPrimary),
      bodyMedium: TextStyle(color: lightTextSecondary),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: darkPrimary,
    colorScheme: ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkCardBg,
      error: darkAccent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: darkTextPrimary),
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: darkTextPrimary),
      bodyMedium: TextStyle(color: darkTextSecondary),
    ),
  );
}


import 'package:flutter/material.dart';

ThemeData buildTheme() {
  return ThemeData(
    primaryColor: const Color.fromARGB(255, 39, 123, 43), 
    scaffoldBackgroundColor: Colors.green[50], 
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 139, 192, 142), 
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
      displayLarge: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white, 
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.green[300]!, 
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.green[600]!, 
        ),
      ),
      labelStyle: TextStyle(
        color: Colors.green[800], 
        fontSize: 16,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[600], 
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, 
        backgroundColor: Colors.green[600], 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), 
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), 
      ),
    ),
    colorScheme: ColorScheme(
      primary: Colors.green[600]!, 
      secondary: Colors.brown[300]!, 
      surface: Colors.white,
      error: Colors.redAccent, 
      onPrimary: Colors.white, 
      onSecondary: Colors.black, 
      onSurface: Colors.black, 
      onError: Colors.white, 
      brightness: Brightness.light, 
    ),
    iconTheme: IconThemeData(
      color: Colors.green[800]!,
      size: 24,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.green[600]!, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

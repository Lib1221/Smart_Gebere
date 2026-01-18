import 'package:flutter/material.dart';

class TColor {
  // Define the light color
  TColor._();

  //App basic colors
  static const Color primary = Colors.blue;
  static const Color secondary = Color(0xFFFFE24B);
  static const Color accent = Color(0xFFb0c7ff);

  // gradient colors
  static const Gradient linearGradient = LinearGradient(
    colors: [Color(0xFFFF9a9e), Color(0xFFFAD0C4), Color(0xFFFAD0C4)],
    begin: Alignment(0.0, 0.0),
    end: Alignment(0.707, -0.707),
  );

  // Text colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textWhite = Colors.white;

  // Background colors
  static const Color light = Color(0xFFF5F5F5);
  static const Color dark = Color(0xFF1E1E1E);
  static const Color primaryBackground = Color(0xFFF3F5FF);

  //background container colors
  static const Color containerLight = Color(0xFFF6F6F6);
  static Color containerDark = TColor.white.withOpacity(0.1);

  static var white = Colors.white;

  //button colors
  static const Color buttonPrimary = Color(0xFF4b68ff);
  static const Color buttonSecondary = Color(0xFF6c7570);
  static const Color buttonDisabled = Color(0xFFC4C4C4);

  //border colors
  static const Color borderPrimary = Color(0xFFD9D9D9);
  static const Color borderSecondary = Color(0xFFE6E6E6);

  // Error and validation Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
}

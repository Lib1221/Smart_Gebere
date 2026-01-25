// lib/controller/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static ThemeController get instance => Get.find();
  
  final _themeMode = Rx<ThemeMode>(ThemeMode.system);
  late SharedPreferences _prefs;
  
  Future<ThemeController> init() async {
    _prefs = await SharedPreferences.getInstance();
    loadThemeMode();
    return this;
  }
  
  void loadThemeMode() {
    final savedThemeMode = _prefs.getString('themeMode');
    
    if (savedThemeMode != null) {
      switch (savedThemeMode) {
        case 'light':
          _themeMode.value = ThemeMode.light;
          break;
        case 'dark':
          _themeMode.value = ThemeMode.dark;
          break;
        default:
          _themeMode.value = ThemeMode.system;
      }
    }
  }
  
  ThemeMode getThemeMode() {
    return _themeMode.value;
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    
    // Save preference
    await _prefs.setString('themeMode', mode.toString().split('.').last);
    
    // Update the app theme
    Get.changeThemeMode(mode);
    update();
  }
  
  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode.value == ThemeMode.dark;
  }
  
  String get currentThemeText {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
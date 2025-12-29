import 'package:flutter/material.dart';
import 'package:smart_gebere/settings/locale_store.dart';

class AppSettings extends ChangeNotifier {
  Locale _locale;
  Locale get locale => _locale;

  AppSettings({Locale? initialLocale}) : _locale = initialLocale ?? const Locale('en');

  static Future<AppSettings> load() async {
    try {
      final store = getLocaleStore();
      final code = normalizeLocaleCode(await store.readLocaleCode());
      return AppSettings(initialLocale: Locale(code));
    } catch (_) {
      // If storage fails for any reason, default to English.
      return AppSettings(initialLocale: const Locale('en'));
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    try {
      final store = getLocaleStore();
      await store.writeLocaleCode(normalizeLocaleCode(locale.languageCode));
    } catch (_) {
      // ignore storage errors; locale will still work for the current session
    }
  }

  /// Human-readable language name used for AI prompt instruction.
  /// (We keep it simple so the model follows it reliably.)
  String aiLanguageName() {
    switch (_locale.languageCode) {
      case 'am':
        return 'Amharic';
      case 'om':
        return 'Afaan Oromo';
      default:
        return 'English';
    }
  }
}



import 'package:flutter/foundation.dart';

import 'locale_store_stub.dart'
    if (dart.library.html) 'locale_store_web.dart'
    if (dart.library.io) 'locale_store_io.dart';

/// Small abstraction so locale persistence works on Web + Mobile.
/// - Web: window.localStorage
/// - Mobile/Desktop: SharedPreferences
abstract class LocaleStore {
  Future<String?> readLocaleCode();
  Future<void> writeLocaleCode(String code);
}

LocaleStore getLocaleStore() => LocaleStoreImpl();

String normalizeLocaleCode(String? code) {
  final c = (code ?? '').trim();
  if (c.isEmpty) return 'en';
  // Only allow our supported language codes.
  if (c == 'en' || c == 'am' || c == 'om') return c;
  return 'en';
}

const kLocaleStorageKey = 'app_locale';



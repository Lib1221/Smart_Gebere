import 'package:shared_preferences/shared_preferences.dart';

import 'locale_store.dart';

class LocaleStoreImpl implements LocaleStore {
  @override
  Future<String?> readLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kLocaleStorageKey);
  }

  @override
  Future<void> writeLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLocaleStorageKey, code);
  }
}



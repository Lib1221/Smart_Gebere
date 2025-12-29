import 'dart:html' as html;

import 'locale_store.dart';

class LocaleStoreImpl implements LocaleStore {
  @override
  Future<String?> readLocaleCode() async {
    try {
      return html.window.localStorage[kLocaleStorageKey];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeLocaleCode(String code) async {
    try {
      html.window.localStorage[kLocaleStorageKey] = code;
    } catch (_) {
      // ignore
    }
  }
}



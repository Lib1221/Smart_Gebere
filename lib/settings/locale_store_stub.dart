import 'locale_store.dart';

/// Fallback implementation used for unsupported platforms in this build.
class LocaleStoreImpl implements LocaleStore {
  String? _memory;

  @override
  Future<String?> readLocaleCode() async => _memory;

  @override
  Future<void> writeLocaleCode(String code) async {
    _memory = code;
  }
}



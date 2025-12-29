import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Simple in-repo localization (no code generation).
/// Supports: English (en), Amharic (am), Afaan Oromo (om).
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(loc != null, 'AppLocalizations not found in widget tree');
    return loc!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('am'),
    Locale('om'),
  ];

  String get _lang => locale.languageCode;

  String _t(String key) {
    return (_values[_lang] ?? _values['en']!)[key] ?? _values['en']![key] ?? key;
  }

  // Strings used in UI
  String get appName => _t('appName');
  String get logout => _t('logout');
  String get settings => _t('settings');
  String get confirmLogoutTitle => _t('confirmLogoutTitle');
  String get confirmLogoutBody => _t('confirmLogoutBody');
  String get cancel => _t('cancel');
  String get createTask => _t('createTask');
  String get createdTasks => _t('createdTasks');
  String get expectedEvents => _t('expectedEvents');

  String get welcomeToApp => _t('welcomeToApp');
  String get tagline => _t('tagline');
  String get createAccount => _t('createAccount');
  String get firstName => _t('firstName');
  String get lastName => _t('lastName');
  String get country => _t('country');
  String get phoneNumber => _t('phoneNumber');
  String get email => _t('email');
  String get password => _t('password');
  String get confirmPassword => _t('confirmPassword');
  String get signUp => _t('signUp');
  String get alreadyHaveAccount => _t('alreadyHaveAccount');
  String get login => _t('login');
  String get dontHaveAccount => _t('dontHaveAccount');

  String get language => _t('language');
  String get languageEnglish => _t('languageEnglish');
  String get languageAmharic => _t('languageAmharic');
  String get languageAfanOromo => _t('languageAfanOromo');
  String get save => _t('save');

  String get noCropData => _t('noCropData');
  String get lookSchedule => _t('lookSchedule');
  String get diseaseDetection => _t('diseaseDetection');
  String get fileManager => _t('fileManager');
  String get camera => _t('camera');
  String get detect => _t('detect');
  String get week => _t('week');
  String get days => _t('days');
  String get noCropsFound => _t('noCropsFound');
  String get plantingGuide => _t('plantingGuide');
  String get plantIt => _t('plantIt');
  String get plantItQuestionTitle => _t('plantItQuestionTitle');
  String get plantItQuestionBody => _t('plantItQuestionBody');
  String get agree => _t('agree');
  String get disagree => _t('disagree');
  String get ok => _t('ok');
  String get uploadingPleaseWait => _t('uploadingPleaseWait');
  String get uploadSuccessTitle => _t('uploadSuccessTitle');
  String get uploadFailedTitle => _t('uploadFailedTitle');

  String aiRespondIn(String language) {
    final template = _t('aiRespondIn');
    return template.replaceAll('{language}', language);
  }

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'appName': 'Smart Gebere',
      'logout': 'Logout',
      'settings': 'Settings',
      'confirmLogoutTitle': 'Confirm Logout',
      'confirmLogoutBody': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
      'createTask': 'Create Task',
      'createdTasks': 'Created Tasks',
      'expectedEvents': 'Expected Events',
      'welcomeToApp': 'Welcome to Smart Gebere',
      'tagline': 'Empowering Farmers with Smart Solutions',
      'createAccount': 'Create Account',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'country': 'Country',
      'phoneNumber': 'Phone Number',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'signUp': 'Sign Up',
      'alreadyHaveAccount': 'Already have an account?',
      'login': 'Login',
      'dontHaveAccount': "Don't have an account?",
      'language': 'Language',
      'languageEnglish': 'English',
      'languageAmharic': 'Amharic',
      'languageAfanOromo': 'Afaan Oromo',
      'save': 'Save',
      'noCropData': 'No crop data available.',
      'lookSchedule': 'Look Schedule',
      'diseaseDetection': 'Disease Detection',
      'fileManager': 'File Manager',
      'camera': 'Camera',
      'detect': 'Detect',
      'week': 'Week',
      'days': 'Days',
      'noCropsFound': 'No crops found. Please add crops.',
      'plantingGuide': 'Planting Guide',
      'plantIt': 'Plant It',
      'plantItQuestionTitle': 'Plant It?',
      'plantItQuestionBody': 'Do you agree to proceed with planting this crop?',
      'agree': 'Agree',
      'disagree': 'Disagree',
      'ok': 'OK',
      'uploadingPleaseWait': 'Uploading data... Please wait',
      'uploadSuccessTitle': 'Success ✅',
      'uploadFailedTitle': 'Upload Failed ❌',
      'aiRespondIn': 'Respond in {language}.',
    },
    'am': {
      'appName': 'ስማርት ገበሬ',
      'logout': 'ውጣ',
      'settings': 'ቅንብሮች',
      'confirmLogoutTitle': 'መውጣት አረጋግጥ',
      'confirmLogoutBody': 'በእርግጥ መውጣት ትፈልጋለህ?',
      'cancel': 'ሰርዝ',
      'createTask': 'ተግባር ፍጠር',
      'createdTasks': 'የተፈጠሩ ተግባሮች',
      'expectedEvents': 'የሚጠበቁ ክስተቶች',
      'welcomeToApp': 'እንኳን ወደ ስማርት ገበሬ በደህና መጣህ',
      'tagline': 'ገበሬዎችን በስማርት መፍትሄዎች ማበረታታት',
      'createAccount': 'መለያ ፍጠር',
      'firstName': 'ስም',
      'lastName': 'የአባት ስም',
      'country': 'ሀገር',
      'phoneNumber': 'ስልክ ቁጥር',
      'email': 'ኢሜይል',
      'password': 'የይለፍ ቃል',
      'confirmPassword': 'የይለፍ ቃል አረጋግጥ',
      'signUp': 'ይመዝገቡ',
      'alreadyHaveAccount': 'መለያ አለህ?',
      'login': 'ግባ',
      'dontHaveAccount': 'መለያ የለህም?',
      'language': 'ቋንቋ',
      'languageEnglish': 'እንግሊዝኛ',
      'languageAmharic': 'አማርኛ',
      'languageAfanOromo': 'አፋን ኦሮሞ',
      'save': 'አስቀምጥ',
      'noCropData': 'የሰብል መረጃ አልተገኘም።',
      'lookSchedule': 'መርሃ ግብር ተመልከት',
      'diseaseDetection': 'የበሽታ ምርመራ',
      'fileManager': 'ፋይል አስተዳዳሪ',
      'camera': 'ካሜራ',
      'detect': 'ምርመራ',
      'week': 'ሳምንት',
      'days': 'ቀኖች',
      'noCropsFound': 'ሰብል አልተገኘም። እባክዎ ሰብሎችን ያክሉ።',
      'plantingGuide': 'የመተከል መመሪያ',
      'plantIt': 'ተክል',
      'plantItQuestionTitle': 'ተክል?',
      'plantItQuestionBody': 'ይህን ሰብል ለመተከል መቀጠል ትስማማለህ?',
      'agree': 'እስማማለሁ',
      'disagree': 'አልስማማም',
      'ok': 'እሺ',
      'uploadingPleaseWait': 'ውሂብ በመስቀል ላይ... እባክዎ ይጠብቁ',
      'uploadSuccessTitle': 'ተሳክቷል ✅',
      'uploadFailedTitle': 'መስቀል አልተሳካም ❌',
      'aiRespondIn': 'በ{language} ቋንቋ መልስ።',
    },
    'om': {
      'appName': 'Smart Gebere',
      'logout': "Ba'i",
      'settings': "Qindaa'ina",
      'confirmLogoutTitle': "Ba'uu Mirkaneessi",
      'confirmLogoutBody': "Dhugumaan keessaa ba'uu barbaaddaa?",
      'cancel': 'Haqi',
      'createTask': 'Hojii Uumi',
      'createdTasks': 'Hojii Uumaman',
      'expectedEvents': 'Taateewwan Eegaman',
      'welcomeToApp': 'Baga nagaan gara Smart Gebere dhuftan',
      'tagline': "Qonnaan bultoota furmaata smart ta'een jabeessuu",
      'createAccount': 'Herrega Uumi',
      'firstName': 'Maqaa',
      'lastName': 'Maqaa Abbaa',
      'country': 'Biyya',
      'phoneNumber': 'Lakkoofsa Bilbilaa',
      'email': 'Iimeelii',
      'password': 'Jecha Darbii',
      'confirmPassword': 'Jecha Darbii Mirkaneessi',
      'signUp': "Galmaa'i",
      'alreadyHaveAccount': 'Herrega qabdaa?',
      'login': 'Seeni',
      'dontHaveAccount': 'Herrega hin qabduu?',
      'language': 'Afaan',
      'languageEnglish': 'English',
      'languageAmharic': 'Afaan Amaaraa',
      'languageAfanOromo': 'Afaan Oromo',
      'save': "Olkaa'i",
      'noCropData': 'Odeeffannoon midhaanii hin jiru.',
      'lookSchedule': 'Sagantaa Ilaali',
      'diseaseDetection': 'Sakatta’iinsa Dhukkuba',
      'fileManager': 'Faayila Filadhu',
      'camera': 'Kaameraa',
      'detect': "Sakatta'i",
      'week': 'Torban',
      'days': 'Guyyoota',
      'noCropsFound': 'Midhaan hin argamne. Mee midhaan dabaluu.',
      'plantingGuide': 'Qajeelfama Dhaabbii',
      'plantIt': 'Dhaabi',
      'plantItQuestionTitle': 'Dhaabi?',
      'plantItQuestionBody': 'Midhaan kana dhaabuuf itti fufuu irratti walii galaa?',
      'agree': 'Eeyyee',
      'disagree': "Lakki",
      'ok': 'TOLE',
      'uploadingPleaseWait': 'Odeeffannoo olkaa\'aa jira... Mee eegi',
      'uploadSuccessTitle': 'Milkaa\'e ✅',
      'uploadFailedTitle': 'Olkaa\'uun hin milkoofne ❌',
      'aiRespondIn': 'Afaan {language}tiin deebisi.',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}



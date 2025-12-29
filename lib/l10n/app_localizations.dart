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
  String get profileSaved => _t('profileSaved');

  // Farm Profile
  String get farmProfile => _t('farmProfile');
  String get basicInfo => _t('basicInfo');
  String get farmerName => _t('farmerName');
  String get location => _t('location');
  String get region => _t('region');
  String get zone => _t('zone');
  String get woreda => _t('woreda');
  String get kebele => _t('kebele');
  String get farmDetails => _t('farmDetails');
  String get farmSizeHectares => _t('farmSizeHectares');
  String get soilType => _t('soilType');
  String get irrigationType => _t('irrigationType');
  String get hasWaterAccess => _t('hasWaterAccess');
  String get farmingPractice => _t('farmingPractice');
  String get farmingType => _t('farmingType');
  String get subsistence => _t('subsistence');
  String get commercial => _t('commercial');
  String get mixed => _t('mixed');
  String get experience => _t('experience');
  String get usesChemicalFertilizers => _t('usesChemicalFertilizers');
  String get usesOrganic => _t('usesOrganic');
  String get crops => _t('crops');
  String get currentCrops => _t('currentCrops');
  String get preferredCrops => _t('preferredCrops');
  String get equipment => _t('equipment');
  String get availableEquipment => _t('availableEquipment');
  String get marketAccess => _t('marketAccess');
  String get nearestMarket => _t('nearestMarket');
  String get distanceToMarketKm => _t('distanceToMarketKm');
  String get hasTransport => _t('hasTransport');
  String get saveProfile => _t('saveProfile');

  // Market Prices
  String get marketPrices => _t('marketPrices');
  String get currentPrices => _t('currentPrices');
  String get priceHistory => _t('priceHistory');
  String get sellRecommendation => _t('sellRecommendation');
  String get getRecommendation => _t('getRecommendation');

  // Weather
  String get weatherAdvisor => _t('weatherAdvisor');
  String get currentWeather => _t('currentWeather');
  String get humidity => _t('humidity');
  String get rain => _t('rain');
  String get wind => _t('wind');
  String get weatherAlerts => _t('weatherAlerts');
  String get farmingAdvice => _t('farmingAdvice');
  String get sevenDayForecast => _t('sevenDayForecast');
  String get today => _t('today');

  // Farm Records
  String get farmRecords => _t('farmRecords');
  String get records => _t('records');
  String get analytics => _t('analytics');
  String get summary => _t('summary');
  String get addRecord => _t('addRecord');
  String get noRecords => _t('noRecords');
  String get tapToAddRecord => _t('tapToAddRecord');
  String get recordType => _t('recordType');
  String get crop => _t('crop');
  String get description => _t('description');
  String get amount => _t('amount');
  String get category => _t('category');
  String get quantity => _t('quantity');
  String get date => _t('date');
  String get notes => _t('notes');
  String get required => _t('required');
  String get totalExpenses => _t('totalExpenses');
  String get totalIncome => _t('totalIncome');
  String get netProfit => _t('netProfit');
  String get laborHours => _t('laborHours');
  String get incomeByMonth => _t('incomeByMonth');
  String get harvestByCrop => _t('harvestByCrop');
  String get expensesByCategory => _t('expensesByCategory');
  String get noDataForAnalytics => _t('noDataForAnalytics');

  // Knowledge Base
  String get knowledgeBase => _t('knowledgeBase');
  String get searchArticles => _t('searchArticles');
  String get all => _t('all');
  String get noArticlesFound => _t('noArticlesFound');

  // Privacy
  String get privacySettings => _t('privacySettings');
  String get dataCollection => _t('dataCollection');
  String get usageAnalytics => _t('usageAnalytics');
  String get usageAnalyticsDesc => _t('usageAnalyticsDesc');
  String get locationAccess => _t('locationAccess');
  String get locationAccessDesc => _t('locationAccessDesc');
  String get dataSharing => _t('dataSharing');
  String get dataSharingDesc => _t('dataSharingDesc');
  String get offlineMode => _t('offlineMode');
  String get offlineModeOnly => _t('offlineModeOnly');
  String get offlineModeOnlyDesc => _t('offlineModeOnlyDesc');
  String get syncStatus => _t('syncStatus');
  String get online => _t('online');
  String get offline => _t('offline');
  String get dataManagement => _t('dataManagement');
  String get exportData => _t('exportData');
  String get exportDataDesc => _t('exportDataDesc');
  String get clearLocalData => _t('clearLocalData');
  String get clearLocalDataDesc => _t('clearLocalDataDesc');
  String get deleteAccount => _t('deleteAccount');
  String get deleteAccountDesc => _t('deleteAccountDesc');
  String get deleteAccountWarning => _t('deleteAccountWarning');
  String get clear => _t('clear');
  String get clearLocalDataConfirm => _t('clearLocalDataConfirm');
  String get localDataCleared => _t('localDataCleared');
  String get exportingData => _t('exportingData');
  String get dataExported => _t('dataExported');
  String get errorDeletingAccount => _t('errorDeletingAccount');
  String get consentInfo => _t('consentInfo');
  String get dataWeCollect => _t('dataWeCollect');
  String get profileInfo => _t('profileInfo');
  String get locationData => _t('locationData');
  String get farmData => _t('farmData');
  String get usageData => _t('usageData');
  String get howWeUseData => _t('howWeUseData');
  String get dataUsageDesc => _t('dataUsageDesc');
  String get privacyPolicy => _t('privacyPolicy');
  String get termsOfService => _t('termsOfService');
  String get close => _t('close');

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
      'profileSaved': 'Profile saved successfully!',
      'farmProfile': 'Farm Profile',
      'basicInfo': 'Basic Information',
      'farmerName': 'Farmer Name',
      'location': 'Location',
      'region': 'Region',
      'zone': 'Zone',
      'woreda': 'Woreda',
      'kebele': 'Kebele',
      'farmDetails': 'Farm Details',
      'farmSizeHectares': 'Farm Size (Hectares)',
      'soilType': 'Soil Type',
      'irrigationType': 'Irrigation Type',
      'hasWaterAccess': 'Has Water Access',
      'farmingPractice': 'Farming Practice',
      'farmingType': 'Farming Type',
      'subsistence': 'Subsistence',
      'commercial': 'Commercial',
      'mixed': 'Mixed',
      'experience': 'Experience',
      'usesChemicalFertilizers': 'Uses Chemical Fertilizers',
      'usesOrganic': 'Uses Organic Methods',
      'crops': 'Crops',
      'currentCrops': 'Current Crops',
      'preferredCrops': 'Preferred Crops',
      'equipment': 'Equipment',
      'availableEquipment': 'Available Equipment',
      'marketAccess': 'Market Access',
      'nearestMarket': 'Nearest Market',
      'distanceToMarketKm': 'Distance to Market (km)',
      'hasTransport': 'Has Transport',
      'saveProfile': 'Save Profile',
      'marketPrices': 'Market Prices',
      'currentPrices': 'Current Prices',
      'priceHistory': 'Price History',
      'sellRecommendation': 'Sell Recommendation',
      'getRecommendation': 'Get Recommendation',
      'weatherAdvisor': 'Weather Advisor',
      'currentWeather': 'Current Weather',
      'humidity': 'Humidity',
      'rain': 'Rain',
      'wind': 'Wind',
      'weatherAlerts': 'Weather Alerts',
      'farmingAdvice': 'Farming Advice',
      'sevenDayForecast': '7-Day Forecast',
      'today': 'Today',
      'farmRecords': 'Farm Records',
      'records': 'Records',
      'analytics': 'Analytics',
      'summary': 'Summary',
      'addRecord': 'Add Record',
      'noRecords': 'No records yet',
      'tapToAddRecord': 'Tap + to add your first record',
      'recordType': 'Record Type',
      'crop': 'Crop',
      'description': 'Description',
      'amount': 'Amount',
      'category': 'Category',
      'quantity': 'Quantity',
      'date': 'Date',
      'notes': 'Notes',
      'required': 'This field is required',
      'totalExpenses': 'Total Expenses',
      'totalIncome': 'Total Income',
      'netProfit': 'Net Profit',
      'laborHours': 'Labor Hours',
      'incomeByMonth': 'Income by Month',
      'harvestByCrop': 'Harvest by Crop',
      'expensesByCategory': 'Expenses by Category',
      'noDataForAnalytics': 'No data for analytics',
      'knowledgeBase': 'Knowledge Base',
      'searchArticles': 'Search articles...',
      'all': 'All',
      'noArticlesFound': 'No articles found',
      'privacySettings': 'Privacy & Data',
      'dataCollection': 'Data Collection',
      'usageAnalytics': 'Usage Analytics',
      'usageAnalyticsDesc': 'Help improve the app with anonymous usage data',
      'locationAccess': 'Location Access',
      'locationAccessDesc': 'Used for weather and crop recommendations',
      'dataSharing': 'Data Sharing',
      'dataSharingDesc': 'Share anonymized data for research',
      'offlineMode': 'Offline Mode',
      'offlineModeOnly': 'Offline Mode Only',
      'offlineModeOnlyDesc': 'Never sync data to cloud',
      'syncStatus': 'Sync Status',
      'online': 'Online',
      'offline': 'Offline',
      'dataManagement': 'Data Management',
      'exportData': 'Export My Data',
      'exportDataDesc': 'Download all your farm data',
      'clearLocalData': 'Clear Local Cache',
      'clearLocalDataDesc': 'Remove cached data from device',
      'deleteAccount': 'Delete Account',
      'deleteAccountDesc': 'Permanently delete account and all data',
      'deleteAccountWarning': 'This action cannot be undone!',
      'clear': 'Clear',
      'clearLocalDataConfirm': 'This will clear all cached data. Continue?',
      'localDataCleared': 'Local cache cleared',
      'exportingData': 'Exporting your data...',
      'dataExported': 'Data exported successfully',
      'errorDeletingAccount': 'Error deleting account',
      'consentInfo': 'Data & Consent Information',
      'dataWeCollect': 'Data We Collect',
      'profileInfo': 'Profile information',
      'locationData': 'Location data',
      'farmData': 'Farm and crop data',
      'usageData': 'App usage data',
      'howWeUseData': 'How We Use Your Data',
      'dataUsageDesc': 'We use your data to provide personalized crop recommendations, weather alerts, and improve our AI models. Your data is stored securely and never sold to third parties.',
      'privacyPolicy': 'Privacy Policy',
      'termsOfService': 'Terms of Service',
      'close': 'Close',
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
      'profileSaved': 'መገለጫ በተሳካ ሁኔታ ተቀምጧል!',
      'farmProfile': 'የእርሻ መገለጫ',
      'basicInfo': 'መሰረታዊ መረጃ',
      'farmerName': 'የገበሬው ስም',
      'location': 'አካባቢ',
      'region': 'ክልል',
      'zone': 'ዞን',
      'woreda': 'ወረዳ',
      'kebele': 'ቀበሌ',
      'farmDetails': 'የእርሻ ዝርዝሮች',
      'farmSizeHectares': 'የእርሻ መጠን (ሄክታር)',
      'soilType': 'የአፈር አይነት',
      'irrigationType': 'የመስኖ አይነት',
      'hasWaterAccess': 'የውሃ መዳረሻ አለው',
      'farmingPractice': 'የእርሻ ልማድ',
      'farmingType': 'የእርሻ ዓይነት',
      'subsistence': 'ለራስ ፍጆታ',
      'commercial': 'ንግድ',
      'mixed': 'ድብልቅ',
      'experience': 'ልምድ',
      'usesChemicalFertilizers': 'ኬሚካል ማዳበሪያ ይጠቀማል',
      'usesOrganic': 'ኦርጋኒክ ዘዴዎችን ይጠቀማል',
      'crops': 'ሰብሎች',
      'currentCrops': 'ወቅታዊ ሰብሎች',
      'preferredCrops': 'ተመራጭ ሰብሎች',
      'equipment': 'መሳሪያዎች',
      'availableEquipment': 'ያሉ መሳሪያዎች',
      'marketAccess': 'የገበያ መዳረሻ',
      'nearestMarket': 'ቅርብ ገበያ',
      'distanceToMarketKm': 'ወደ ገበያ ርቀት (ኪ.ሜ)',
      'hasTransport': 'ትራንስፖርት አለው',
      'saveProfile': 'መገለጫ አስቀምጥ',
      'marketPrices': 'የገበያ ዋጋዎች',
      'currentPrices': 'ወቅታዊ ዋጋዎች',
      'priceHistory': 'የዋጋ ታሪክ',
      'sellRecommendation': 'የሽያጭ ምክር',
      'getRecommendation': 'ምክር አግኝ',
      'weatherAdvisor': 'የአየር ሁኔታ አማካሪ',
      'currentWeather': 'ወቅታዊ የአየር ሁኔታ',
      'humidity': 'እርጥበት',
      'rain': 'ዝናብ',
      'wind': 'ነፋስ',
      'weatherAlerts': 'የአየር ሁኔታ ማንቂያዎች',
      'farmingAdvice': 'የእርሻ ምክር',
      'sevenDayForecast': 'የ7 ቀን ትንበያ',
      'today': 'ዛሬ',
      'farmRecords': 'የእርሻ መዝገቦች',
      'records': 'መዝገቦች',
      'analytics': 'ትንታኔ',
      'summary': 'ማጠቃለያ',
      'addRecord': 'መዝገብ ጨምር',
      'noRecords': 'ገና መዝገብ የለም',
      'tapToAddRecord': 'የመጀመሪያ መዝገብዎን ለመጨመር + ን ይጫኑ',
      'recordType': 'የመዝገብ አይነት',
      'crop': 'ሰብል',
      'description': 'ገለጻ',
      'amount': 'መጠን',
      'category': 'ምድብ',
      'quantity': 'ብዛት',
      'date': 'ቀን',
      'notes': 'ማስታወሻዎች',
      'required': 'ይህ መስክ ያስፈልጋል',
      'totalExpenses': 'ጠቅላላ ወጪዎች',
      'totalIncome': 'ጠቅላላ ገቢ',
      'netProfit': 'ንጹህ ትርፍ',
      'laborHours': 'የስራ ሰዓቶች',
      'incomeByMonth': 'በወር ገቢ',
      'harvestByCrop': 'በሰብል ምርት',
      'expensesByCategory': 'በምድብ ወጪዎች',
      'noDataForAnalytics': 'ለትንታኔ ውሂብ የለም',
      'knowledgeBase': 'የእውቀት ማዕከል',
      'searchArticles': 'ጽሁፎችን ይፈልጉ...',
      'all': 'ሁሉም',
      'noArticlesFound': 'ጽሁፎች አልተገኙም',
      'privacySettings': 'ግላዊነት እና ውሂብ',
      'dataCollection': 'ውሂብ መሰብሰብ',
      'usageAnalytics': 'አጠቃቀም ትንታኔ',
      'usageAnalyticsDesc': 'በማንነት የሌለው ውሂብ መተግበሪያውን ለማሻሻል ይረዱ',
      'locationAccess': 'የአካባቢ መዳረሻ',
      'locationAccessDesc': 'ለአየር ሁኔታ እና ለሰብል ምክሮች ይጠቅማል',
      'dataSharing': 'ውሂብ ማጋራት',
      'dataSharingDesc': 'ለምርምር ማንነት የሌለው ውሂብ ያጋሩ',
      'offlineMode': 'ከመስመር ውጪ ሁነታ',
      'offlineModeOnly': 'ከመስመር ውጪ ብቻ',
      'offlineModeOnlyDesc': 'ውሂብን በጭራሽ ወደ ደመና አይላክ',
      'syncStatus': 'የማመሳሰል ሁኔታ',
      'online': 'መስመር ላይ',
      'offline': 'ከመስመር ውጪ',
      'dataManagement': 'ውሂብ አስተዳደር',
      'exportData': 'ውሂቤን ላክ',
      'exportDataDesc': 'ሁሉንም የእርሻ ውሂብዎን ያውርዱ',
      'clearLocalData': 'የአካባቢ መሸጎጫ አጥፋ',
      'clearLocalDataDesc': 'ከመሳሪያው የተሸጎጠ ውሂብን ያስወግዱ',
      'deleteAccount': 'መለያ ሰርዝ',
      'deleteAccountDesc': 'መለያ እና ሁሉንም ውሂብ በቋሚነት ሰርዝ',
      'deleteAccountWarning': 'ይህ እርምጃ መመለስ አይቻልም!',
      'clear': 'አጥፋ',
      'clearLocalDataConfirm': 'ይህ ሁሉንም የተሸጎጠ ውሂብ ያጠፋል። ይቀጥሉ?',
      'localDataCleared': 'የአካባቢ መሸጎጫ ተጠርጓል',
      'exportingData': 'ውሂብዎን በመላክ ላይ...',
      'dataExported': 'ውሂብ በተሳካ ሁኔታ ተልኳል',
      'errorDeletingAccount': 'መለያ በመሰረዝ ላይ ስህተት',
      'consentInfo': 'ውሂብ እና ስምምነት መረጃ',
      'dataWeCollect': 'የምንሰበስበው ውሂብ',
      'profileInfo': 'የመገለጫ መረጃ',
      'locationData': 'የአካባቢ ውሂብ',
      'farmData': 'የእርሻ እና የሰብል ውሂብ',
      'usageData': 'የመተግበሪያ አጠቃቀም ውሂብ',
      'howWeUseData': 'ውሂብዎን እንዴት እንጠቀማለን',
      'dataUsageDesc': 'ውሂብዎን ለግል ሰብል ምክሮች፣ ለአየር ሁኔታ ማንቂያዎች እና AI ሞዴሎቻችንን ለማሻሻል እንጠቀማለን። ውሂብዎ በደህንነት ይቀመጣል እና በጭራሽ ለሶስተኛ ወገኖች አይሸጥም።',
      'privacyPolicy': 'የግላዊነት ፖሊሲ',
      'termsOfService': 'የአገልግሎት ውሎች',
      'close': 'ዝጋ',
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
      'profileSaved': 'Piroofaayiliin milkaa\'inaan olkaa\'ame!',
      'farmProfile': 'Piroofaayilii Qonnaa',
      'basicInfo': 'Odeeffannoo Bu\'uuraa',
      'farmerName': 'Maqaa Qonnaan Bulaa',
      'location': 'Bakka',
      'region': 'Naannoo',
      'zone': 'Godina',
      'woreda': 'Aanaa',
      'kebele': 'Ganda',
      'farmDetails': 'Bal\'ina Qonnaa',
      'farmSizeHectares': 'Bal\'ina Lafa (Heektaara)',
      'soilType': 'Gosa Biyyee',
      'irrigationType': 'Gosa Jallisii',
      'hasWaterAccess': 'Bishaan Argachuu',
      'farmingPractice': 'Gocha Qonnaa',
      'farmingType': 'Gosa Qonnaa',
      'subsistence': 'Ofii Fayyadamuuf',
      'commercial': 'Daldalaa',
      'mixed': 'Makaa',
      'experience': 'Muuxannoo',
      'usesChemicalFertilizers': 'Xaa\'oo Keemikaalaa Fayyadama',
      'usesOrganic': 'Mala Orgaanikii Fayyadama',
      'crops': 'Midhaanota',
      'currentCrops': 'Midhaanota Ammaa',
      'preferredCrops': 'Midhaanota Filataman',
      'equipment': 'Meeshaalee',
      'availableEquipment': 'Meeshaalee Jiran',
      'marketAccess': 'Gabaa Argachuu',
      'nearestMarket': 'Gabaa Dhihoo',
      'distanceToMarketKm': 'Fageenya Gabaa (km)',
      'hasTransport': 'Geejjiba Qaba',
      'saveProfile': 'Piroofaayilii Olkaa\'i',
      'marketPrices': 'Gatii Gabaa',
      'currentPrices': 'Gatii Ammaa',
      'priceHistory': 'Seenaa Gatii',
      'sellRecommendation': 'Gorsa Gurgurtaa',
      'getRecommendation': 'Gorsa Argadhu',
      'weatherAdvisor': 'Gorsaa Haala Qilleensaa',
      'currentWeather': 'Haala Qilleensaa Ammaa',
      'humidity': 'Jiidhina',
      'rain': 'Rooba',
      'wind': 'Bubbee',
      'weatherAlerts': 'Akeekkachiisa Qilleensaa',
      'farmingAdvice': 'Gorsa Qonnaa',
      'sevenDayForecast': 'Tilmaama Guyyaa 7',
      'today': 'Har\'a',
      'farmRecords': 'Galmee Qonnaa',
      'records': 'Galmeewwan',
      'analytics': 'Xiinxala',
      'summary': 'Cuunfaa',
      'addRecord': 'Galmee Dabali',
      'noRecords': 'Ammas galmeen hin jiru',
      'tapToAddRecord': 'Galmee jalqabaa dabaluuf + tuqi',
      'recordType': 'Gosa Galmee',
      'crop': 'Midhaan',
      'description': 'Ibsa',
      'amount': 'Baay\'ina',
      'category': 'Ramaddii',
      'quantity': 'Hamma',
      'date': 'Guyyaa',
      'notes': 'Yaadannoo',
      'required': 'Kutaan kun barbaachisaa dha',
      'totalExpenses': 'Baasii Waliigalaa',
      'totalIncome': 'Galii Waliigalaa',
      'netProfit': 'Bu\'aa Qulqulluu',
      'laborHours': 'Sa\'aatii Hojii',
      'incomeByMonth': 'Galii Ji\'aan',
      'harvestByCrop': 'Oomisha Midhaaniin',
      'expensesByCategory': 'Baasii Ramaddiiin',
      'noDataForAnalytics': 'Xiinxalaaf odeeffannoon hin jiru',
      'knowledgeBase': 'Kuusaa Beekumsaa',
      'searchArticles': 'Barruulee barbaadi...',
      'all': 'Hundaa',
      'noArticlesFound': 'Barruuleen hin argamne',
      'privacySettings': 'Iccitii fi Odeeffannoo',
      'dataCollection': 'Odeeffannoo Walitti Qabuu',
      'usageAnalytics': 'Xiinxala Itti Fayyadama',
      'usageAnalyticsDesc': 'Odeeffannoo maqaa malee app fooyyessuuf gargaari',
      'locationAccess': 'Bakka Argachuu',
      'locationAccessDesc': 'Haala qilleensaa fi gorsa midhaaniif fayyada',
      'dataSharing': 'Odeeffannoo Qooduu',
      'dataSharingDesc': 'Qorannoof odeeffannoo maqaa malee qoodi',
      'offlineMode': 'Haalata Offline',
      'offlineModeOnly': 'Offline Qofa',
      'offlineModeOnlyDesc': 'Odeeffannoo yeroo kamuu gara duumeessaatti hin ergiin',
      'syncStatus': 'Haala Walsimsiisuu',
      'online': 'Sarara irra',
      'offline': 'Sarara alaa',
      'dataManagement': 'Bulchiinsa Odeeffannoo',
      'exportData': 'Odeeffannoo Koo Ergi',
      'exportDataDesc': 'Odeeffannoo qonnaa kee hunda buufadhu',
      'clearLocalData': 'Kuusaa Naannoo Haqi',
      'clearLocalDataDesc': 'Odeeffannoo kuufame meeshaa irraa haqi',
      'deleteAccount': 'Herrega Haqi',
      'deleteAccountDesc': 'Herrega fi odeeffannoo hunda yeroo hundaaf haqi',
      'deleteAccountWarning': 'Gocha kana deebisuu hin danda\'amu!',
      'clear': 'Haqi',
      'clearLocalDataConfirm': 'Kun odeeffannoo kuufame hunda ni haqa. Itti fufi?',
      'localDataCleared': 'Kuusaan naannoo haqame',
      'exportingData': 'Odeeffannoo kee ergaa jira...',
      'dataExported': 'Odeeffannoon milkaa\'inaan ergame',
      'errorDeletingAccount': 'Herrega haquurratti dogoggora',
      'consentInfo': 'Odeeffannoo fi Walii Galtee',
      'dataWeCollect': 'Odeeffannoo Walitti Qabnu',
      'profileInfo': 'Odeeffannoo piroofaayilii',
      'locationData': 'Odeeffannoo bakka',
      'farmData': 'Odeeffannoo qonnaa fi midhaanii',
      'usageData': 'Odeeffannoo itti fayyadama app',
      'howWeUseData': 'Odeeffannoo Kee Akkamitti Fayyadamna',
      'dataUsageDesc': 'Odeeffannoo kee gorsa midhaan dhuunfaa, akeekkachiisa qilleensaa, fi moodela AI keenya fooyyessuuf fayyadamna. Odeeffannoon kee nageenyaan kuufama, qaamota sadaffaaf hin gurguramne.',
      'privacyPolicy': 'Imaammata Iccitii',
      'termsOfService': 'Haala Tajaajilaa',
      'close': 'Cufi',
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



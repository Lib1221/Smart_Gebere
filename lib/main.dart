import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:smart_gebere/firebase_options.dart';
import 'package:smart_gebere/stream/stream_provider.dart';
import 'package:provider/provider.dart';
import 'package:smart_gebere/settings/app_settings.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_gebere/l10n/fallback_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock the orientation to **portrait mode only**
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final appSettings = await AppSettings.load();

  runApp(
    ChangeNotifierProvider.value(
      value: appSettings,
      child: const SmartGebereApp(),
    ),
  );
}

class SmartGebereApp extends StatelessWidget {
  const SmartGebereApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Fallback delegates (support all locales, return default EN) so the app
        // doesn't crash on locales Flutter doesn't ship (e.g. `om`).
        const FallbackMaterialLocalizationsDelegate(),
        const FallbackWidgetsLocalizationsDelegate(),
        const FallbackCupertinoLocalizationsDelegate(),
      ],
      home: StreamProviderClass(),
    );
  }
}

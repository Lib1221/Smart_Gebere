import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_gebere/Disease_page/DiseaseDetection.dart';
import 'package:smart_gebere/Home/Home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_gebere/Loading/loading.dart';
import 'package:smart_gebere/auth/login/login.dart';
import 'package:smart_gebere/off_track/list_generate.dart';
import 'package:smart_gebere/stream/stream_provider.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MaterialApp(
      home:CropSuggestionPage(), //StreamProviderClass()
    )
    );
}




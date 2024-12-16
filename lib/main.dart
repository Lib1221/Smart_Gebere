import 'package:flutter/material.dart';
import 'package:smart_gebere/splash/screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';



void main() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(MaterialApp(
    title: 'Smart Gebere',
    theme: ThemeData(
      primaryColor: Colors.green,
      scaffoldBackgroundColor: Colors.lightGreen[50],
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
        displayLarge: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, 
          backgroundColor: Colors.green,
        ),
      ),
    ),
    home: MyHomePage1(),
  ));
}

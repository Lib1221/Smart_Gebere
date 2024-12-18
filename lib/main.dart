import 'package:flutter/material.dart';
import 'package:smart_gebere/Home/home_page.dart';
import 'package:smart_gebere/auth/authservice.dart';
import 'package:smart_gebere/splash/screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';



void main() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const Authservice());
    
}




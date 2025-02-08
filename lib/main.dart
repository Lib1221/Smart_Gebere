import 'package:flutter/material.dart';
import 'package:smart_gebere/Home/Home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_gebere/auth/login/login.dart';
import 'firebase_options.dart';



void main() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(MaterialApp(
    home: LoginPage(),
    debugShowCheckedModeBanner: false,
  ) );//Authservice());
    
}


import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:smart_gebere/Home/Home.dart';
import 'package:smart_gebere/Theme/theme.dart';
import 'package:smart_gebere/auth/sign_in.dart';

class Authservice extends StatelessWidget { 
  const Authservice({super.key});
  

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Gebere',
      theme: buildTheme(),
    initialRoute:
          '/sign-in',
      routes: {
        
        '/sign-in': (context) => CustomSignInScreen(provider: providers,),
        '/profile': (context) => ProfileScreen( 
                  providers:providers, 
                  showDeleteConfirmationDialog:true,
                   actions:[ SignedOutAction((context) {
                     Navigator.pushReplacementNamed(context, '/sign-in'); 
                     }), 
                     AccountDeletedAction((context, user) { 
                      Navigator.pushReplacementNamed(context, '/sign-in'); }),], 
                      children:const []),
        '/home':(context)=>const Home_Screen()
                      },
        
  );
  }
  }
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:smart_gebere/auth/authservice.dart';
import 'package:tbib_splash_screen/splash_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool isLoaded = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) { 
        setState(() {
          isLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreenView(
      duration: const Duration(seconds: 0),
      navigateWhere: isLoaded,
      navigateRoute: const Authservice(), 
      backgroundColor: Colors.green,
      
      text: WavyAnimatedText(
        "Smart Gebere",
        textAlign: TextAlign.center,
        textStyle: const TextStyle(
          color: Colors.red,
          fontSize: 40.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      imageSrc: 'assets/first.png',
      displayLoading: true,
      logoSize: 250.0, 
    );
  }
}


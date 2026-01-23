import 'package:flutter/material.dart'; 
import 'package:google_fonts/google_fonts.dart'; // Custom Google Fonts support
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:smart_gebere/Home/Home.dart'; // Home screen
import 'package:smart_gebere/onboarding/onboarding_page.dart'; // Onboarding screen
import 'package:smart_gebere/auth/login/login.dart'; // Login screen
import 'package:smart_gebere/core/services/offline_storage.dart'; // Local storage service

// Splash screen widget
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// State class with animation support
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  
  // Animations
  late Animation<double> _logoScale;      // Logo scaling animation
  late Animation<double> _logoRotation;   // Logo rotation animation
  late Animation<double> _textOpacity;    // Text fade animation
  late Animation<Offset> _textSlide;      // Text slide animation
  late Animation<double> _progressValue;  // Progress bar animation

  @override
  void initState() {
    super.initState();
    _initAnimations();       // Initialize all animations
    _navigateAfterDelay();   // Navigate after splash delay
  }

  // Initialize animation controllers and animations
  void _initAnimations() {

    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Logo scale animation
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    // Logo rotation animation
    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Text opacity animation
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    
    // Text slide animation
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Progress bar animation controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Progress value animation
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start logo animation
    _logoController.forward();

    // Start text and progress animations after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
      _progressController.forward();
    });
  }

  // Handle navigation after splash screen delay
  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    
    // Prevent navigation if widget is disposed
    if (!mounted) return;

    // Check if onboarding was completed
    final onboardingCompleted =
        OfflineStorage.getUserPref<bool>('onboarding_completed') ?? false;
    
    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;

    Widget destination;

    // Decide destination screen
    if (user != null) {
      destination = const Home_Screen();
    } else if (!onboardingCompleted) {
      destination = const OnboardingPage();
    } else {
      destination = const LoginPage();
    }

    // Navigate with fade transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose animation controllers to free memory
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // Background gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF43A047),
            ],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated logo
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Transform.rotate(
                      angle: _logoRotation.value * 0.1,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Leaf icon
                      const Icon(
                        Icons.eco,
                        size: 70,
                        color: Color(0xFF2E7D32),
                      ),

                      // Shine effect
                      Positioned(
                        top: 20,
                        right: 25,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // App name and tagline
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Column(
                    children: [
                      Text(
                        'Smart Gebere',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Empowering Ethiopian Farmers',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Loading progress indicator
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return Column(
                    children: [
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progressValue.value,
                            backgroundColor:
                                Colors.white.withOpacity(0.2),
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Loading status text
                      Text(
                        _getLoadingText(_progressValue.value),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // App version
              Text(
                'Version 1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Returns loading text based on progress value
  String _getLoadingText(double progress) {
    if (progress < 0.3) return 'Initializing...';
    if (progress < 0.6) return 'Loading resources...';
    if (progress < 0.9) return 'Almost ready...';
    return 'Welcome!';
  }
}

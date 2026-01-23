import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_gebere/auth/login/login.dart';
import 'package:smart_gebere/core/services/offline_storage.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = [
    _OnboardingItem(
      title: 'Smart Crop Planning',
      description: 'Get AI-powered crop recommendations based on your location, soil type, and weather conditions in Ethiopia.',
      icon: Icons.grass,
      color: const Color(0xFF4CAF50),
      image: 'crops',
    ),
    _OnboardingItem(
      title: 'Disease Detection',
      description: 'Take a photo of your crops and instantly identify diseases with treatment recommendations.',
      icon: Icons.document_scanner,
      color: const Color(0xFFE91E63),
      image: 'disease',
    ),
    _OnboardingItem(
      title: 'Market Prices',
      description: 'Track real-time market prices for Teff, Wheat, Coffee, and more. Know the best time to sell.',
      icon: Icons.trending_up,
      color: const Color(0xFF2196F3),
      image: 'market',
    ),
    _OnboardingItem(
      title: 'Weather Alerts',
      description: 'Get weather forecasts and farming advice. Protect your crops from extreme weather.',
      icon: Icons.cloud,
      color: const Color(0xFF0277BD),
      image: 'weather',
    ),
    _OnboardingItem(
      title: 'Works Offline',
      description: 'Access your farm data even without internet. Sync automatically when connected.',
      icon: Icons.offline_bolt,
      color: const Color(0xFFFF9800),
      image: 'offline',
    ),
  ];

  
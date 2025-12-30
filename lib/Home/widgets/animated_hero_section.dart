import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_gebere/features/weather_advisor/weather_advisor_page.dart';
import 'package:smart_gebere/settings/settings_page.dart';
import 'package:smart_gebere/core/services/connectivity_service.dart';

/// A stunning animated hero section for the Smart Gebere dashboard
class AnimatedHeroSection extends StatefulWidget {
  final Map<String, dynamic>? weatherData;
  final String Function() getGreeting;
  final String Function() getWeatherTemperature;
  final ConnectivityService connectivity;

  const AnimatedHeroSection({
    super.key,
    required this.weatherData,
    required this.getGreeting,
    required this.getWeatherTemperature,
    required this.connectivity,
  });

  @override
  State<AnimatedHeroSection> createState() => _AnimatedHeroSectionState();
}

class _AnimatedHeroSectionState extends State<AnimatedHeroSection>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _sunController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    
    // Floating animation
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Sun rotation
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    _sunController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SliverAppBar(
      expandedHeight: 260,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1B5E20),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: _buildActions(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D3B0D),
                    Color(0xFF1B5E20),
                    Color(0xFF2E7D32),
                    Color(0xFF43A047),
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
            
            // Layer 2: Animated sun
            _buildAnimatedSun(),
            
            // Layer 3: Animated clouds
            _buildAnimatedClouds(),
            
            // Layer 4: Floating particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ParticlePainter(
                    progress: _particleController.value,
                  ),
                );
              },
            ),
            
            // Layer 5: Growing plants at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: AnimatedBuilder(
                animation: _floatingController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _PlantsPainter(
                      swayOffset: _floatingController.value * 6 - 3,
                    ),
                  );
                },
              ),
            ),
            
            // Layer 6: Ground fade
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1B5E20).withAlpha(200),
                    ],
                  ),
                ),
              ),
            ),
            
            // Layer 7: User content
            _buildUserContent(user),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      if (!widget.connectivity.isOnline)
        Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, color: Colors.orange, size: 16),
              SizedBox(width: 4),
              Text('Offline', style: TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ),
        ),
      IconButton(
        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        onPressed: () {},
      ),
      IconButton(
        icon: const Icon(Icons.settings_outlined, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
        ),
      ),
    ];
  }

  Widget _buildAnimatedSun() {
    return AnimatedBuilder(
      animation: Listenable.merge([_sunController, _pulseController]),
      builder: (context, child) {
        final glowIntensity = 0.3 + (_pulseController.value * 0.3);
        
        return Positioned(
          right: 25,
          top: 55,
          child: Transform.rotate(
            angle: _sunController.value * 2 * math.pi,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.withAlpha((255 * glowIntensity).toInt()),
                        Colors.amber.withAlpha((80 * glowIntensity).toInt()),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Sun rays
                ...List.generate(8, (i) {
                  final angle = i * 45 * math.pi / 180;
                  return Transform.rotate(
                    angle: angle,
                    child: Container(
                      width: 2.5,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.amber.withAlpha(180),
                            Colors.amber.withAlpha(30),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
                // Sun core
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFEB3B),
                        Color(0xFFFFC107),
                        Color(0xFFFF9800),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withAlpha(150),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedClouds() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        final offset = _floatingController.value * 20;
        
        return Stack(
          children: [
            Positioned(
              left: 20 + offset,
              top: 50,
              child: _buildCloud(70, 0.12),
            ),
            Positioned(
              left: 150 - offset * 0.5,
              top: 80,
              child: _buildCloud(50, 0.08),
            ),
            Positioned(
              right: 100 + offset * 0.7,
              top: 110,
              child: _buildCloud(40, 0.06),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCloud(double size, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size * 0.5,
            height: size * 0.35,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Transform.translate(
            offset: Offset(-size * 0.15, -size * 0.1),
            child: Container(
              width: size * 0.7,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-size * 0.3, 0),
            child: Container(
              width: size * 0.4,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserContent(User? user) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                // Pulsing avatar
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.05);
                    
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(40),
                              blurRadius: 12 * scale,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withAlpha(50),
                          child: Text(
                            (user?.displayName?.isNotEmpty ?? false)
                                ? user!.displayName![0].toUpperCase()
                                : '🌾',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Greeting and name
                Expanded(
                  child: AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      final offset = (_floatingController.value - 0.5) * 4;
                      
                      return Transform.translate(
                        offset: Offset(0, offset),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.getGreeting(),
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.displayName ?? 'Farmer',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(50),
                                    blurRadius: 8,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Weather card
                _buildWeatherCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const WeatherAdvisorPage()),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatingController, _pulseController]),
        builder: (context, child) {
          final floatOffset = (_floatingController.value - 0.5) * 6;
          final scale = 0.97 + (_pulseController.value * 0.03);
          
          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha(60),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (widget.weatherData?['icon'] as String?) ?? '🌡️',
                      style: const TextStyle(fontSize: 26),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.getWeatherTemperature(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.weatherData?['condition'] != null)
                      Text(
                        (widget.weatherData!['condition'] as String).split(' ').first,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Custom Painters
// ═══════════════════════════════════════════════════════════════════════════════

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final List<_Particle> _particles = _generateParticles();

  _ParticlePainter({required this.progress});

  static List<_Particle> _generateParticles() {
    final random = math.Random(42);
    return List.generate(20, (i) => _Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 3 + 1.5,
      speed: random.nextDouble() * 0.15 + 0.05,
      opacity: random.nextDouble() * 0.4 + 0.2,
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = ((p.y + progress * p.speed * 5) % 1.2) * size.height - size.height * 0.1;
      final x = p.x * size.width + math.sin(progress * math.pi * 2 + p.y * 10) * 15;
      
      final paint = Paint()
        ..color = Colors.white.withAlpha((255 * p.opacity * (1 - (y / size.height).clamp(0, 1) * 0.5)).toInt());
      
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => 
      oldDelegate.progress != progress;
}

class _Particle {
  final double x, y, size, speed, opacity;
  _Particle({required this.x, required this.y, required this.size, 
             required this.speed, required this.opacity});
}

class _PlantsPainter extends CustomPainter {
  final double swayOffset;

  _PlantsPainter({required this.swayOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF558B2F)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = const Color(0xFF7CB342).withAlpha(200)
      ..style = PaintingStyle.fill;

    // Draw several plants
    for (int i = 0; i < 7; i++) {
      final x = size.width * (0.08 + i * 0.14);
      final height = 35.0 + (i % 3) * 15;
      final sway = swayOffset * (0.5 + (i % 3) * 0.3);
      
      _drawPlant(canvas, x, size.height, height, sway, stemPaint, leafPaint, i);
    }
  }

  void _drawPlant(Canvas canvas, double x, double baseY, double height, 
                  double sway, Paint stemPaint, Paint leafPaint, int type) {
    // Stem
    final stemPath = Path()
      ..moveTo(x, baseY)
      ..quadraticBezierTo(x + sway * 0.5, baseY - height * 0.5, x + sway, baseY - height);
    canvas.drawPath(stemPath, stemPaint);

    // Leaves
    final leafSize = 10.0;
    
    // Left leaf
    if (height > 25) {
      final ly = baseY - height * 0.4;
      final lx = x + sway * 0.3;
      final leftLeaf = Path()
        ..moveTo(lx, ly)
        ..quadraticBezierTo(lx - leafSize, ly - leafSize * 0.3, lx - leafSize * 0.7, ly + leafSize * 0.2);
      canvas.drawPath(leftLeaf, leafPaint);
    }

    // Right leaf
    if (height > 35) {
      final ry = baseY - height * 0.65;
      final rx = x + sway * 0.65;
      final rightLeaf = Path()
        ..moveTo(rx, ry)
        ..quadraticBezierTo(rx + leafSize, ry - leafSize * 0.3, rx + leafSize * 0.7, ry + leafSize * 0.2);
      canvas.drawPath(rightLeaf, leafPaint);
    }

    // Top (grain/flower based on type)
    final topX = x + sway;
    final topY = baseY - height;
    
    if (type % 3 == 0) {
      // Wheat grain
      final grainPaint = Paint()..color = const Color(0xFFFFD54F);
      for (int j = 0; j < 4; j++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(topX + (j - 1.5) * 3, topY - j * 3),
            width: 3,
            height: 6,
          ),
          grainPaint,
        );
      }
    } else if (type % 3 == 1) {
      // Teff-like
      final teffPaint = Paint()
        ..color = const Color(0xFFBCAAA4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      for (int j = 0; j < 5; j++) {
        final angle = (j * 72 - 90) * math.pi / 180;
        canvas.drawLine(
          Offset(topX, topY),
          Offset(topX + math.cos(angle) * 8, topY + math.sin(angle) * 8),
          teffPaint,
        );
      }
    } else {
      // Simple dot
      canvas.drawCircle(
        Offset(topX, topY - 3),
        4,
        Paint()..color = const Color(0xFFA5D6A7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlantsPainter oldDelegate) => 
      oldDelegate.swayOffset != swayOffset;
}

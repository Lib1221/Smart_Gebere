// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_gebere/Home/created_task.dart';
import 'package:smart_gebere/Home/expected_event.dart';
import 'package:smart_gebere/Home/task_creation.dart';
import 'package:smart_gebere/auth/login/login.dart';
import 'package:smart_gebere/settings/settings_page.dart';
import 'package:smart_gebere/features/farm_profile/farm_profile_page.dart';
import 'package:smart_gebere/features/market_prices/market_prices_page.dart';
import 'package:smart_gebere/features/weather_advisor/weather_advisor_page.dart';
import 'package:smart_gebere/features/farm_records/farm_records_page.dart';
import 'package:smart_gebere/features/knowledge_base/knowledge_base_page.dart';
import 'package:smart_gebere/features/privacy/privacy_page.dart';
import 'package:smart_gebere/features/ai_doctor/ai_crop_doctor_page.dart';
import 'package:smart_gebere/features/yield_prediction/yield_prediction_page.dart';
import 'package:smart_gebere/features/field_mapping/field_mapping_page.dart';
import 'package:smart_gebere/Disease_page/DiseaseDetection.dart' as disease;
import 'package:smart_gebere/task_management/descrition.dart';
import 'package:smart_gebere/core/services/connectivity_service.dart';
import 'package:smart_gebere/core/services/offline_storage.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';

class Home_Screen extends StatefulWidget {
  const Home_Screen({super.key});

  @override
  State<Home_Screen> createState() => _Home_ScreenState();
}

class _Home_ScreenState extends State<Home_Screen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 0;
  Map<String, dynamic>? _weatherData;
  int _taskCount = 0;
  int _cropCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    // Load cached weather
    final weather = OfflineStorage.getCachedWeather('current');
    if (weather != null && mounted) {
      setState(() => _weatherData = weather);
    }

    // Load task count from Firestore
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('Farmers')
            .doc(userId)
            .get();

        if (userDoc.exists && mounted) {
          final crops = userDoc.data()?['crops'] as List<dynamic>? ?? [];
          int totalTasks = 0;
          for (var crop in crops) {
            final weeks = crop['weeks'] as List<dynamic>? ?? [];
            for (var week in weeks) {
              final tasks = week['tasks'] as List<dynamic>? ?? [];
              totalTasks += tasks.length;
            }
          }

          setState(() {
            _cropCount = crops.length;
            _taskCount = totalTasks;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('[Home] Error loading dashboard data: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connectivity = Provider.of<ConnectivityService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _buildDrawer(context, l10n),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBodyContent(_selectedIndex, l10n, connectivity),
      ),
      bottomNavigationBar: _buildBottomNav(l10n),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AgriculturePage()),
              ),
              backgroundColor: const Color(0xFF2E7D32),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                l10n.createTask,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBodyContent(
      int index, AppLocalizations l10n, ConnectivityService connectivity) {
    switch (index) {
      case 0:
        return _buildHomePage(l10n, connectivity);
      case 1:
        return _buildCropsPage(l10n);
      case 2:
        // Center "Add" button - navigate to create task
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgriculturePage()),
          );
          setState(() => _selectedIndex = 0);
        });
        return _buildHomePage(l10n, connectivity);
      case 3:
        return _buildAnalyticsPage(l10n);
      case 4:
        return _buildProfilePage(l10n);
      default:
        return _buildHomePage(l10n, connectivity);
    }
  }

  // ===================== HOME PAGE =====================
  Widget _buildHomePage(AppLocalizations l10n, ConnectivityService connectivity) {
    final user = FirebaseAuth.instance.currentUser;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Custom App Bar with Agriculture Image
        SliverAppBar(
          expandedHeight: 220,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF2E7D32),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            if (!connectivity.isOnline)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text('Offline',
                        style: TextStyle(color: Colors.orange, fontSize: 12)),
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
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                    ),
                  ),
                ),
                // Agriculture pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FarmPatternPainter(),
                  ),
                ),
                // User greeting
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Animated avatar with plant icon
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  (user?.displayName?.isNotEmpty == true)
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    user?.displayName ?? 'Farmer',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Weather mini card
                            if (_weatherData != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.wb_sunny,
                                        color: Colors.amber, size: 24),
                                    Text(
                                      '${_weatherData!['current']?['temperature_2m'] ?? '--'}°',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Dashboard Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Stats Row
                _buildStatsRow(),
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickActionsRow(l10n),
                const SizedBox(height: 24),

                // Create Task Section
                _buildEnhancedSectionCard(
                  title: l10n.createTask,
                  subtitle: 'Start your farming journey',
                  icon: Icons.add_task,
                  color: const Color(0xFF4CAF50),
                  child: const EnhancedTaskCreationSection(),
                ),
                const SizedBox(height: 16),

                // Created Tasks Section
                _buildEnhancedSectionCard(
                  title: l10n.createdTasks,
                  subtitle: 'Track your crop progress',
                  icon: Icons.checklist,
                  color: const Color(0xFF2196F3),
                  child: SizedBox(
                    height: 180,
                    child: SlideableCreatedTasks(),
                  ),
                ),
                const SizedBox(height: 16),

                // Expected Events Section
                _buildEnhancedSectionCard(
                  title: l10n.expectedEvents,
                  subtitle: 'Upcoming farming activities',
                  icon: Icons.event,
                  color: const Color(0xFFF57C00),
                  child: const SizedBox(
                    height: 180,
                    child: SlideableExpectedEvents(),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildEnhancedStatCard(
            icon: Icons.grass,
            label: 'Active Crops',
            value: _isLoading ? '...' : '$_cropCount',
            color: const Color(0xFF4CAF50),
            gradient: [const Color(0xFF66BB6A), const Color(0xFF43A047)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEnhancedStatCard(
            icon: Icons.task_alt,
            label: 'Total Tasks',
            value: _isLoading ? '...' : '$_taskCount',
            color: const Color(0xFF2196F3),
            gradient: [const Color(0xFF42A5F5), const Color(0xFF1E88E5)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEnhancedStatCard(
            icon: Icons.wb_sunny,
            label: 'Weather',
            value: _weatherData != null
                ? '${_weatherData!['current']?['temperature_2m'] ?? '--'}°'
                : '--°',
            color: const Color(0xFFFF9800),
            gradient: [const Color(0xFFFFB74D), const Color(0xFFFB8C00)],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(AppLocalizations l10n) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildEnhancedQuickAction(
            icon: Icons.add_circle_outline,
            label: l10n.createTask,
            color: const Color(0xFF4CAF50),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AgriculturePage()),
            ),
          ),
          _buildEnhancedQuickAction(
            icon: Icons.document_scanner,
            label: 'Scan Disease',
            color: const Color(0xFFE91E63),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => disease.ImageAnalyzer()),
            ),
          ),
          _buildEnhancedQuickAction(
            icon: Icons.trending_up,
            label: 'Prices',
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarketPricesPage()),
            ),
          ),
          _buildEnhancedQuickAction(
            icon: Icons.cloud,
            label: 'Weather',
            color: const Color(0xFF0277BD),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeatherAdvisorPage()),
            ),
          ),
          _buildEnhancedQuickAction(
            icon: Icons.menu_book,
            label: 'Knowledge',
            color: const Color(0xFF00695C),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KnowledgeBasePage()),
            ),
          ),
          _buildEnhancedQuickAction(
            icon: Icons.medical_services,
            label: 'AI Doctor',
            color: const Color(0xFF9C27B0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AICropDoctorPage()),
            ),
          ),
          _buildEnhancedQuickAction(
            icon: Icons.auto_graph,
            label: 'Yield',
            color: const Color(0xFF3F51B5),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const YieldPredictionPage()),
            ),
          ),
          _buildEnhancedQuickAction(
            icon: Icons.map,
            label: 'Field Map',
            color: const Color(0xFF795548),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FieldMappingPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ===================== CROPS PAGE =====================
  Widget _buildCropsPage(AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('My Crops', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Farmers')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyState(
              icon: Icons.grass,
              title: 'No Crops Yet',
              subtitle: 'Start by creating your first crop plan',
              buttonText: l10n.createTask,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AgriculturePage()),
              ),
            );
          }

          final crops = snapshot.data!.data() as Map<String, dynamic>?;
          final cropList = crops?['crops'] as List<dynamic>? ?? [];

          if (cropList.isEmpty) {
            return _buildEmptyState(
              icon: Icons.grass,
              title: 'No Crops Yet',
              subtitle: 'Start by creating your first crop plan',
              buttonText: l10n.createTask,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AgriculturePage()),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cropList.length,
            itemBuilder: (context, index) {
              final crop = cropList[index];
              return _buildCropCard(crop);
            },
          );
        },
      ),
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop) {
    final weeks = crop['weeks'] as List<dynamic>? ?? [];
    final progress = _calculateCropProgress(weeks);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF43A047), const Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43A047).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Crop icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            // Crop info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop['name'] ?? 'Crop',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${weeks.length} weeks planned',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Progress indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 5,
                  ),
                ),
                Text(
                  '$progress%',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateCropProgress(List<dynamic> weeks) {
    if (weeks.isEmpty) return 0;
    final now = DateTime.now();
    int completed = 0;
    for (var week in weeks) {
      final dateRange = week['date_range'] as List<dynamic>?;
      if (dateRange != null && dateRange.length >= 2) {
        final endDate = DateTime.tryParse(dateRange[1]);
        if (endDate != null && now.isAfter(endDate)) {
          completed++;
        }
      }
    }
    return ((completed / weeks.length) * 100).round();
  }

  // ===================== ANALYTICS PAGE =====================
  Widget _buildAnalyticsPage(AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Farm Records summary
            _buildAnalyticsCard(
              title: l10n.farmRecords,
              icon: Icons.book,
              color: const Color(0xFF6A1B9A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FarmRecordsPage()),
              ),
            ),
            const SizedBox(height: 16),
            // Market Prices
            _buildAnalyticsCard(
              title: l10n.marketPrices,
              icon: Icons.trending_up,
              color: const Color(0xFF1565C0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketPricesPage()),
              ),
            ),
            const SizedBox(height: 16),
            // Weather
            _buildAnalyticsCard(
              title: l10n.weatherAdvisor,
              icon: Icons.cloud,
              color: const Color(0xFF0277BD),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeatherAdvisorPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ===================== PROFILE PAGE =====================
  Widget _buildProfilePage(AppLocalizations l10n) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            (user?.displayName?.isNotEmpty == true)
                                ? user!.displayName![0].toUpperCase()
                                : '👨‍🌾',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.displayName ?? 'Farmer',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileMenuItem(
                    icon: Icons.person_outline,
                    title: l10n.farmProfile,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FarmProfilePage()),
                    ),
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.settings,
                    title: l10n.settings,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacySettings,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmLogout(context, l10n),
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.logout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32)),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: const Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(buttonText, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.grass, 'Crops'),
              _buildNavItem(2, Icons.add_circle, 'Add', isSpecial: true),
              _buildNavItem(3, Icons.analytics, 'Analytics'),
              _buildNavItem(4, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      {bool isSpecial = false}) {
    final isSelected = _selectedIndex == index;

    if (isSpecial) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgriculturePage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[400],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            stops: [0.0, 0.3],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(
                      (user?.displayName?.isNotEmpty == true)
                          ? user!.displayName![0].toUpperCase()
                          : 'F',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? l10n.farmerName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style:
                        GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline,
                    title: l10n.farmProfile,
                    color: const Color(0xFF2E7D32),
                    page: const FarmProfilePage(),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.trending_up,
                    title: l10n.marketPrices,
                    color: const Color(0xFF1565C0),
                    page: const MarketPricesPage(),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.cloud,
                    title: l10n.weatherAdvisor,
                    color: const Color(0xFF0277BD),
                    page: const WeatherAdvisorPage(),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.book,
                    title: l10n.farmRecords,
                    color: const Color(0xFF6A1B9A),
                    page: const FarmRecordsPage(),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.library_books,
                    title: l10n.knowledgeBase,
                    color: const Color(0xFF00695C),
                    page: const KnowledgeBasePage(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Divider(),
                  ),
                  // AI & Advanced Features Section
                  _buildDrawerItem(
                    context,
                    icon: Icons.medical_services,
                    title: 'AI Crop Doctor',
                    color: const Color(0xFF9C27B0),
                    page: const AICropDoctorPage(),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.auto_graph,
                    title: 'Yield Prediction',
                    color: const Color(0xFF3F51B5),
                    page: const YieldPredictionPage(),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.map,
                    title: 'Field Mapping',
                    color: const Color(0xFF795548),
                    page: const FieldMappingPage(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Divider(),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings,
                    title: l10n.settings,
                    color: Colors.grey[700]!,
                    page: const SettingsPage(),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.privacy_tip,
                    title: l10n.privacySettings,
                    color: const Color(0xFF37474F),
                    page: const PrivacyPage(),
                  ),
                  const SizedBox(height: 20),
                  // Logout button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmLogout(context, l10n),
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: Text(l10n.logout,
                            style: const TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required Widget page,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text(l10n.confirmLogoutTitle),
          ],
        ),
        content: Text(l10n.confirmLogoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}

// ===================== ENHANCED TASK CREATION SECTION =====================
class EnhancedTaskCreationSection extends StatelessWidget {
  const EnhancedTaskCreationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Row(
      children: [
        Expanded(
          child: _buildEnhancedTaskCard(
            context: context,
            title: l10n.createTask,
            subtitle: 'AI-Powered Guidance',
            icon: Icons.agriculture,
            gradientColors: [const Color(0xFF43A047), const Color(0xFF66BB6A)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AgriculturePage()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEnhancedTaskCard(
            context: context,
            title: 'Detect Disease',
            subtitle: 'Scan Plant Leaves',
            icon: Icons.document_scanner,
            gradientColors: [const Color(0xFFE91E63), const Color(0xFFF06292)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => disease.ImageAnalyzer()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTaskCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 100,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== FARM PATTERN PAINTER =====================
class _FarmPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw wheat/plant pattern
    for (var i = 0; i < 8; i++) {
      final x = (size.width / 8) * i + 30;
      final baseY = size.height - 30;

      // Stem
      final path = Path()
        ..moveTo(x, baseY)
        ..lineTo(x, baseY - 60);

      // Leaves
      path.moveTo(x, baseY - 20);
      path.quadraticBezierTo(x + 15, baseY - 30, x + 20, baseY - 15);

      path.moveTo(x, baseY - 35);
      path.quadraticBezierTo(x - 15, baseY - 45, x - 20, baseY - 30);

      path.moveTo(x, baseY - 50);
      path.quadraticBezierTo(x + 12, baseY - 58, x + 15, baseY - 45);

      canvas.drawPath(path, paint);

      // Sun rays
      if (i == 6) {
        final sunCenter = Offset(x, baseY - 100);
        canvas.drawCircle(sunCenter, 20, paint);
        for (var j = 0; j < 8; j++) {
          final angle = (j * 45) * 3.14159 / 180;
          canvas.drawLine(
            Offset(sunCenter.dx + 25 * cos(angle), sunCenter.dy + 25 * sin(angle)),
            Offset(sunCenter.dx + 35 * cos(angle), sunCenter.dy + 35 * sin(angle)),
            paint,
          );
        }
      }
    }
  }

  double cos(double angle) => _cos(angle);
  double sin(double angle) => _sin(angle);

  double _cos(double x) {
    return 1 -
        (x * x) / 2 +
        (x * x * x * x) / 24 -
        (x * x * x * x * x * x) / 720;
  }

  double _sin(double x) {
    return x -
        (x * x * x) / 6 +
        (x * x * x * x * x) / 120 -
        (x * x * x * x * x * x * x) / 5040;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

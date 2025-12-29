// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:smart_gebere/core/services/connectivity_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';

class Home_Screen extends StatelessWidget {
  const Home_Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connectivity = Provider.of<ConnectivityService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Offline indicator
          if (!connectivity.isOnline)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.cloud_off, color: Colors.orange, size: 20),
            ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: l10n.logout,
            onPressed: () async {
              bool confirmLogout = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(l10n.confirmLogoutTitle),
                    content: Text(l10n.confirmLogoutBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.logout),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, l10n),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Flexible(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SectionHeader(title: l10n.createTask, bgColor: Colors.green.shade100),
                            const TaskCreationSection(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Flexible(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SectionHeader(title: l10n.createdTasks, bgColor: Colors.green.shade100),
                            const SizedBox(height: 10),
                            Expanded(child: SlideableCreatedTasks()),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Flexible(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            SectionHeader(title: l10n.expectedEvents, bgColor: Colors.green.shade100),
                            const SizedBox(height: 10),
                            const Expanded(child: SlideableExpectedEvents()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? l10n.farmerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Farm Profile
          _buildDrawerItem(
            context,
            icon: Icons.person_outline,
            title: l10n.farmProfile,
            color: const Color(0xFF2E7D32),
            page: const FarmProfilePage(),
          ),

          // Market Prices
          _buildDrawerItem(
            context,
            icon: Icons.trending_up,
            title: l10n.marketPrices,
            color: const Color(0xFF1565C0),
            page: const MarketPricesPage(),
          ),

          // Weather Advisor
          _buildDrawerItem(
            context,
            icon: Icons.cloud,
            title: l10n.weatherAdvisor,
            color: const Color(0xFF0277BD),
            page: const WeatherAdvisorPage(),
          ),

          // Farm Records
          _buildDrawerItem(
            context,
            icon: Icons.book,
            title: l10n.farmRecords,
            color: const Color(0xFF6A1B9A),
            page: const FarmRecordsPage(),
          ),

          // Knowledge Base
          _buildDrawerItem(
            context,
            icon: Icons.library_books,
            title: l10n.knowledgeBase,
            color: const Color(0xFF00695C),
            page: const KnowledgeBasePage(),
          ),

          const Divider(),

          // Settings
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: l10n.settings,
            color: Colors.grey[700]!,
            page: const SettingsPage(),
          ),

          // Privacy
          _buildDrawerItem(
            context,
            icon: Icons.privacy_tip,
            title: l10n.privacySettings,
            color: const Color(0xFF37474F),
            page: const PrivacyPage(),
          ),
        ],
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
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Color bgColor;

  const SectionHeader({super.key, required this.title, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

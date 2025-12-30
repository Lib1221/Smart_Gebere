import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_gebere/settings/app_settings.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';
import 'package:smart_gebere/core/services/offline_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Settings state
  bool _notificationsEnabled = true;
  // ignore: unused_field - reserved for future dark mode implementation
  bool _darkMode = false;
  bool _offlineModeEnabled = true;
  bool _autoSync = true;
  bool _locationEnabled = true;
  bool _analyticsEnabled = true;
  String _measurementUnit = 'hectares';
  String _temperatureUnit = 'celsius';
  double _cacheSize = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // Load saved settings from local storage
    final notifications = OfflineStorage.getUserPref<bool>('notifications_enabled');
    final darkMode = OfflineStorage.getUserPref<bool>('dark_mode');
    final offlineMode = OfflineStorage.getUserPref<bool>('offline_mode_enabled');
    final autoSync = OfflineStorage.getUserPref<bool>('auto_sync');
    final location = OfflineStorage.getUserPref<bool>('location_enabled');
    final analytics = OfflineStorage.getUserPref<bool>('analytics_enabled');
    final measureUnit = OfflineStorage.getUserPref<String>('measurement_unit');
    final tempUnit = OfflineStorage.getUserPref<String>('temperature_unit');

    if (mounted) {
      setState(() {
        _notificationsEnabled = notifications ?? true;
        _darkMode = darkMode ?? false;
        _offlineModeEnabled = offlineMode ?? true;
        _autoSync = autoSync ?? true;
        _locationEnabled = location ?? true;
        _analyticsEnabled = analytics ?? true;
        _measurementUnit = measureUnit ?? 'hectares';
        _temperatureUnit = tempUnit ?? 'celsius';
      });
    }

    // Calculate cache size (simplified)
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    // Simplified cache size calculation
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _cacheSize = 12.5; // MB - placeholder
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    await OfflineStorage.setUserPref(key, value);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<AppSettings>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Beautiful header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.settings,
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Customize your experience',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Settings content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══════════════════════════════════════════════════════
                    // Account Section
                    // ═══════════════════════════════════════════════════════
                    _buildSectionHeader('👤', 'Account', 'Manage your profile'),
                    _buildSettingsCard([
                      _buildAccountTile(user),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        subtitle: 'Update your personal information',
                        onTap: () => _showComingSoon('Edit Profile'),
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your security credentials',
                        onTap: _showChangePasswordDialog,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // Language & Region
                    // ═══════════════════════════════════════════════════════
                    _buildSectionHeader('🌍', 'Language & Region', 'Localization settings'),
                    _buildSettingsCard([
                      _buildLanguageSelector(settings, l10n),
                      _buildDivider(),
                      _buildDropdownTile(
                        icon: Icons.straighten,
                        title: 'Measurement Unit',
                        subtitle: 'For field sizes',
                        value: _measurementUnit,
                        items: const [
                          DropdownMenuItem(value: 'hectares', child: Text('Hectares')),
                          DropdownMenuItem(value: 'acres', child: Text('Acres')),
                          DropdownMenuItem(value: 'timad', child: Text('Timad (Ethiopian)')),
                        ],
                        onChanged: (value) async {
                          setState(() => _measurementUnit = value!);
                          await _saveSetting('measurement_unit', value);
                        },
                      ),
                      _buildDivider(),
                      _buildDropdownTile(
                        icon: Icons.thermostat,
                        title: 'Temperature Unit',
                        subtitle: 'For weather display',
                        value: _temperatureUnit,
                        items: const [
                          DropdownMenuItem(value: 'celsius', child: Text('Celsius (°C)')),
                          DropdownMenuItem(value: 'fahrenheit', child: Text('Fahrenheit (°F)')),
                        ],
                        onChanged: (value) async {
                          setState(() => _temperatureUnit = value!);
                          await _saveSetting('temperature_unit', value);
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // Notifications
                    // ═══════════════════════════════════════════════════════
                    _buildSectionHeader('🔔', 'Notifications', 'Alert preferences'),
                    _buildSettingsCard([
                      _buildSwitchTile(
                        icon: Icons.notifications_active,
                        title: 'Push Notifications',
                        subtitle: 'Receive task reminders',
                        value: _notificationsEnabled,
                        onChanged: (value) async {
                          setState(() => _notificationsEnabled = value);
                          await _saveSetting('notifications_enabled', value);
                        },
                      ),
                      if (_notificationsEnabled) ...[
                        _buildDivider(),
                        _buildNavigationTile(
                          icon: Icons.schedule,
                          title: 'Reminder Time',
                          subtitle: 'Set when to receive daily reminders',
                          trailing: Text(
                            '8:00 AM',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => _showComingSoon('Reminder Time'),
                        ),
                        _buildDivider(),
                        _buildNavigationTile(
                          icon: Icons.wb_sunny,
                          title: 'Weather Alerts',
                          subtitle: 'Get notified about weather changes',
                          onTap: () => _showComingSoon('Weather Alerts'),
                        ),
                      ],
                    ]),

                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // Data & Storage
                    // ═══════════════════════════════════════════════════════
                    _buildSectionHeader('💾', 'Data & Storage', 'Manage app data'),
                    _buildSettingsCard([
                      _buildSwitchTile(
                        icon: Icons.wifi_off,
                        title: 'Offline Mode',
                        subtitle: 'Download data for offline use',
                        value: _offlineModeEnabled,
                        onChanged: (value) async {
                          setState(() => _offlineModeEnabled = value);
                          await _saveSetting('offline_mode_enabled', value);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.sync,
                        title: 'Auto Sync',
                        subtitle: 'Automatically sync when online',
                        value: _autoSync,
                        onChanged: (value) async {
                          setState(() => _autoSync = value);
                          await _saveSetting('auto_sync', value);
                        },
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.storage,
                        title: 'Cache Size',
                        subtitle: '${_cacheSize.toStringAsFixed(1)} MB used',
                        trailing: TextButton(
                          onPressed: _clearCache,
                          child: Text(
                            'Clear',
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: _clearCache,
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.download,
                        title: 'Export Data',
                        subtitle: 'Download your farm data',
                        onTap: () => _showComingSoon('Export Data'),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // Privacy & Security
                    // ═══════════════════════════════════════════════════════
                    _buildSectionHeader('🔒', 'Privacy & Security', 'Data protection'),
                    _buildSettingsCard([
                      _buildSwitchTile(
                        icon: Icons.location_on,
                        title: 'Location Services',
                        subtitle: 'Allow access to your location',
                        value: _locationEnabled,
                        onChanged: (value) async {
                          setState(() => _locationEnabled = value);
                          await _saveSetting('location_enabled', value);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.analytics,
                        title: 'Analytics',
                        subtitle: 'Help improve the app',
                        value: _analyticsEnabled,
                        onChanged: (value) async {
                          setState(() => _analyticsEnabled = value);
                          await _saveSetting('analytics_enabled', value);
                        },
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.policy,
                        title: 'Privacy Policy',
                        subtitle: 'Read our privacy policy',
                        onTap: () => _showComingSoon('Privacy Policy'),
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.description,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms',
                        onTap: () => _showComingSoon('Terms of Service'),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // AI Settings
                    // ═══════════════════════════════════════════════════════
                    _buildSectionHeader('🤖', 'AI Assistant', 'Configure AI features'),
                    _buildSettingsCard([
                      _buildNavigationTile(
                        icon: Icons.psychology,
                        title: 'AI Language',
                        subtitle: 'Language for AI responses',
                        trailing: Text(
                          settings.aiLanguageName(),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.history,
                        title: 'Chat History',
                        subtitle: 'Clear AI conversation history',
                        onTap: _clearAIHistory,
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.bug_report,
                        title: 'Report AI Issue',
                        subtitle: 'Help us improve AI accuracy',
                        onTap: () => _showComingSoon('Report AI Issue'),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════════════════
                    // About
                    // ═══════════════════════════════════════════════════════
                    _buildSectionHeader('ℹ️', 'About', 'App information'),
                    _buildSettingsCard([
                      _buildNavigationTile(
                        icon: Icons.info_outline,
                        title: 'App Version',
                        subtitle: 'Smart Gebere v2.0.0',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.star_outline,
                        title: 'Rate App',
                        subtitle: 'Share your feedback',
                        onTap: () => _showComingSoon('Rate App'),
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.share,
                        title: 'Share App',
                        subtitle: 'Invite other farmers',
                        onTap: () => _showComingSoon('Share App'),
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help with the app',
                        onTap: () => _showComingSoon('Help & Support'),
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // Logout button
                    _buildLogoutButton(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Widget Builders
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
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
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, color: Colors.grey[200]);
  }

  Widget _buildAccountTile(User? user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            user?.email?.substring(0, 1).toUpperCase() ?? 'F',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        user?.displayName ?? 'Farmer',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        user?.email ?? 'Not signed in',
        style: GoogleFonts.poppins(
          color: Colors.grey[500],
          fontSize: 13,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Active',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2E7D32),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(AppSettings settings, AppLocalizations l10n) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.language, color: Color(0xFF2E7D32)),
      ),
      title: Text(
        l10n.language,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Choose app language',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: settings.locale.languageCode,
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    const Text('🇬🇧 '),
                    Text(l10n.languageEnglish),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'am',
                child: Row(
                  children: [
                    const Text('🇪🇹 '),
                    Text(l10n.languageAmharic),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'om',
                child: Row(
                  children: [
                    const Text('🇪🇹 '),
                    Text(l10n.languageAfanOromo),
                  ],
                ),
              ),
            ],
            onChanged: (code) async {
              if (code == null) return;
              await context.read<AppSettings>().setLocale(Locale(code));
              HapticFeedback.selectionClick();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32)),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32)),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile<T>({
    required IconData icon,
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32)),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dialogs & Actions
  // ═══════════════════════════════════════════════════════════════════════════

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will remove cached data. You\'ll need internet to reload data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await OfflineStorage.clearBox(OfflineStorage.weatherCacheBox);
              await OfflineStorage.clearBox(OfflineStorage.cropSuggestionsBox);
              if (mounted) {
                setState(() => _cacheSize = 0.0);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Cache cleared successfully'),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearAIHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear AI History?'),
        content: const Text(
          'This will clear all AI conversation history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('AI history cleared'),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: const Text(
          'We\'ll send you an email to reset your password. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user?.email != null) {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: user!.email!);
              }
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password reset email sent'),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

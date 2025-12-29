import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/services/offline_storage.dart';
import '../../core/services/connectivity_service.dart';
import '../../l10n/app_localizations.dart';
import '../../auth/login/login.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _analyticsEnabled = true;
  bool _locationEnabled = true;
  bool _dataSharingEnabled = false;
  bool _offlineModeOnly = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final connectivity = Provider.of<ConnectivityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.privacySettings),
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Data Collection Section
          _buildSectionHeader(loc.dataCollection, Icons.analytics),
          const SizedBox(height: 8),
          _buildSettingCard(
            title: loc.usageAnalytics,
            subtitle: loc.usageAnalyticsDesc,
            icon: Icons.bar_chart,
            value: _analyticsEnabled,
            onChanged: (value) => setState(() => _analyticsEnabled = value),
          ),
          _buildSettingCard(
            title: loc.locationAccess,
            subtitle: loc.locationAccessDesc,
            icon: Icons.location_on,
            value: _locationEnabled,
            onChanged: (value) => setState(() => _locationEnabled = value),
          ),
          _buildSettingCard(
            title: loc.dataSharing,
            subtitle: loc.dataSharingDesc,
            icon: Icons.share,
            value: _dataSharingEnabled,
            onChanged: (value) => setState(() => _dataSharingEnabled = value),
          ),

          const SizedBox(height: 24),

          // Offline Mode Section
          _buildSectionHeader(loc.offlineMode, Icons.cloud_off),
          const SizedBox(height: 8),
          _buildSettingCard(
            title: loc.offlineModeOnly,
            subtitle: loc.offlineModeOnlyDesc,
            icon: Icons.wifi_off,
            value: _offlineModeOnly,
            onChanged: (value) => setState(() => _offlineModeOnly = value),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.sync, color: Color(0xFF37474F)),
              title: Text(loc.syncStatus),
              subtitle: Text(
                connectivity.isOnline ? loc.online : loc.offline,
                style: TextStyle(
                  color: connectivity.isOnline ? Colors.green : Colors.orange,
                ),
              ),
              trailing: connectivity.isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionHeader(loc.dataManagement, Icons.folder),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Color(0xFF37474F)),
                  title: Text(loc.exportData),
                  subtitle: Text(loc.exportDataDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep, color: Colors.orange),
                  title: Text(loc.clearLocalData),
                  subtitle: Text(loc.clearLocalDataDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _clearLocalData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    loc.deleteAccount,
                    style: const TextStyle(color: Colors.red),
                  ),
                  subtitle: Text(loc.deleteAccountDesc),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Consent Information
          _buildSectionHeader(loc.consentInfo, Icons.info),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.dataWeCollect,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildConsentItem(Icons.person, loc.profileInfo),
                  _buildConsentItem(Icons.location_on, loc.locationData),
                  _buildConsentItem(Icons.grass, loc.farmData),
                  _buildConsentItem(Icons.analytics, loc.usageData),
                  const SizedBox(height: 16),
                  Text(
                    loc.howWeUseData,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.dataUsageDesc,
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showPrivacyPolicy,
                          child: Text(loc.privacyPolicy),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showTermsOfService,
                          child: Text(loc.termsOfService),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF37474F)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF37474F),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF37474F)),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF37474F),
      ),
    );
  }

  Widget _buildConsentItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final loc = AppLocalizations.of(context);
    
    // Show progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(loc.exportingData),
          ],
        ),
      ),
    );

    // Simulate export
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.dataExported)),
      );
    }
  }

  Future<void> _clearLocalData() async {
    final loc = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.clearLocalData),
        content: Text(loc.clearLocalDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(loc.clear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear all Hive boxes
      await OfflineStorage.clearBox(OfflineStorage.cropSuggestionsBox);
      await OfflineStorage.clearBox(OfflineStorage.diseaseResultsBox);
      await OfflineStorage.clearBox(OfflineStorage.weatherCacheBox);
      await OfflineStorage.clearBox(OfflineStorage.marketPricesBox);
      await OfflineStorage.clearBox(OfflineStorage.knowledgeBaseBox);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.localDataCleared)),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final loc = AppLocalizations.of(context);
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(loc.deleteAccount),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.deleteAccountWarning,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(loc.deleteAccountDesc),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: loc.confirmPassword,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(loc.deleteAccount),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      await _deleteAccount(passwordController.text);
    }
  }

  Future<void> _deleteAccount(String password) async {
    final loc = AppLocalizations.of(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Deleting account...'),
          ],
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete Firestore data
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .delete();
      
      await FirebaseFirestore.instance
          .collection('user_data')
          .doc(user.uid)
          .delete();

      // Clear local data
      await OfflineStorage.clearBox(OfflineStorage.farmProfileBox);
      await OfflineStorage.clearBox(OfflineStorage.farmRecordsBox);
      await OfflineStorage.clearBox(OfflineStorage.syncQueueBox);

      // Delete Firebase Auth account
      await user.delete();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        // Navigate to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? loc.errorDeletingAccount),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorDeletingAccount),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).privacyPolicy),
        content: SingleChildScrollView(
          child: Text(_privacyPolicyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).termsOfService),
        content: SingleChildScrollView(
          child: Text(_termsOfServiceText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  static const String _privacyPolicyText = '''
Smart Gebere Privacy Policy

Last updated: December 2024

1. Information We Collect
- Profile information (name, phone number)
- Farm location and characteristics
- Crop and farming activity data
- Device information for app functionality

2. How We Use Your Information
- To provide personalized crop recommendations
- To improve our AI models and services
- To enable offline functionality
- To sync your data across devices

3. Data Storage
- Your data is stored securely in Firebase
- Local data is cached for offline access
- You can delete your data at any time

4. Your Rights
- Access your personal data
- Request data deletion
- Export your data
- Opt out of analytics

5. Contact Us
For privacy concerns, contact: privacy@smartgebere.com
''';

  static const String _termsOfServiceText = '''
Smart Gebere Terms of Service

Last updated: December 2024

1. Acceptance of Terms
By using Smart Gebere, you agree to these terms.

2. Use of Service
- The app provides agricultural guidance only
- AI recommendations are not guaranteed
- Consult local experts for critical decisions

3. User Responsibilities
- Provide accurate farm information
- Keep your account secure
- Use the app responsibly

4. Limitations
- Service provided "as is"
- No warranty of accuracy
- Not liable for crop losses

5. Modifications
We may update these terms at any time.

6. Contact
Questions: support@smartgebere.com
''';
}


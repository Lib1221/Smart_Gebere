import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_gebere/settings/app_settings.dart';
import 'package:smart_gebere/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.language,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: settings.locale.languageCode,
              items: [
                DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                DropdownMenuItem(value: 'am', child: Text(l10n.languageAmharic)),
                DropdownMenuItem(value: 'om', child: Text(l10n.languageAfanOromo)),
              ],
              onChanged: (code) async {
                if (code == null) return;
                await context.read<AppSettings>().setLocale(Locale(code));
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.save}: ${settings.locale.languageCode}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}



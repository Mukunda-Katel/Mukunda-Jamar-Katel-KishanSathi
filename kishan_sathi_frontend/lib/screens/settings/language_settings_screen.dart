import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_theme.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        title: Text(
          l10n.language,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _LanguageTile(
                  language: l10n.english,
                  locale: const Locale('en'),
                  currentLocale: localeProvider.locale,
                  onTap: () {
                    localeProvider.setLocale(const Locale('en'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language changed to ${l10n.english}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _LanguageTile(
                  language: l10n.nepali,
                  locale: const Locale('ne'),
                  currentLocale: localeProvider.locale,
                  onTap: () {
                    localeProvider.setLocale(const Locale('ne'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('भाषा ${l10n.nepali}मा परिवर्तन गरियो'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              localeProvider.locale.languageCode == 'en'
                  ? 'Select your preferred language for the app interface.'
                  : 'एप इन्टरफेसको लागि तपाईंको मनपर्ने भाषा चयन गर्नुहोस्।',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String language;
  final Locale locale;
  final Locale currentLocale;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.locale,
    required this.currentLocale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = locale.languageCode == currentLocale.languageCode;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.language,
          color: isSelected ? AppTheme.primaryGreen : Colors.grey[600],
        ),
      ),
      title: Text(
        language,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryGreen : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: AppTheme.primaryGreen,
            )
          : Icon(
              Icons.circle_outlined,
              color: Colors.grey[400],
            ),
      onTap: onTap,
    );
  }
}

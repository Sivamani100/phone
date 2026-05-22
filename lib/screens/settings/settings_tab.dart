import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dialer_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/colors.dart';
import '../../utils/localization.dart';
import '../onboarding/language_setup.dart';
import 'blocklist_screen.dart';
import '../splash/initial_splash.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  void _showThemeSelector(BuildContext context, ThemeProvider themeProvider, AppLocalization local) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            local.translate('themeLabel'),
            style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                activeColor: AppColors.accentPurple,
                title: Text('System Default', style: TextStyle(color: AppColors.textPrimary(context))),
                onChanged: (mode) {
                  if (mode != null) {
                    themeProvider.setThemeMode(mode);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                activeColor: AppColors.accentPurple,
                title: Text('Light Mode', style: TextStyle(color: AppColors.textPrimary(context))),
                onChanged: (mode) {
                  if (mode != null) {
                    themeProvider.setThemeMode(mode);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                activeColor: AppColors.accentPurple,
                title: Text('Dark Mode', style: TextStyle(color: AppColors.textPrimary(context))),
                onChanged: (mode) {
                  if (mode != null) {
                    themeProvider.setThemeMode(mode);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRateAppDialog(BuildContext context, AppLocalization local) {
    int rating = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Center(
                child: Text(
                  local.translate('rateTitle'),
                  style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.bold),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    local.translate('rateDesc'),
                    style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= rating;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            rating = starIndex;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSelected ? AppColors.starGold : AppColors.textSecondary(context).withOpacity(0.4),
                            size: 38,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    local.translate('cancel'),
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: rating == 0
                      ? null
                      : () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(local.translate('rateThanks')),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.callGreen,
                            ),
                          );
                        },
                  child: Text(
                    local.translate('ok'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accentPurple, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary(context),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary(context)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialerProvider = Provider.of<DialerProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final local = AppLocalization(localeProvider.locale);

    final String currentLang = localeProvider.locale.languageCode == 'hi'
        ? 'हिंदी (Hindi)'
        : localeProvider.locale.languageCode == 'pt'
            ? 'Português (Portuguese)'
            : 'English';

    final String currentTheme = themeProvider.themeMode == ThemeMode.system
        ? 'System Default'
        : themeProvider.themeMode == ThemeMode.dark
            ? 'Dark Mode'
            : 'Light Mode';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          local.translate('settings'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSettingsTile(
                      context: context,
                      icon: Icons.language_rounded,
                      title: local.translate('languageLabel'),
                      subtitle: currentLang,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LanguageSetup(isOnboarding: false),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context: context,
                      icon: Icons.brightness_6_rounded,
                      title: local.translate('themeLabel'),
                      subtitle: currentTheme,
                      onTap: () => _showThemeSelector(context, themeProvider, local),
                    ),
                    _buildSettingsTile(
                      context: context,
                      icon: Icons.block_flipped,
                      title: local.translate('blockedListLabel'),
                      subtitle: '${dialerProvider.blockedNumbers.length} contacts blocked',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BlocklistScreen()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context: context,
                      icon: Icons.share_rounded,
                      title: local.translate('shareAppLabel'),
                      subtitle: 'Invite your friends to use Callin',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sharing Callin App install link...'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.accentPurple,
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context: context,
                      icon: Icons.star_rate_rounded,
                      title: local.translate('rateAppLabel'),
                      subtitle: 'Give us feedback on Google Play Store',
                      onTap: () => _showRateAppDialog(context, local),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Reset/Onboarding Developer Utility Shortcut
                    TextButton.icon(
                      onPressed: () async {
                        await dialerProvider.resetOnboarding();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const InitialSplash()),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.warningOrange, size: 18),
                      label: const Text(
                        'Reset Onboarding (Developer Option)',
                        style: TextStyle(
                          color: AppColors.warningOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Version info footer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    Text(
                      local.translate('appName'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context).withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      local.translate('version'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context).withOpacity(0.5),
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
}

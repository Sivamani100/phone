import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dialer_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/colors.dart';
import '../../utils/localization.dart';
import '../onboarding/language_setup.dart';

class WelcomeSplash extends StatelessWidget {
  const WelcomeSplash({super.key});

  void _showPrivacyPolicySheet(BuildContext context, AppLocalization local) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppColors.border(context), width: 1.5),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.privacy_tip_rounded, color: AppColors.accentPurple, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    local.translate('privacyPolicy'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    '1. Information Collection\n'
                    'Callin accesses your local contacts list, phone permissions, and local SQLite log caches to function correctly. No personal metrics or sensitive contacts records are ever transmitted over external networks.\n\n'
                    '2. Local Processing\n'
                    'All calculations, T9 pattern parsing, blocklist filters, and history grouping are processed strictly on your local device. We are strongly committed to user privacy and secure local computations.\n\n'
                    '3. Third Party Ads\n'
                    'Callin incorporates simulated Google AdMob banner and interstitial advertisements for mock monetization. No sensitive private trackers are active.\n\n'
                    '4. Local Storage\n'
                    'App customization preferences (theme, language selection) are stored in standard device SharedPreferences caches, while history logs are managed in a local SQLite file callin_phone.db.\n\n'
                    'By tapping Agree & Continue, you signify your compliance with our policy rules and terms.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    local.translate('ok'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialerProvider = Provider.of<DialerProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final local = AppLocalization(localeProvider.locale);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13), // Deep Charcoal Black
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.3,
            colors: [
              Color(0xFF281E48), // Purple radial glow
              Color(0xFF0F0F13),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              children: [
                const Spacer(),
                
                // Hero Logo Icon with dynamic outline glow
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentPurple, AppColors.accentPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPurple.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                
                // Welcome Text Labels
                Text(
                  local.translate('splashWelcome'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    local.translate('splashDescription'),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.55),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const Spacer(),

                // Privacy Policy Link button
                GestureDetector(
                  onTap: () => _showPrivacyPolicySheet(context, local),
                  child: Text(
                    local.translate('privacyPolicy'),
                    style: const TextStyle(
                      color: AppColors.accentPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Aggregated Action Button Continue
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.accentPurple.withOpacity(0.4),
                    ),
                    onPressed: () {
                      dialerProvider.setWelcomeSeen();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LanguageSetup(isOnboarding: true)),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          local.translate('continueBtn'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dialer_provider.dart';
import '../../utils/colors.dart';
import 'welcome_splash.dart';
import '../onboarding/language_setup.dart';
import '../onboarding/permission_setup.dart';
import '../home/home_screen.dart';

class InitialSplash extends StatefulWidget {
  const InitialSplash({super.key});

  @override
  State<InitialSplash> createState() => _InitialSplashState();
}

class _InitialSplashState extends State<InitialSplash> {
  bool _minTimeElapsed = false;
  bool _providerReady = false;

  @override
  void initState() {
    super.initState();

    // Minimum display time for the splash screen
    Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() => _minTimeElapsed = true);
      _tryNavigate();
    });

    // Listen for the provider to finish loading SharedPreferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DialerProvider>(context, listen: false);
      if (provider.isInitialized) {
        setState(() => _providerReady = true);
        _tryNavigate();
      } else {
        // Poll until the provider signals it has loaded
        provider.addListener(_onProviderChange);
      }
    });
  }

  void _onProviderChange() {
    final provider = Provider.of<DialerProvider>(context, listen: false);
    if (provider.isInitialized && mounted) {
      provider.removeListener(_onProviderChange);
      setState(() => _providerReady = true);
      _tryNavigate();
    }
  }

  void _tryNavigate() {
    // Only navigate once BOTH the timer AND the provider are ready
    if (!_minTimeElapsed || !_providerReady || !mounted) return;

    final dialerProvider = Provider.of<DialerProvider>(context, listen: false);

    if (!dialerProvider.welcomeSplashSeen) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeSplash()),
      );
    } else if (!dialerProvider.languageSetupSeen) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LanguageSetup(isOnboarding: true)),
      );
    } else if (!dialerProvider.permissionSetupSeen) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionSetup()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    try {
      Provider.of<DialerProvider>(context, listen: false)
          .removeListener(_onProviderChange);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0E), // Ultra-premium pure black
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Callin Sleek Neon Dialer Logo Animation
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentPurple, AppColors.accentPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPurple.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Callin',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'NEXT-GEN DIALER',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accentPurple.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

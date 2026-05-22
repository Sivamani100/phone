import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/dialer_provider.dart';
import '../../utils/colors.dart';
import '../home/home_screen.dart';

class PermissionSetup extends StatelessWidget {
  const PermissionSetup({super.key});

  Widget _buildPermissionCard(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.accentPurple, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialerProvider = Provider.of<DialerProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Text(
                'Access Permissions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please authorize these settings to enable call records loading, contact searches, and cellular dial support.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Permissions List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPermissionCard(
                      context,
                      Icons.contacts_rounded,
                      'Read Contacts',
                      'Allows Callin to display all local records in the Contacts directory and search names via T9 keypad typing.',
                    ),
                    _buildPermissionCard(
                      context,
                      Icons.phone_rounded,
                      'Make Cellular Calls',
                      'Allows Callin to trigger direct calls and simulated call panels directly when clicking dialpad buttons.',
                    ),
                    _buildPermissionCard(
                      context,
                      Icons.history_rounded,
                      'Access Call Logs',
                      'Enables local call history indexing, groupings, and missed call notifications inside the Recents log tab.',
                    ),
                    _buildPermissionCard(
                      context,
                      Icons.settings_phone_rounded,
                      'Default Phone App',
                      'Allows Callin to fully manage incoming and outgoing calls, display custom call screens, and block numbers.',
                    ),
                  ],
                ),
              ),

              // Allow Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    // ✅ Mark permission setup as DONE first, before any OS operation
                    // that may restart the Activity (like requestSetAsDefaultDialer).
                    // This guarantees we never re-show onboarding on next cold start.
                    await dialerProvider.setPermissionSeen();

                    // Request real OS permissions
                    await [
                      Permission.contacts,
                      Permission.phone,
                      Permission.phone,
                    ].request();

                    // Request default dialer role — may restart the Activity on some ROMs
                    await dialerProvider.requestSetAsDefaultDialer();

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  },
                  child: const Text(
                    'Grant & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

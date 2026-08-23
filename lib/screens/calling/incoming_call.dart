import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dialer_provider.dart';
import '../../utils/colors.dart';
import '../../utils/glassmorphism.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerPhone;
  final String? avatarUrl;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerPhone,
    this.avatarUrl,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialerProvider = Provider.of<DialerProvider>(context);
    final avatarColor = AppColors.getAvatarColor(widget.callerName);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Stack(
        children: [
          // Blurred avatar background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.12),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                color: Colors.black.withOpacity(0.68),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status bar area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sim_card_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dialerProvider.simSelected,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Caller info and avatar
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pulsing avatar
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer pulse
                              Container(
                                width:
                                    160 + (50 * _pulseController.value),
                                height:
                                    160 + (50 * _pulseController.value),
                                decoration: BoxDecoration(
                                  color: avatarColor.withOpacity(
                                    0.08 * (1.0 - _pulseController.value),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Inner pulse
                              Container(
                                width:
                                    160 + (25 * _pulseController.value),
                                height:
                                    160 + (25 * _pulseController.value),
                                decoration: BoxDecoration(
                                  color: avatarColor.withOpacity(
                                    0.12 * (1.0 - _pulseController.value),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Avatar
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: avatarColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          avatarColor.withOpacity(0.5),
                                      blurRadius: 30,
                                      offset:
                                          const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  widget.callerName.isNotEmpty
                                      ? widget.callerName[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 40),

                      // Caller name
                      Text(
                        widget.callerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Caller phone
                      Text(
                        widget.callerPhone,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Status
                      Text(
                        'Incoming call',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons - Reject and Accept
                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    bottom: 60,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reject button
                      GestureDetector(
                        onTap: () {
                          dialerProvider.endCall();
                          Navigator.pop(context);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlassmorphicContainer(
                              blurStrength: 20,
                              opacity: 0.95,
                              backgroundColor:
                                  AppColors.hangupRed,
                              borderRadius:
                                  BorderRadius.circular(90),
                              padding:
                                  const EdgeInsets.all(22),
                              border: Border.all(
                                color: AppColors.hangupRed
                                    .withOpacity(0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.hangupRed
                                      .withOpacity(0.5),
                                  blurRadius: 28,
                                  offset:
                                      const Offset(0, 12),
                                ),
                              ],
                              child: const Icon(
                                Icons.call_end_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Reject',
                              style: TextStyle(
                                color: Colors.white
                                    .withOpacity(0.8),
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Accept button
                      GestureDetector(
                        onTap: () {
                          dialerProvider.answerCall();
                          Navigator.pop(context);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlassmorphicContainer(
                              blurStrength: 20,
                              opacity: 0.95,
                              backgroundColor:
                                  AppColors.callGreen,
                              borderRadius:
                                  BorderRadius.circular(90),
                              padding:
                                  const EdgeInsets.all(22),
                              border: Border.all(
                                color: AppColors.callGreen
                                    .withOpacity(0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.callGreen
                                      .withOpacity(0.5),
                                  blurRadius: 28,
                                  offset:
                                      const Offset(0, 12),
                                ),
                              ],
                              child: const Icon(
                                Icons.call_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Accept',
                              style: TextStyle(
                                color: Colors.white
                                    .withOpacity(0.8),
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

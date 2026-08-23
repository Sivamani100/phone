import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/glassmorphism.dart';

class SMSReplySheet extends StatefulWidget {
  final String callerName;
  final String callerPhone;

  const SMSReplySheet({
    super.key,
    required this.callerName,
    required this.callerPhone,
  });

  @override
  State<SMSReplySheet> createState() => _SMSReplySheetState();
}

class _SMSReplySheetState extends State<SMSReplySheet> {
  final List<String> _smsReplies = [
    "I'll call you back later.",
    "Can't talk now. What's up?",
    "Can't talk now. Call me back later.",
    "I'll be there soon.",
    "Custom",
  ];

  String? _selectedReply;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1E).withOpacity(0.95),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Close indicator
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'SMS reply',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // SMS options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: _smsReplies.map((reply) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedReply = reply);
                            // Handle SMS sending here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('SMS sent: $reply'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            Future.delayed(const Duration(milliseconds: 500), () {
                              Navigator.pop(context);
                            });
                          },
                          child: GlassmorphicContainer(
                            blurStrength: 12,
                            opacity: _selectedReply == reply ? 0.25 : 0.08,
                            backgroundColor: _selectedReply == reply
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: Border.all(
                              color: _selectedReply == reply
                                  ? const Color(0xFF22C55E)
                                      .withOpacity(0.4)
                                  : Colors.white.withOpacity(0.15),
                              width: 1.2,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reply,
                                    style: TextStyle(
                                      color: _selectedReply == reply
                                          ? Colors.white
                                          : Colors.white
                                              .withOpacity(0.85),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                if (_selectedReply == reply)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 12),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white.withOpacity(
                                        0.9,
                                      ),
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Cancel button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: GlassmorphicContainer(
                      blurStrength: 12,
                      opacity: 0.06,
                      backgroundColor: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.2,
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: const Color(0xFF22C55E),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

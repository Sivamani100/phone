import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dialer_provider.dart';
import '../../utils/colors.dart';

class ActiveCall extends StatefulWidget {
  const ActiveCall({super.key});

  @override
  State<ActiveCall> createState() => _ActiveCallState();
}

class _ActiveCallState extends State<ActiveCall> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showKeypad = false;
  String _dtmfInput = '';
  bool _isRecording = false;

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

  String _formatTimer(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildKeypadButton(
    String digit,
    String sub,
    DialerProvider dialerProvider,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _dtmfInput += digit;
          });
          // Send real DTMF tone to the active call
          dialerProvider.playDtmfTone(digit);
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridAction(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: icon == Icons.fiber_manual_record_rounded && isActive
                  ? Colors.red
                  : (isActive ? const Color(0xFF0F0F13) : Colors.white),
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Returns true when a call is ringing/incoming and needs the Answer+Reject UI.
  bool _isIncomingRinging(String state) =>
      state == 'ringing' || state == 'incoming';

  @override
  Widget build(BuildContext context) {
    final dialerProvider = Provider.of<DialerProvider>(context);
    final avatarColor = AppColors.getAvatarColor(dialerProvider.activeCallerName);
    final callState = dialerProvider.activeCallState;
    final isRinging = _isIncomingRinging(callState);

    // Formatting caller state message
    String callStateMessage;
    switch (callState) {
      case 'dialing':
        callStateMessage = 'Dialing...';
        break;
      case 'ringing':
        callStateMessage = 'Incoming Call';
        break;
      case 'incoming':
        callStateMessage = 'Incoming Call';
        break;
      case 'connected':
        callStateMessage = 'Connected';
        break;
      case 'hold':
        callStateMessage = 'Call on Hold';
        break;
      default:
        callStateMessage = callState.toUpperCase();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Stack(
        children: [
          // 1. Blurred Avatar Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.15),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
              child: Container(
                color: Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          // 2. Main calling UI content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  
                  // Selected SIM Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sim_card_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          dialerProvider.simSelected,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Dialer Name Label
                  Text(
                    dialerProvider.activeCallerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Phone number
                  Text(
                    dialerProvider.activeCallerPhone,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 3. Central Pulsing Profile Avatar (Shown only when in-call DTMF Keypad is hidden)
                  if (!_showKeypad)
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing wave 2
                                Container(
                                  width: 140 + (40 * _pulseController.value),
                                  height: 140 + (40 * _pulseController.value),
                                  decoration: BoxDecoration(
                                    color: avatarColor.withOpacity(0.1 * (1.0 - _pulseController.value)),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // Pulsing wave 1
                                Container(
                                  width: 140 + (20 * _pulseController.value),
                                  height: 140 + (20 * _pulseController.value),
                                  decoration: BoxDecoration(
                                    color: avatarColor.withOpacity(0.15 * (1.0 - _pulseController.value)),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // Central Static Avatar
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: avatarColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: avatarColor.withOpacity(0.4),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    dialerProvider.activeCallerName.isNotEmpty
                                        ? dialerProvider.activeCallerName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    )
                  else
                    // DTMF Keypad Panel
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 40,
                              alignment: Alignment.centerRight,
                              child: Text(
                                _dtmfInput,
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                _buildKeypadButton('1', '', dialerProvider),
                                _buildKeypadButton('2', 'ABC', dialerProvider),
                                _buildKeypadButton('3', 'DEF', dialerProvider),
                              ],
                            ),
                            Row(
                              children: [
                                _buildKeypadButton('4', 'GHI', dialerProvider),
                                _buildKeypadButton('5', 'JKL', dialerProvider),
                                _buildKeypadButton('6', 'MNO', dialerProvider),
                              ],
                            ),
                            Row(
                              children: [
                                _buildKeypadButton('7', 'PQRS', dialerProvider),
                                _buildKeypadButton('8', 'TUV', dialerProvider),
                                _buildKeypadButton('9', 'WXYZ', dialerProvider),
                              ],
                            ),
                            Row(
                              children: [
                                _buildKeypadButton('*', '', dialerProvider),
                                _buildKeypadButton('0', '+', dialerProvider),
                                _buildKeypadButton('#', '', dialerProvider),
                              ],
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => setState(() => _showKeypad = false),
                              child: const Text('Hide Keypad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Call State / Duration Timer Display
                  Column(
                    children: [
                      Text(
                        callStateMessage,
                        style: TextStyle(
                          color: callState == 'hold'
                              ? AppColors.warningOrange
                              : isRinging
                                  ? const Color(0xFF4ADE80)
                                  : Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (callState == 'connected' || callState == 'hold' || callState == 'disconnected') ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatTimer(dialerProvider.callDurationSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 36),

                  // ── 4A. Outgoing/Active call actions grid ──────────────────
                  // Only shown when NOT in ringing/incoming state and NOT typing DTMF
                  if (!isRinging && !_showKeypad) ...[
                    // Row 1: Mute · Keypad · Speaker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildGridAction(
                          context,
                          Icons.mic_off_rounded,
                          dialerProvider.isMuted ? 'Unmute' : 'Mute',
                          dialerProvider.isMuted,
                          () => dialerProvider.toggleMute(),
                        ),
                        _buildGridAction(
                          context,
                          Icons.dialpad_rounded,
                          'Keypad',
                          false,
                          () => setState(() => _showKeypad = true),
                        ),
                        _buildGridAction(
                          context,
                          Icons.volume_up_rounded,
                          dialerProvider.isSpeakerOn ? 'Speaker On' : 'Speaker',
                          dialerProvider.isSpeakerOn,
                          () => dialerProvider.toggleSpeaker(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Row 2: Hold · Add Call · Record
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildGridAction(
                          context,
                          Icons.pause_rounded,
                          dialerProvider.isOnHold ? 'Resume' : 'Hold',
                          dialerProvider.isOnHold,
                          () => dialerProvider.toggleHold(),
                        ),
                        _buildGridAction(
                          context,
                          Icons.add_ic_call_rounded,
                          'Add Call',
                          false,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Add Call: put current call on hold first.'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        _buildGridAction(
                          context,
                          Icons.fiber_manual_record_rounded,
                          _isRecording ? 'Stop Rec' : 'Record',
                          _isRecording,
                          () {
                            setState(() => _isRecording = !_isRecording);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isRecording ? '🔴 Recording started' : '⏹ Recording stopped',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],

                  // ── 5. Bottom Action Buttons ───────────────────────────
                  if (isRinging) ...[
                    // ── INCOMING CALL: Answer (green) + Reject (red) ──────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // REJECT button
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () => dialerProvider.endCall(),
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: AppColors.hangupRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.hangupRed.withOpacity(0.55),
                                        blurRadius: 22,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Decline',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          // ANSWER button
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () => dialerProvider.answerCall(),
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: AppColors.callGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.callGreen.withOpacity(0.55),
                                        blurRadius: 22,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.call_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Answer',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // ── OUTGOING / ACTIVE CALL: End Call button only ──────
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => dialerProvider.endCall(),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.hangupRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.hangupRed.withOpacity(0.55),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'End Call',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

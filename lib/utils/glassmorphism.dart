import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphic Container - Frosted glass effect
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double blurStrength;
  final double opacity;
  final BorderRadius borderRadius;
  final Border? border;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color backgroundColor;
  final List<BoxShadow>? boxShadow;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.blurStrength = 10.0,
    this.opacity = 0.1,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.border,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(opacity),
              border: border ?? Border.all(
                color: Colors.white.withOpacity(0.15),
              ),
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glassmorphic Button - For call control buttons
class GlassmorphicButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool isActive;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Color iconColor;

  const GlassmorphicButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.size = 70,
    this.activeColor = const Color(0xFFFFFFFF),
    this.inactiveColor = const Color(0x1AFFFFFF),
    this.iconColor = const Color(0xFFFFFFFF),
  });

  @override
  State<GlassmorphicButton> createState() => _GlassmorphicButtonState();
}

class _GlassmorphicButtonState extends State<GlassmorphicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassmorphicContainer(
              blurStrength: 12,
              opacity: widget.isActive ? 0.3 : 0.08,
              backgroundColor: widget.isActive
                  ? widget.activeColor
                  : widget.inactiveColor,
              borderRadius: BorderRadius.circular(widget.size / 2),
              padding: EdgeInsets.all(widget.size / 3.5),
              margin: EdgeInsets.zero,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor,
                size: widget.size / 2.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Glassmorphic Keypad Button - For dialer numbers
class GlassmorphicKeypadButton extends StatefulWidget {
  final VoidCallback onTap;
  final String digit;
  final String letters;

  const GlassmorphicKeypadButton({
    super.key,
    required this.onTap,
    required this.digit,
    this.letters = '',
  });

  @override
  State<GlassmorphicKeypadButton> createState() =>
      _GlassmorphicKeypadButtonState();
}

class _GlassmorphicKeypadButtonState extends State<GlassmorphicKeypadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GlassmorphicContainer(
          blurStrength: 15,
          opacity: 0.12,
          backgroundColor: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1.2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.digit,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.letters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.letters,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

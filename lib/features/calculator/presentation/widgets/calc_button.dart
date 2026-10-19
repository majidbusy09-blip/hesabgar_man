import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalcButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isEqual;
  final bool isScientific;
  final bool isMemory;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isOperator = false,
    this.isEqual = false,
    this.isScientific = false,
    this.isMemory = false,
  });

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    _controller.forward();
    if (widget.isEqual) {
      HapticFeedback.mediumImpact();
    } else if (widget.isOperator) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _release() {
    _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;

    if (widget.isEqual) {
      bgColor = scheme.primary;
      textColor = scheme.onPrimary;
    } else if (widget.isOperator) {
      bgColor = scheme.secondary;
      textColor = scheme.onSecondary;
    } else if (widget.isMemory) {
      bgColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0);
      textColor = isDark ? Colors.amber : Colors.brown;
    } else if (widget.isScientific) {
      bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);
      textColor = isDark ? Colors.white70 : Colors.black87;
    } else {
      bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        elevation: widget.isEqual ? 2 : 0,
        shadowColor: scheme.primary.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTapDown: (_) => _press(),
          onTapUp: (_) => _release(),
          onTapCancel: () => _controller.reverse(),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize:
                        widget.isScientific || widget.isMemory ? 12 : 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

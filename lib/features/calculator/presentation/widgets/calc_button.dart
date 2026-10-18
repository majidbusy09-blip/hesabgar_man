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

class _CalcButtonState extends State<CalcButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 60));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor;
    Color textColor;

    if (widget.isEqual) {
      bgColor = const Color(0xFF2A9D8F);
      textColor = Colors.white;
    } else if (widget.isOperator) {
      bgColor = const Color(0xFFE76F51);
      textColor = Colors.white;
    } else if (widget.isMemory) {
      bgColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0);
      textColor = isDark ? Colors.amber : Colors.brown;
    } else if (widget.isScientific) {
      bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);
      textColor = isDark ? Colors.white70 : Colors.black87;
    } else {
      bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) {
          _controller.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: widget.isScientific || widget.isMemory ? 14 : 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

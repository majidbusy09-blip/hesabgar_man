import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class CalcButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isEqual;
  final bool isWide;
  final bool isScientific;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isOperator = false,
    this.isEqual = false,
    this.isWide = false,
    this.isScientific = false,
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
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    if (widget.isEqual) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else if (widget.isOperator) {
      bg = isDark
          ? AppColors.primaryLight.withValues(alpha: 0.25)
          : AppColors.primaryLight.withValues(alpha: 0.2);
      fg = isDark ? AppColors.primaryLight : AppColors.primary;
    } else if (widget.isScientific) {
      bg = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
      fg = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    } else {
      bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
      fg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
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
          width: widget.isWide ? double.infinity : null,
          height: 64,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: widget.isScientific ? 16 : 22,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

class _CalcButtonState extends State<CalcButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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

    // تعیین رنگ‌ها با گرادیانت
    List<Color> gradientColors;
    Color textColor;

    if (widget.isEqual) {
      // دکمه مساوی: سبز شاد
      gradientColors = [const Color(0xFF2A9D8F), const Color(0xFF21867A)];
      textColor = Colors.white;
    } else if (widget.isOperator) {
      // دکمه‌های عملیات: نارنجی
      gradientColors = [const Color(0xFFE76F51), const Color(0xFFD65A3B)];
      textColor = Colors.white;
    } else if (widget.isScientific) {
      // دکمه‌های مهندسی: خاکستری تیره
      gradientColors = isDark 
          ? [const Color(0xFF333333), const Color(0xFF222222)]
          : [const Color(0xFFE0E0E0), const Color(0xFFCCCCCC)];
      textColor = isDark ? Colors.white70 : Colors.black87;
    } else {
      // دکمه‌های اعداد: ظاهر شیشه‌ای
      gradientColors = isDark 
          ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
          : [Colors.white, const Color(0xFFF0F0F0)];
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) {
          _controller.forward();
          HapticFeedback.mediumImpact();
        },
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          width: widget.isWide ? double.infinity : null,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: widget.isScientific ? 18 : 26,
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

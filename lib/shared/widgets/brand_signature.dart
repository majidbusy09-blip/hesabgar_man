import 'package:flutter/material.dart';

/// امضای بصری اپ — برای اسپلش و درباره
class BrandSignature extends StatelessWidget {
  final bool compact;
  final Color? textColor;

  const BrandSignature({super.key, this.compact = false, this.textColor});

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/brand/app_icon.png',
          width: compact ? 72 : 120,
          height: compact ? 72 : 120,
          errorBuilder: (_, __, ___) => Icon(
            Icons.calculate_rounded,
            size: compact ? 72 : 120,
            color: color,
          ),
        ),
        SizedBox(height: compact ? 12 : 20),
        Text(
          'حسابگر من',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: compact ? 22 : 32,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'هوشمند · مالی · دانش‌آموزی',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: compact ? 12 : 14,
            color: color.withValues(alpha: 0.9),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 16),
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ساخته‌شده با دقت برای تو',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: color.withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );
  }
}

/// صفحه شروع کوتاه با امضای برند
class BrandSplash extends StatefulWidget {
  final Widget child;
  const BrandSplash({super.key, required this.child});

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    _c.forward();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9660), Color(0xFFFF6B45)],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: const Center(child: BrandSignature()),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/brand.dart';

/// Your CUT logo file (JPG). Until it exists a placeholder crest is drawn.
const String kLogoAsset = 'assets/images/cut_logo.jpg';

/// The logo on its own - used on the white screens (login, reset, etc.).
class CutLogo extends StatelessWidget {
  const CutLogo({super.key, this.height = 64});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Central University of Technology logo',
      image: true,
      child: Image.asset(
        kLogoAsset,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => _PlaceholderCrest(size: height),
      ),
    );
  }
}

/// Logo on a white rounded tile - used on the blue headers, splash and app bars.
class CutLogoBadge extends StatelessWidget {
  const CutLogoBadge({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.15),
        child: CutLogo(height: size * 0.8),
      ),
    );
  }
}

/// AppBar with the CUT logo on the right - used on every pushed screen.
PreferredSizeWidget cutAppBar(String title) {
  return AppBar(
    title: Text(title),
    actions: const [
      Padding(
        padding: EdgeInsets.only(right: 12),
        child: Center(child: CutLogoBadge(size: 36)),
      ),
    ],
  );
}

class _PlaceholderCrest extends StatelessWidget {
  const _PlaceholderCrest({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.85, size),
      painter: _CrestPainter(),
    );
  }
}

class _CrestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final shield = Path()
      ..moveTo(w * 0.08, h * 0.04)
      ..lineTo(w * 0.92, h * 0.04)
      ..lineTo(w * 0.92, h * 0.55)
      ..quadraticBezierTo(w * 0.92, h * 0.86, w * 0.5, h * 0.98)
      ..quadraticBezierTo(w * 0.08, h * 0.86, w * 0.08, h * 0.55)
      ..close();
    canvas.drawPath(shield, Paint()..color = CutColors.red);
    final c = Offset(w * 0.5, h * 0.46);
    canvas.drawCircle(c, w * 0.3, Paint()..color = CutColors.gold);
    canvas.drawCircle(c, w * 0.22, Paint()..color = CutColors.blue);
    canvas.drawCircle(c, w * 0.09, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
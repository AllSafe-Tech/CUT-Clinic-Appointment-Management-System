import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/brand.dart';
import 'cut_logo.dart';

/// Save a CUT campus photo here (JPG, about 1200 px wide):
///   assets/images/cut_campus.jpg
/// Until it exists a blue gradient is shown instead.
const String kCampusAsset = 'assets/images/cut_campus.jpg';

/// Home screen hero: campus photo with a CUT-blue tint, logo and greeting.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    this.height = 300,
  });

  final String title;
  final String subtitle;
  final Widget leading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              kCampusAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stack) => const _HeroFallback(),
            ),
            // CUT-blue tint over the photo (darker at the top for readability)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CutColors.blueDark.withAlpha(225),
                    CutColors.blue.withAlpha(160),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, top + 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CutLogoBadge(size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CENTRAL UNIVERSITY OF TECHNOLOGY',
                              style: t.labelSmall?.copyWith(
                                color: CutColors.gold,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('Student Clinic',
                                style: t.bodySmall?.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      leading,
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(subtitle,
                                style: t.bodyMedium?.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CutColors.blueDark, CutColors.blue],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(14),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -60,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
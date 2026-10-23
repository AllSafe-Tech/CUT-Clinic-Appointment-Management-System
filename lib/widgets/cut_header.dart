import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/brand.dart';
import 'cut_logo.dart';

/// Blue header with the CUT logo, used at the top of every main screen.
/// Pass [onBack] to show a back arrow (for screens opened from Home).
class CutHeader extends StatelessWidget {
  const CutHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: t.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: t.bodyMedium?.copyWith(color: Colors.white70)),
        ],
        const SizedBox(height: 14),
        Container(
          height: 4,
          width: 44,
          decoration: BoxDecoration(
            color: CutColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CutColors.blueDark, CutColors.blue],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onBack != null) ...[
                      Material(
                        color: Colors.white.withAlpha(30),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Back to home',
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const CutLogoBadge(size: 46),
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
                const SizedBox(height: 22),
                if (leading != null)
                  Row(children: [
                    leading!,
                    const SizedBox(width: 16),
                    Expanded(child: titleBlock),
                  ])
                else
                  titleBlock,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../widgets/cut_logo.dart';

/// Welcome page shown to signed-out users (Figma: Splash).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CutColors.blueDark, CutColors.blue],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: -90, right: -70, child: _Bubble(size: 260, opacity: 0.06)),
            const Positioned(top: 170, left: -100, child: _Bubble(size: 210, opacity: 0.05)),
            const Positioned(bottom: -120, left: -60, child: _Bubble(size: 300, opacity: 0.06)),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, child) => Opacity(
                                opacity: v,
                                child: Transform.translate(
                                  offset: Offset(0, 24 * (1 - v)),
                                  child: child,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Spacer(flex: 2),
                                  const CutLogoBadge(size: 124),
                                  const SizedBox(height: 30),
                                  Text(
                                    'CUT CLINIC',
                                    textAlign: TextAlign.center,
                                    style: t.headlineLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 4,
                                      fontSize: 34,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 3,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white54,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'YOUR HEALTH, OUR PRIORITY',
                                    textAlign: TextAlign.center,
                                    style: t.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2.2,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Book and manage your clinic appointments',
                                    textAlign: TextAlign.center,
                                    style: t.bodyMedium?.copyWith(color: Colors.white70),
                                  ),
                                  const Spacer(flex: 3),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _Feature(
                                          icon: Icons.event_available_rounded,
                                          label: 'Easy booking'),
                                      _Feature(
                                          icon: Icons.track_changes_rounded,
                                          label: 'Live status'),
                                      _Feature(
                                          icon: Icons.notifications_active_outlined,
                                          label: 'Reminders'),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  _GetStartedButton(onPressed: onContinue),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Central University of Technology, Free State',
                                    textAlign: TextAlign.center,
                                    style: t.bodySmall?.copyWith(color: Colors.white60),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha((opacity * 255).round()),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.white70)),
      ],
    );
  }
}

class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(31),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(31),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                children: [
                  const SizedBox(width: 44),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          color: CutColors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: const BoxDecoration(
                      color: CutColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
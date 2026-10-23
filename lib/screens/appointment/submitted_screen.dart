import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../widgets/cut_logo.dart';

class SubmittedScreen extends StatelessWidget {
  const SubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: CutLogo(height: 72)),
                  const SizedBox(height: 36),
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: const BoxDecoration(
                          color: CutColors.blue, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          size: 72, color: Color(0xFF4CD964)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Request submitted',
                      textAlign: TextAlign.center,
                      style: t.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800, color: CutColors.blue)),
                  const SizedBox(height: 10),
                  Text(
                    'The clinic will review your request and assign your date and '
                    'time. You will be notified by SMS/email.',
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodyLarge
                        ?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Back to home'),
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
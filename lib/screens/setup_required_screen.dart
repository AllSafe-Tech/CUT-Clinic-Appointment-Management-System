import 'package:flutter/material.dart';

class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.settings_suggest_rounded, size: 56, color: t.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Supabase is not configured', style: t.textTheme.headlineSmall),
              const SizedBox(height: 12),
              const Text('Copy env.example.json to env.json, fill in your Supabase '
                  'URL and anon key, then run:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SelectableText(
                  'flutter run --dart-define-from-file=env.json',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

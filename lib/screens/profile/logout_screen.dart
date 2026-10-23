import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';
import '../../widgets/pill_button.dart';

/// Figma: Logout confirmation.
class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  bool _busy = false;

  Future<void> _logout() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    try {
      await ClinicService.signOut();
      navigator.popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: CutColors.blue,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: CutLogo(height: 80)),
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      height: 96,
                      width: 96,
                      decoration: const BoxDecoration(
                          color: CutColors.blue, shape: BoxShape.circle),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 44),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Log out',
                      textAlign: TextAlign.center,
                      style: t.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800, color: CutColors.blue)),
                  const SizedBox(height: 8),
                  Text('Are you sure you want to log out of CUT Clinic?',
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodyLarge
                          ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      PillButton(
                        label: 'Cancel',
                        icon: Icons.close_rounded,
                        onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      ),
                      PillButton(
                        label: 'Log out',
                        icon: Icons.logout_rounded,
                        color: CutColors.red,
                        filled: true,
                        busy: _busy,
                        onPressed: _busy ? null : _logout,
                      ),
                    ],
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
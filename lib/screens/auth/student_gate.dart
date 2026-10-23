import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../models/student_profile.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../home/home_shell.dart';

/// Loads the student profile after login. Accounts without a student record
/// (e.g. clinic staff) are refused: staff use the web app (FR6, IR15).
class StudentGate extends StatefulWidget {
  const StudentGate({super.key});

  @override
  State<StudentGate> createState() => _StudentGateState();
}

class _StudentGateState extends State<StudentGate> {
  late Future<StudentProfile?> _future = ClinicService.fetchProfile();

  void _retry() => setState(() => _future = ClinicService.fetchProfile());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentProfile?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            body: ErrorView(message: friendlyError(snap.error!), onRetry: _retry),
          );
        }
        final profile = snap.data;
        if (profile == null) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const EmptyState(
                      icon: Icons.block_rounded,
                      title: 'This app is for CUT students',
                      subtitle: 'No student account was found for this login. '
                          'Clinic staff should use the clinic web application.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: ClinicService.signOut,
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return HomeShell(profile: profile);
      },
    );
  }
}

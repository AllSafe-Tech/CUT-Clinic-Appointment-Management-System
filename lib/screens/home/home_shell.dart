import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../models/appointment.dart';
import '../../models/student_profile.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../appointment/my_appointment_page.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import 'dashboard_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.profile});

  final StudentProfile profile;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late StudentProfile _profile = widget.profile;
  late Stream<List<Appointment>> _stream = ClinicService.watchAppointments();

  void _retry() => setState(() => _stream = ClinicService.watchAppointments());

  Future<void> _refreshProfile() async {
    try {
      final p = await ClinicService.fetchProfile();
      if (p != null && mounted) setState(() => _profile = p);
    } catch (_) {
      // keep showing the last known profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Appointment>>(
      stream: _stream,
      builder: (context, snap) {
        final list = snap.data ?? const <Appointment>[];
        final loading = !snap.hasData && !snap.hasError;

        Widget body;
        if (snap.hasError && !snap.hasData) {
          body = SafeArea(
            child: ErrorView(message: friendlyError(snap.error!), onRetry: _retry),
          );
        } else if (loading) {
          body = const SafeArea(child: Center(child: CircularProgressIndicator()));
        } else {
          switch (_index) {
            case 0:
              body = DashboardPage(
                profile: _profile,
                appointments: list,
                onOpenTab: (i) => setState(() => _index = i),
              );
              break;
            case 1:
              body = MyAppointmentPage(appointments: list);
              break;
            case 2:
              body = const NotificationsPage();
              break;
            default:
              body = ProfilePage(profile: _profile, onProfileChanged: _refreshProfile);
          }
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.event_outlined),
                  selectedIcon: Icon(Icons.event_rounded),
                  label: 'Appointment'),
              NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications_rounded),
                  label: 'Alerts'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}
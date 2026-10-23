import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../models/appointment.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import 'my_appointment_page.dart';

/// "My Appointment" opened from the Home buttons (with a back arrow to Home).
class MyAppointmentScreen extends StatefulWidget {
  const MyAppointmentScreen({super.key});

  @override
  State<MyAppointmentScreen> createState() => _MyAppointmentScreenState();
}

class _MyAppointmentScreenState extends State<MyAppointmentScreen> {
  late Stream<List<Appointment>> _stream = ClinicService.watchAppointments();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Appointment>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError && !snap.hasData) {
            return SafeArea(
              child: ErrorView(
                message: friendlyError(snap.error!),
                onRetry: () =>
                    setState(() => _stream = ClinicService.watchAppointments()),
              ),
            );
          }
          if (!snap.hasData) {
            return const SafeArea(child: Center(child: CircularProgressIndicator()));
          }
          return MyAppointmentPage(
            appointments: snap.data!,
            onBack: () => Navigator.of(context).maybePop(),
          );
        },
      ),
    );
  }
}
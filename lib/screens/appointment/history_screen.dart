import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../models/appointment.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Stream<List<Appointment>> _stream = ClinicService.watchAppointments();
  AppointmentStatus? _filter; // null = all

  static const _filters = <String, AppointmentStatus?>{
    'All': null,
    'Completed': AppointmentStatus.completed,
    'Cancelled': AppointmentStatus.cancelled,
    'Not approved': AppointmentStatus.rejected,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: cutAppBar('Past appointments'),
      body: StreamBuilder<List<Appointment>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError && !snap.hasData) {
            return ErrorView(
              message: friendlyError(snap.error!),
              onRetry: () => setState(() => _stream = ClinicService.watchAppointments()),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final past = snap.data!.where((a) => !a.isActive).toList();
          final shown =
              _filter == null ? past : past.where((a) => a.status == _filter).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final e in _filters.entries)
                    ChoiceChip(
                      label: Text(e.key),
                      selected: _filter == e.value,
                      onSelected: (_) => setState(() => _filter = e.value),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No past appointments',
                    subtitle: 'Completed and cancelled appointments will appear here.',
                  ),
                )
              else
                for (final a in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppointmentCard(appointment: a),
                  ),
            ],
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../models/appointment.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_header.dart';
import '../../widgets/pill_button.dart';
import 'history_screen.dart';

/// Shows status, assigned date/time and the cancel action (FR15-FR17).
class MyAppointmentPage extends StatefulWidget {
  const MyAppointmentPage({super.key, required this.appointments, this.onBack});

  final List<Appointment> appointments;

  /// Shows a back arrow in the header and calls this when it is tapped.
  final VoidCallback? onBack;

  @override
  State<MyAppointmentPage> createState() => _MyAppointmentPageState();
}

class _MyAppointmentPageState extends State<MyAppointmentPage> {
  bool _busy = false;

  Future<void> _cancel(Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('The clinic will be told your appointment is cancelled. '
            'You can then submit a new request.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                minimumSize: const Size(120, 44), backgroundColor: CutColors.red),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ClinicService.cancelAppointment(a.id);
      if (mounted) showInfo(context, 'Appointment cancelled.');
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final list = widget.appointments;
    final a = list.where((x) => x.isActive).firstOrNull ?? list.firstOrNull;

    if (a == null) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          CutHeader(
            title: 'My appointment',
            onBack: widget.onBack,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No appointments yet',
              subtitle: 'Request an appointment from the Home tab.',
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        CutHeader(
          title: 'My appointment',
          onBack: widget.onBack,
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 6, color: a.status.color),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusChip(status: a.status),
                              const SizedBox(height: 12),
                              Text(a.status.description, style: t.textTheme.bodyLarge),
                              const Divider(height: 28),
                              InfoRow(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Date',
                                  value: a.dateText),
                              InfoRow(
                                  icon: Icons.access_time_rounded,
                                  label: 'Time',
                                  value: a.timeText),
                              InfoRow(
                                  icon: Icons.medical_information_outlined,
                                  label: 'Reason',
                                  value: (a.notes ?? '').isEmpty ? '-' : a.notes!),
                              InfoRow(
                                  icon: Icons.send_rounded,
                                  label: 'Requested',
                                  value: formatDateTime(a.createdAt)),
                              InfoRow(
                                  icon: Icons.update_rounded,
                                  label: 'Last updated',
                                  value: formatDateTime(a.updatedAt)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Progress'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StatusTimeline(status: a.status),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (a.canCancel)
                    PillButton(
                      label: 'Cancel appointment',
                      icon: Icons.close_rounded,
                      color: CutColors.red,
                      busy: _busy,
                      onPressed: _busy ? null : () => _cancel(a),
                    ),
                  PillButton(
                    label: 'Past appointments',
                    icon: Icons.history_rounded,
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  ),
                ],
              ),
              if (a.canCancel)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    'Need a different time? Clinic staff handle rescheduling and will '
                    'notify you of any change.',
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodySmall
                        ?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
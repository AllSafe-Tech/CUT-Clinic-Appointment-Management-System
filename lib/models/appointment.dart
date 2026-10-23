import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum AppointmentStatus { pending, approved, rejected, cancelled, completed, unknown }

AppointmentStatus parseStatus(String? s) {
  switch (s) {
    case 'pending':
      return AppointmentStatus.pending;
    case 'approved':
      return AppointmentStatus.approved;
    case 'rejected':
      return AppointmentStatus.rejected;
    case 'cancelled':
      return AppointmentStatus.cancelled;
    case 'completed':
      return AppointmentStatus.completed;
    default:
      return AppointmentStatus.unknown;
  }
}

extension AppointmentStatusX on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending review';
      case AppointmentStatus.approved:
        return 'Approved';
      case AppointmentStatus.rejected:
        return 'Not approved';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.unknown:
        return 'Unknown';
    }
  }

  String get description {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Waiting for clinic staff to review your request. '
            'They will assign a date and time.';
      case AppointmentStatus.approved:
        return 'Your appointment is confirmed. Please arrive on time.';
      case AppointmentStatus.rejected:
        return 'Your request was not approved. Contact the clinic if you need help.';
      case AppointmentStatus.cancelled:
        return 'This appointment was cancelled.';
      case AppointmentStatus.completed:
        return 'This appointment has been completed.';
      case AppointmentStatus.unknown:
        return '';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return const Color(0xFFB26A00);
      case AppointmentStatus.approved:
        return const Color(0xFF1B7F3B);
      case AppointmentStatus.rejected:
        return const Color(0xFFA12830);
      case AppointmentStatus.cancelled:
        return const Color(0xFF616161);
      case AppointmentStatus.completed:
        return const Color(0xFF003261);
      case AppointmentStatus.unknown:
        return const Color(0xFF616161);
    }
  }

  IconData get icon {
    switch (this) {
      case AppointmentStatus.pending:
        return Icons.hourglass_top_rounded;
      case AppointmentStatus.approved:
        return Icons.check_circle_rounded;
      case AppointmentStatus.rejected:
        return Icons.cancel_rounded;
      case AppointmentStatus.cancelled:
        return Icons.event_busy_rounded;
      case AppointmentStatus.completed:
        return Icons.task_alt_rounded;
      case AppointmentStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.studentId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledAt,
    this.notes,
    this.serviceName,
    this.details,
  });

  final String id;
  final String studentId;
  final AppointmentStatus status;

  /// Assigned by clinic staff. Null until staff assign a slot (FR12).
  final DateTime? scheduledAt;

  /// Text shown in the app: "<type of service>: <details>".
  final String? notes;

  /// Type of service chosen by the student (null for older appointments).
  final String? serviceName;

  /// What the student typed (details + preference), without the service name.
  final String? details;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive =>
      status == AppointmentStatus.pending || status == AppointmentStatus.approved;
  bool get canCancel => isActive;

  String get dateText => scheduledAt == null
      ? 'To be assigned by clinic staff'
      : DateFormat('EEEE, d MMMM yyyy').format(scheduledAt!);
  String get timeText =>
      scheduledAt == null ? '-' : DateFormat('HH:mm').format(scheduledAt!);

  factory Appointment.fromMap(Map<String, dynamic> m) {
    final d = m['appointment_date'] as String?;
    final t = m['appointment_time'] as String?;
    DateTime? when;
    if (d != null && t != null) when = DateTime.tryParse('${d}T$t');

    final service = m['service_name'] as String?;
    final raw = m['notes'] as String?;
    final shown = (service == null || service.isEmpty)
        ? raw
        : ((raw == null || raw.isEmpty) ? service : '$service: $raw');

    return Appointment(
      id: m['appointment_id'] as String,
      studentId: m['student_id'] as String,
      status: parseStatus(m['status'] as String?),
      scheduledAt: when,
      notes: shown,
      serviceName: service,
      details: raw,
      createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
    );
  }
}
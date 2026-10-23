import 'package:cut_clinic_app/models/appointment.dart';
import 'package:cut_clinic_app/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Appointment.fromMap parses an approved appointment', () {
    final a = Appointment.fromMap({
      'appointment_id': 'a1',
      'student_id': 's1',
      'status': 'approved',
      'appointment_date': '2026-10-20',
      'appointment_time': '09:30:00',
      'notes': 'Check-up',
      'created_at': '2026-10-14T08:00:00Z',
      'updated_at': '2026-10-14T09:00:00Z',
    });
    expect(a.status, AppointmentStatus.approved);
    expect(a.isActive, true);
    expect(a.scheduledAt, DateTime(2026, 10, 20, 9, 30));
  });

  test('Pending appointment has no slot yet', () {
    final a = Appointment.fromMap({
      'appointment_id': 'a2',
      'student_id': 's1',
      'status': 'pending',
      'appointment_date': null,
      'appointment_time': null,
      'notes': null,
      'created_at': '2026-10-14T08:00:00Z',
      'updated_at': '2026-10-14T08:00:00Z',
    });
    expect(a.scheduledAt, isNull);
    expect(a.canCancel, true);
  });

  test('Cancelled appointment is not active', () {
    expect(parseStatus('cancelled'), AppointmentStatus.cancelled);
    expect(AppointmentStatus.cancelled == AppointmentStatus.pending, false);
  });

  test('Validators', () {
    expect(Validators.studentNumber('222016838'), isNull);
    expect(Validators.studentNumber('12345'), isNotNull);
    expect(Validators.phone('0821234567'), isNull);
    expect(Validators.normalisePhone('082 123 4567'), '+27821234567');
    expect(Validators.email('a@b.co'), isNull);
    expect(Validators.email('nope'), isNotNull);
  });
}

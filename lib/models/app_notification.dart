class AppNotification {
  const AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
    this.appointmentId,
  });

  final String id;
  final String? appointmentId;
  final String message;
  final String type; // SMS / Email
  final String status; // queued / sent / failed
  final DateTime createdAt;

  bool get isReminder => message.startsWith('Reminder:');

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['notification_id'] as String,
        appointmentId: m['appointment_id'] as String?,
        message: m['message'] as String,
        type: m['type'] as String,
        status: m['status'] as String,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}

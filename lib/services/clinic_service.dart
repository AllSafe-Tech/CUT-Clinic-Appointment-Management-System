import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/validators.dart';
import '../models/app_notification.dart';
import '../models/appointment.dart';
import '../models/service_type.dart';
import '../models/student_document.dart';
import '../models/student_profile.dart';

class ClinicService {
  static SupabaseClient get _c => Supabase.instance.client;
  static String? get userId => _c.auth.currentUser?.id;
  static String? get userEmail => _c.auth.currentUser?.email;

  static const String documentsBucket = 'student-documents';
  static const String photosBucket = 'profile-photos';

  /// Signed links are cached for the session so avatars do not flicker.
  static final Map<String, MapEntry<String, DateTime>> _urlCache = {};

  // ---------- Auth ----------

  static Future<void> signIn(String email, String password) async {
    await _c.auth.signInWithPassword(email: email, password: password);
  }

  static Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String studentNumber,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await _c.auth.signUp(
      email: email,
      password: password,
      data: {
        'account_type': 'student',
        'first_name': firstName,
        'last_name': lastName,
        'student_number': studentNumber,
        'phone': Validators.normalisePhone(phone),
      },
    );
    return res.session != null;
  }

  static Future<void> signOut() async {
    _urlCache.clear();
    await _c.auth.signOut();
  }

  static Future<void> sendPasswordResetCode(String email) async {
    await _c.auth.resetPasswordForEmail(email.trim());
  }

  static Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _c.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.recovery,
    );
    try {
      await _c.auth.updateUser(UserAttributes(password: newPassword));
    } finally {
      await _c.auth.signOut();
    }
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = userEmail;
    if (email == null) throw AuthException('Please log in again.');
    try {
      await _c.auth.signInWithPassword(email: email, password: currentPassword);
    } on AuthException {
      throw AuthException('Your current password is incorrect.');
    }
    await _c.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ---------- Profile ----------

  static Future<StudentProfile?> fetchProfile() async {
    final id = userId;
    if (id == null) return null;
    final row =
        await _c.from('students').select().eq('student_id', id).maybeSingle();
    return row == null ? null : StudentProfile.fromMap(row);
  }

  static Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    await _c.rpc('update_my_profile', params: {
      'p_first_name': firstName.trim(),
      'p_last_name': lastName.trim(),
      'p_phone': Validators.normalisePhone(phone),
    });
  }

  // ---------- Files (profile photo + documents) ----------

  static String _mimeFor(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return 'application/pdf';
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Temporary link (1 hour) to a private file. Returns null on failure.
  static Future<String?> signedUrl(String bucket, String path) async {
    final key = '$bucket/$path';
    final hit = _urlCache[key];
    if (hit != null && hit.value.isAfter(DateTime.now())) return hit.key;
    try {
      final url = await _c.storage.from(bucket).createSignedUrl(path, 3600);
      _urlCache[key] =
          MapEntry(url, DateTime.now().add(const Duration(minutes: 50)));
      return url;
    } catch (_) {
      return null;
    }
  }

  static Future<void> uploadAvatar({
    required Uint8List bytes,
    required String ext,
  }) async {
    final uid = userId;
    if (uid == null) throw AuthException('Please log in again.');
    final e = const ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
    final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$e';
    final storage = _c.storage.from(photosBucket);
    final old = (await fetchProfile())?.avatarPath;

    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: _mimeFor(path)),
    );
    try {
      await _c.rpc('set_my_avatar', params: {'p_path': path});
    } catch (err) {
      try {
        await storage.remove([path]);
      } catch (_) {}
      rethrow;
    }
    if (old != null) {
      try {
        await storage.remove([old]);
      } catch (_) {}
    }
  }

  static Future<void> removeAvatar() async {
    final old = (await fetchProfile())?.avatarPath;
    await _c.rpc('set_my_avatar', params: {'p_path': null});
    if (old != null) {
      try {
        await _c.storage.from(photosBucket).remove([old]);
      } catch (_) {}
    }
  }

  static Future<List<StudentDocument>> fetchDocuments() async {
    final id = userId;
    if (id == null) return [];
    final rows = await _c
        .from('documents')
        .select()
        .eq('student_id', id)
        .order('uploaded_at', ascending: false);
    return (rows as List)
        .map((r) => StudentDocument.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<void> uploadDocument({
    required DocType type,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final uid = userId;
    if (uid == null) throw AuthException('Please log in again.');
    final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$safe';
    final storage = _c.storage.from(documentsBucket);

    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: _mimeFor(safe)),
    );
    try {
      await _c.rpc('add_my_document', params: {
        'p_doc_type': type.dbValue,
        'p_file_name': fileName,
        'p_file_path': path,
      });
    } catch (err) {
      try {
        await storage.remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  static Future<void> deleteDocument(StudentDocument d) async {
    await _c.rpc('delete_my_document', params: {'p_document_id': d.id});
    try {
      await _c.storage.from(documentsBucket).remove([d.filePath]);
    } catch (_) {}
  }

  // ---------- Appointments ----------

  static Stream<List<Appointment>> watchAppointments() {
    return _c
        .from('appointments')
        .stream(primaryKey: ['appointment_id'])
        .eq('student_id', userId!)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Appointment.fromMap).toList());
  }

  /// The clinic's types of service (managed in the "services" table).
  static Future<List<ServiceType>> fetchServices() async {
    final rows = await _c
        .from('services')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((r) => ServiceType.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<void> requestAppointment({
    required String serviceId,
    String? notes,
  }) async {
    await _c.rpc('request_appointment', params: {
      'p_service_id': serviceId,
      'p_notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
    });
  }

  static Future<void> cancelAppointment(String appointmentId) async {
    await _c.rpc('cancel_appointment',
        params: {'p_appointment_id': appointmentId});
  }

  // ---------- Notifications ----------

  static Stream<List<AppNotification>> watchNotifications() {
    return _c
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('student_id', userId!)
        .order('created_at', ascending: false)
        .map((rows) {
      final seen = <String>{};
      final out = <AppNotification>[];
      for (final r in rows) {
        final n = AppNotification.fromMap(r);
        if (seen.add('${n.appointmentId}|${n.message}')) out.add(n);
      }
      return out;
    });
  }
}
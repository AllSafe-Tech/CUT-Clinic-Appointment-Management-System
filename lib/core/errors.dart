import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyError(Object e) {
  final raw = e.toString();

  if (raw.contains('SocketException') ||
      raw.contains('ClientException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('TimeoutException')) {
    return 'No connection to the server. Check your internet and try again.';
  }

  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (m.contains('email not confirmed')) {
      return 'Please confirm your email address first, then log in.';
    }
    if (m.contains('already registered') || m.contains('already been')) {
      return 'An account with this email already exists.';
    }
    if (m.contains('database error saving new user')) {
      return 'That student number or email is already registered.';
    }
    if (m.contains('rate limit') || m.contains('too many') || m.contains('security purposes')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if ((m.contains('token') || m.contains('otp') || m.contains('code')) &&
        (m.contains('expired') || m.contains('invalid'))) {
      return 'That code is incorrect or has expired. Request a new one.';
    }
    return e.message;
  }

  if (e is PostgrestException) {
    if (e.code == '23505') {
      return 'You already have an active appointment.';
    }
    return e.message;
  }

  if (e is StorageException) {
    final m = e.message.toLowerCase();
    if (m.contains('mime') || m.contains('not supported')) {
      return 'That file type is not allowed. Use PDF, JPG or PNG.';
    }
    if (m.contains('size') || m.contains('too large') || m.contains('payload')) {
      return 'That file is too large.';
    }
    if (m.contains('row-level security') || m.contains('unauthorized')) {
      return 'You do not have permission to upload this file.';
    }
    return 'Upload failed. Please try again.';
  }

  return 'Something went wrong. Please try again.';
}
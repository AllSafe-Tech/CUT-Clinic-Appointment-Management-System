class Validators {
  static String? required(String? v, [String label = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// CUT student numbers are 9 digits (FR2). Real verification against CUT
  /// systems is out of scope for the prototype (SRS 6.4).
  static String? studentNumber(String? v) {
    final s = v?.trim() ?? '';
    if (!RegExp(r'^\d{9}$').hasMatch(s)) {
      return 'Enter your 9-digit CUT student number';
    }
    return null;
  }

  static String? phone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^(\+27|0)\d{9}$').hasMatch(s)) {
      return 'Enter a valid SA number, e.g. 0821234567';
    }
    return null;
  }

  static String? password(String? v) {
    if ((v ?? '').length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? reason(String? v) {
    final s = v?.trim() ?? '';
    if (s.length < 5) return 'Please give a short reason (at least 5 characters)';
    if (s.length > 300) return 'Please keep this under 300 characters';
    return null;
  }

  /// 0821234567 -> +27821234567 (so SMS services accept it).
  static String normalisePhone(String v) {
    final s = v.replaceAll(RegExp(r'[\s-]'), '');
    return s.startsWith('0') ? '+27${s.substring(1)}' : s;
  }
}

class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.studentNumber,
    this.avatarPath,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String studentNumber;

  /// Path of the profile photo in the private "profile-photos" bucket.
  final String? avatarPath;

  String get fullName => '$firstName $lastName';

  factory StudentProfile.fromMap(Map<String, dynamic> m) => StudentProfile(
        id: m['student_id'] as String,
        firstName: m['first_name'] as String,
        lastName: m['last_name'] as String,
        email: m['email'] as String,
        phone: m['phone'] as String,
        studentNumber: m['student_number'] as String,
        avatarPath: m['avatar_path'] as String?,
      );
}
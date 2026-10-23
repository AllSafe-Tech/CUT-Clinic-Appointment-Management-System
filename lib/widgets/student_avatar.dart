import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../services/clinic_service.dart';

/// Round profile photo (from private storage) with an initials fallback.
class StudentAvatar extends StatefulWidget {
  const StudentAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    this.avatarPath,
    this.radius = 30,
  });

  final String firstName;
  final String lastName;
  final String? avatarPath;
  final double radius;

  @override
  State<StudentAvatar> createState() => _StudentAvatarState();
}

class _StudentAvatarState extends State<StudentAvatar> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StudentAvatar old) {
    super.didUpdateWidget(old);
    if (old.avatarPath != widget.avatarPath) {
      _url = null;
      _load();
    }
  }

  Future<void> _load() async {
    final p = widget.avatarPath;
    if (p == null) return;
    final url = await ClinicService.signedUrl(ClinicService.photosBucket, p);
    if (mounted && p == widget.avatarPath) setState(() => _url = url);
  }

  String get _initials {
    final f = widget.firstName.isNotEmpty ? widget.firstName[0] : '';
    final l = widget.lastName.isNotEmpty ? widget.lastName[0] : '';
    return (f + l).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.radius * 2;
    final initials = Container(
      color: CutColors.gold,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: CutColors.blue,
          fontWeight: FontWeight.w800,
          fontSize: widget.radius * 0.7,
        ),
      ),
    );
    return SizedBox(
      width: d,
      height: d,
      child: ClipOval(
        child: _url == null
            ? initials
            : Image.network(
                _url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => initials,
              ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../models/student_profile.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_logo.dart';
import '../../widgets/student_avatar.dart';
import 'avatar_actions.dart';

/// Edit name, cell number and profile photo. Student number and email are
/// identity fields and stay locked.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final StudentProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.profile.firstName);
  late final _last = TextEditingController(text: widget.profile.lastName);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late String? _avatarPath = widget.profile.avatarPath;
  bool _busy = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final changed = await changeProfilePhoto(context, hasPhoto: _avatarPath != null);
    if (!changed) return;
    final p = await ClinicService.fetchProfile();
    if (mounted) setState(() => _avatarPath = p?.avatarPath);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    try {
      await ClinicService.updateProfile(
        firstName: _first.text,
        lastName: _last.text,
        phone: _phone.text,
      );
      navigator.pop(true);
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Scaffold(
      appBar: cutAppBar('Edit profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _busy ? null : _changePhoto,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            StudentAvatar(
                              firstName: p.firstName,
                              lastName: p.lastName,
                              avatarPath: _avatarPath,
                              radius: 48,
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: CutColors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.photo_camera_rounded,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : _changePhoto,
                        child: const Text('Change photo'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _first,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'First name'),
                      validator: (v) => Validators.required(v, 'First name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _last,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Last name'),
                      validator: (v) => Validators.required(v, 'Last name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Cell number (for SMS)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: p.studentNumber,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Student number (cannot be changed)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: p.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email (cannot be changed)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LoadingButton(label: 'Save changes', busy: _busy, onPressed: _save),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
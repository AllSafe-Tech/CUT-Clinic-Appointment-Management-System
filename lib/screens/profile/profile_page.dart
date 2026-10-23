import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/privacy.dart';
import '../../models/student_profile.dart';
import '../../widgets/common.dart';
import '../../widgets/cut_header.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/student_avatar.dart';
import '../appointment/history_screen.dart';
import 'avatar_actions.dart';
import 'change_password_screen.dart';
import 'documents_screen.dart';
import 'edit_profile_screen.dart';
import 'logout_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.profile, required this.onProfileChanged});

  final StudentProfile profile;
  final Future<void> Function() onProfileChanged;

  Future<void> _changePhoto(BuildContext context) async {
    final changed =
        await changeProfilePhoto(context, hasPhoto: profile.avatarPath != null);
    if (changed) {
      await onProfileChanged();
      if (context.mounted) showInfo(context, 'Profile photo updated.');
    }
  }

  Future<void> _edit(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
    );
    await onProfileChanged(); // also picks up a photo changed inside Edit profile
    if (updated == true && context.mounted) showInfo(context, 'Profile updated.');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        CutHeader(
          title: profile.fullName,
          subtitle: 'Student no. ${profile.studentNumber}',
          leading: GestureDetector(
            onTap: () => _changePhoto(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                StudentAvatar(
                  firstName: profile.firstName,
                  lastName: profile.lastName,
                  avatarPath: profile.avatarPath,
                  radius: 34,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_camera_rounded,
                        size: 16, color: CutColors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Your details'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Student number',
                          value: profile.studentNumber),
                      InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: profile.email),
                      InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Cell number',
                          value: profile.phone),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle('Account'),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.edit_outlined,
                      label: 'Edit profile',
                      onTap: () => _edit(context),
                    ),
                    const Divider(),
                    _MenuTile(
                      icon: Icons.photo_camera_outlined,
                      label: 'Change profile photo',
                      onTap: () => _changePhoto(context),
                    ),
                    const Divider(),
                    _MenuTile(
                      icon: Icons.folder_open_rounded,
                      label: 'My documents',
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DocumentsScreen())),
                    ),
                    const Divider(),
                    _MenuTile(
                      icon: Icons.lock_reset_rounded,
                      label: 'Change password',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen())),
                    ),
                    const Divider(),
                    _MenuTile(
                      icon: Icons.history_rounded,
                      label: 'Past appointments',
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HistoryScreen())),
                    ),
                    const Divider(),
                    _MenuTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy notice',
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Privacy notice'),
                          content: const SingleChildScrollView(child: Text(privacyNotice)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: PillButton(
                  label: 'Log out',
                  icon: Icons.logout_rounded,
                  color: CutColors.red,
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const LogoutScreen())),
                ),
              ),
              const SizedBox(height: 20),
              Text('CUT Clinic  |  Version 1.0.0',
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: CutColors.blue),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
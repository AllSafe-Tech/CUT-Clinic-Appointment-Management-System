import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/brand.dart';
import '../../core/errors.dart';
import '../../services/clinic_service.dart';
import '../../widgets/common.dart';

const int _maxPhotoBytes = 2 * 1024 * 1024;

/// Lets the student pick, take or remove their profile photo.
/// Returns true when the photo was changed or removed.
Future<bool> changeProfilePhoto(
  BuildContext context, {
  required bool hasPhoto,
}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: CutColors.blue),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: CutColors.blue),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: CutColors.red),
              title: const Text('Remove photo'),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return false;

  final navigator = Navigator.of(context, rootNavigator: true);
  var busyShown = false;
  void openBusy() {
    busyShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  try {
    if (choice == 'remove') {
      openBusy();
      await ClinicService.removeAvatar();
      return true;
    }

    final picked = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 85,
    );
    if (picked == null) return false;

    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxPhotoBytes) {
      if (context.mounted) {
        showError(context, 'That photo is too large. Choose one under 2 MB.');
      }
      return false;
    }
    if (!context.mounted) return false;

    openBusy();
    final ext = picked.name.contains('.')
        ? picked.name.split('.').last.toLowerCase()
        : 'jpg';
    await ClinicService.uploadAvatar(bytes: bytes, ext: ext);
    return true;
  } catch (e) {
    if (context.mounted) showError(context, friendlyError(e));
    return false;
  } finally {
    if (busyShown) navigator.pop();
  }
}
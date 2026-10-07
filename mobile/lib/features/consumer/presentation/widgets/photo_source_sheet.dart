import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../vendor/onboarding/data/photo_picker_service.dart';

/// The Camera / Gallery choice, as a bottom sheet. Returns null if dismissed.
Future<PhotoSource?> showPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<PhotoSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(context.l10n.commonCamera, style: AppTextStyles.bodyStrong),
            onTap: () => Navigator.of(context).pop(PhotoSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(context.l10n.commonGallery, style: AppTextStyles.bodyStrong),
            onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
          ),
        ],
      ),
    ),
  );
}

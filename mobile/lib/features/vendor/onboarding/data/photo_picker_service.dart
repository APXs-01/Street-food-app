import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/brand.dart';
import '../../../../core/localization/l10n.dart';

enum PhotoSource { camera, gallery }

class PhotoPickException implements Exception {
  const PhotoPickException(this.message);

  /// Safe to show as it is.
  final String message;

  @override
  String toString() => 'PhotoPickException($message)';
}

/// Takes or chooses a photo. An interface so a test can stand in for the camera.
abstract interface class PhotoPickerService {
  /// The picked image's file path, or null if the person backed out.
  Future<String?> pick(PhotoSource source);
}

class ImagePickerService implements PhotoPickerService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pick(PhotoSource source) async {
    try {
      // Scaled down and recompressed on the device: a phone photo is several
      // megabytes and the API refuses anything over 5 MB.
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      return file?.path;
    } on PlatformException catch (error) {
      final denied = error.code.contains('access_denied');

      throw PhotoPickException(
        source == PhotoSource.camera
            ? (denied ? l10n.photoCameraBlocked(kBrandName) : l10n.photoCameraFailed)
            : (denied ? l10n.photoGalleryBlocked(kBrandName) : l10n.photoGalleryFailed),
      );
    }
  }
}

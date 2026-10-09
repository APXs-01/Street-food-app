import 'package:dio/dio.dart';

import '../../../core/api/json.dart';
import '../../vendor/onboarding/data/onboarding_repository.dart' show imageMimeTypeFor;
import 'inspection_scoring.dart';

/// `POST /api/inspections`: an inspector's submission for one stall (multipart:
/// `vendor_id`, the five criteria as `pass` / `partial` / `fail`, an
/// `evidence_photo`, optional `notes`). Only an inspector account may call it;
/// anyone else gets the server's 403, and `inspector.checklist` is a kill-switch.
/// The score and grade are worked out on the server, never sent.
class InspectionRepository {
  InspectionRepository(this._dio);

  final Dio _dio;

  Future<void> submit({
    required int vendorId,
    required Map<InspectionCriterion, CheckResult> results,
    required String photoPath,
    String? notes,
  }) {
    return guardApi(() async {
      final form = FormData()..fields.add(MapEntry('vendor_id', '$vendorId'));

      for (final entry in results.entries) {
        form.fields.add(MapEntry(entry.key.apiField, entry.value.apiValue));
      }

      if (notes != null && notes.trim().isNotEmpty) form.fields.add(MapEntry('notes', notes.trim()));

      form.files.add(
        MapEntry(
          'evidence_photo',
          await MultipartFile.fromFile(
            photoPath,
            filename: photoPath.split(RegExp(r'[\\/]')).last,
            contentType: DioMediaType.parse(imageMimeTypeFor(photoPath)),
          ),
        ),
      );

      await _dio.post<void>(
        '/inspections',
        data: form,
        options: Options(sendTimeout: const Duration(seconds: 90), receiveTimeout: const Duration(seconds: 60)),
      );
    });
  }
}

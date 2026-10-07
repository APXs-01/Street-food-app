import 'package:dio/dio.dart';

import '../../../core/api/json.dart';
import '../../vendor/onboarding/data/onboarding_repository.dart' show imageMimeTypeFor;
import 'status_models.dart';

/// The status endpoints (docs/API.md "Daily statuses"):
///
///   GET    /statuses              the feed (`mine=1` for your own, expired ones too)
///   POST   /statuses              multipart: caption and/or media, audience, location_label, vendor_id
///   GET    /statuses/{id}         the status plus its first page of comments
///   DELETE /statuses/{id}
///   POST   /statuses/{id}/like    toggles
///   POST   /statuses/{id}/comments
class StatusRepository {
  StatusRepository(this._dio);

  final Dio _dio;

  Future<List<StatusPost>> feed({bool mine = false}) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/statuses',
        queryParameters: {'per_page': 50, if (mine) 'mine': 1},
      );

      return [for (final json in asJsonList(response.data!['data'])) StatusPost.fromJson(json)];
    });
  }

  /// One status with its comments, oldest first.
  Future<StatusPost> show(int id) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/statuses/$id');
      final data = response.data!;
      final comments = data['comments'] is Map ? asJsonList(asJsonMap(data['comments'])['data']) : const <Map<String, dynamic>>[];

      return StatusPost.fromJson(asJsonMap(data['data'])).copyWith(
        comments: [for (final json in comments) StatusComment.fromJson(json)],
      );
    });
  }

  /// Posts a status. A vendor's is always public and for their own stall; a
  /// customer may choose `friends` and tag a stall with [vendorId].
  Future<StatusPost> create({
    String? caption,
    String? photoPath,
    String audience = 'public',
    String? locationLabel,
    int? vendorId,
  }) {
    return guardApi(() async {
      final form = FormData()..fields.add(MapEntry('audience', audience));

      if (caption != null && caption.trim().isNotEmpty) form.fields.add(MapEntry('caption', caption.trim()));
      if (locationLabel != null && locationLabel.isNotEmpty) form.fields.add(MapEntry('location_label', locationLabel));
      if (vendorId != null) form.fields.add(MapEntry('vendor_id', '$vendorId'));

      if (photoPath != null) {
        form.files.add(
          MapEntry(
            'media',
            await MultipartFile.fromFile(
              photoPath,
              filename: photoPath.split(RegExp(r'[\\/]')).last,
              contentType: DioMediaType.parse(imageMimeTypeFor(photoPath)),
            ),
          ),
        );
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/statuses',
        data: form,
        options: Options(sendTimeout: const Duration(seconds: 90), receiveTimeout: const Duration(seconds: 60)),
      );

      return StatusPost.fromJson(asJsonMap(response.data!['data']));
    });
  }

  Future<void> delete(int id) => guardApi(() async {
        await _dio.delete<void>('/statuses/$id');
      });

  /// Likes the status, or takes the like back. Returns the new state.
  Future<({bool liked, int likes})> toggleLike(int id) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>('/statuses/$id/like');
      final data = response.data!;

      return (liked: data['liked'] as bool, likes: toInt(data['likes_count']) ?? 0);
    });
  }

  Future<StatusComment> comment(int id, String body) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>('/statuses/$id/comments', data: {'body': body.trim()});

      return StatusComment.fromJson(asJsonMap(response.data!['data']));
    });
  }
}

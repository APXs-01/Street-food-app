import 'package:dio/dio.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/json.dart';
import '../../vendor/onboarding/data/onboarding_repository.dart' show imageMimeTypeFor;
import 'discovery_stall.dart';
import 'stall_detail_models.dart';

/// Everything a customer reads about stalls (docs/API.md):
///
///   GET  /map/nearby        pins around a point, nearest first
///   GET  /vendors           stalls with details; `q` searches name, description, menu
///   GET  /vendors/{id}      one stall with its menu
///   GET  /vendors/{id}/hygiene, /vendors/{id}/reviews
///   POST /vendors/{id}/follow, DELETE /vendors/{id}/follow
///   POST /vendors/{id}/reviews
class StallRepository {
  StallRepository(this._dio);

  final Dio _dio;

  /// The stalls around a point, nearest first, each filled in with its details.
  ///
  /// The map endpoint gives position, distance and live status but not photo,
  /// description or hours, so `GET /vendors` (up to 50 stalls) is read as well and
  /// merged by id. A stall that is not in that first 50 keeps just its map data.
  Future<List<DiscoveryStall>> nearby({required double lat, required double lng, double radiusKm = 25}) {
    return guardApi(() async {
      final pins = await _dio.get<Map<String, dynamic>>(
        '/map/nearby',
        queryParameters: {'lat': lat, 'lng': lng, 'radius_km': radiusKm, 'per_page': 50},
      );

      final details = <int, DiscoveryStall>{};

      try {
        final vendors = await _dio.get<Map<String, dynamic>>('/vendors', queryParameters: {'per_page': 50});

        for (final json in asJsonList(vendors.data!['data'])) {
          final stall = DiscoveryStall.fromVendorJson(json);
          details[stall.id] = stall;
        }
      } on DioException {
        // The pins are still useful without the extra detail.
      }

      return [
        for (final json in asJsonList(pins.data!['data']))
          () {
            final pin = DiscoveryStall.fromMapPin(json);
            final detail = details[pin.id];

            return detail == null ? pin : pin.withDetail(detail);
          }(),
      ];
    });
  }

  /// Stalls whose name, description or menu match [query].
  Future<List<DiscoveryStall>> search(String query) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/vendors', queryParameters: {'q': query, 'per_page': 20});

      return [for (final json in asJsonList(response.data!['data'])) DiscoveryStall.fromVendorJson(json)];
    });
  }

  Future<DiscoveryStall> vendor(int id) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/vendors/$id');

      return DiscoveryStall.fromVendorJson(asJsonMap(response.data!['data']));
    });
  }

  Future<HygieneBreakdown> hygiene(int id) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/vendors/$id/hygiene');

      return HygieneBreakdown.fromJson(asJsonMap(response.data!['data']));
    });
  }

  Future<ReviewsPage> reviews(int id, {bool withPhotos = false, int page = 1}) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vendors/$id/reviews',
        queryParameters: {'page': page, 'per_page': 10, if (withPhotos) 'with_photos': 1},
      );

      return ReviewsPage.fromJson(response.data!);
    });
  }

  Future<void> setFollowing(int id, {required bool follow}) {
    return guardApi(() async {
      if (follow) {
        await _dio.post<void>('/vendors/$id/follow');
      } else {
        await _dio.delete<void>('/vendors/$id/follow');
      }
    });
  }

  /// Creates the customer's review of a stall, or updates the one they already have.
  ///
  /// Multipart: `rating`, optional `comment`, `observations[]` keys, `is_anonymous`
  /// as 1 or 0, and `photos[i][file]` (up to 3). No `capture_time` is sent: the
  /// server then uses its own upload time, which can never fail the 10-minute
  /// freshness check for a photo picked from the gallery.
  Future<void> submitReview({
    required int vendorId,
    required int rating,
    String? comment,
    List<String> observations = const [],
    List<String> photoPaths = const [],
    bool anonymous = false,
  }) {
    return guardApi(() async {
      final form = FormData()
        ..fields.add(MapEntry('rating', '$rating'))
        ..fields.add(MapEntry('is_anonymous', anonymous ? '1' : '0'));

      if (comment != null && comment.trim().isNotEmpty) form.fields.add(MapEntry('comment', comment.trim()));

      for (final key in observations) {
        form.fields.add(MapEntry('observations[]', key));
      }

      for (var i = 0; i < photoPaths.length; i++) {
        final path = photoPaths[i];

        form.files.add(
          MapEntry(
            'photos[$i][file]',
            await MultipartFile.fromFile(
              path,
              filename: path.split(RegExp(r'[\\/]')).last,
              contentType: DioMediaType.parse(imageMimeTypeFor(path)),
            ),
          ),
        );
      }

      await _dio.post<void>(
        '/vendors/$vendorId/reviews',
        data: form,
        options: Options(sendTimeout: const Duration(seconds: 90), receiveTimeout: const Duration(seconds: 60)),
      );
    });
  }
}

/// A 403 on stall detail is the server saying "not yours"; screens that expect
/// that can recognise it.
extension ApiFailureKind on ApiFailure {
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
}

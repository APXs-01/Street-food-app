import 'package:dio/dio.dart';

import '../../../../core/api/api_failure.dart';
import 'onboarding_draft.dart';
import 'stall_category.dart';

/// The two calls stall onboarding makes (docs/API.md):
///
///   GET  /categories  -> { data: [{ slug, name }] }
///   POST /vendors     multipart -> 201 { data: stall }, the new id is data.id
///                              -> 409 { message, vendor_id } if one already exists
class OnboardingRepository {
  OnboardingRepository(this._dio);

  final Dio _dio;

  Future<List<StallCategory>> fetchCategories() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/categories');
      final items = response.data!['data'] as List<dynamic>;

      return [for (final item in items) StallCategory.fromJson(item as Map<String, dynamic>)];
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } catch (error) {
      if (error is TypeError || error is FormatException) throw _unexpected;
      rethrow;
    }
  }

  /// Creates the stall and returns its id. The draft must have passed validate().
  Future<int> createStall(OnboardingDraft draft) async {
    final path = draft.photoPath;
    if (path == null) throw StateError('The draft has no photo; validate() it first.');

    try {
      final photo = await MultipartFile.fromFile(
        path,
        filename: _fileName(path),
        contentType: DioMediaType.parse(imageMimeTypeFor(path)),
      );

      final response = await _dio.post<Map<String, dynamic>>(
        '/vendors',
        data: draft.toFormData(photo),
        // A photo on a mobile connection takes longer than the default 20 seconds.
        options: Options(sendTimeout: const Duration(seconds: 90), receiveTimeout: const Duration(seconds: 60)),
      );

      return (response.data!['data'] as Map<String, dynamic>)['id'] as int;
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } catch (error) {
      if (error is TypeError || error is FormatException) throw _unexpected;
      rethrow;
    }
  }

  static ApiFailure get _unexpected => ApiFailure.unexpectedResponse();

  static String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;
}

/// The API accepts jpg, jpeg, png and webp. The camera and gallery give jpeg
/// (png and webp from some galleries); anything unknown is sent as jpeg.
String imageMimeTypeFor(String path) {
  final lower = path.toLowerCase();

  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';

  return 'image/jpeg';
}

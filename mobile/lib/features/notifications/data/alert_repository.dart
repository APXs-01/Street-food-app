import 'package:dio/dio.dart';

import '../../../core/api/json.dart';
import 'alert_models.dart';

/// The notifications endpoints. The server creates them; the app only reads and
/// marks them read. There is no delete, so "Clear All" means "mark all read".
///
///   GET   /notifications              newest first, with `unread_count`
///   PATCH /notifications/{id}/read
///   PATCH /notifications/read-all
class AlertRepository {
  AlertRepository(this._dio);

  final Dio _dio;

  Future<({List<AppAlert> items, int unread})> list() {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/notifications', queryParameters: {'per_page': 50});
      final data = response.data!;

      return (
        items: [for (final json in asJsonList(data['data'])) AppAlert.fromJson(json)],
        unread: toInt(data['unread_count']) ?? 0,
      );
    });
  }

  Future<void> markRead(String id) => guardApi(() async {
        await _dio.patch<void>('/notifications/$id/read');
      });

  Future<void> markAllRead() => guardApi(() async {
        await _dio.patch<void>('/notifications/read-all');
      });
}

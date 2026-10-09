import 'package:dio/dio.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/api/json.dart';
import 'social_models.dart';

/// The friends endpoints (docs/API.md "Friends"). Customers only.
///
///   GET    /friends                accepted friends
///   GET    /friends/requests       requests waiting for you to answer
///   GET    /users/lookup?username  one customer by exact username
///   POST   /friends                send a request (`username`)
///   PATCH  /friends/{id}           `status` = accepted | declined
///   DELETE /friends/{id}           unfriend, or withdraw a request
///
/// The API has no suggestions, no search by name and no list of requests you
/// have sent, so the app offers none of those.
class FriendRepository {
  FriendRepository(this._dio);

  final Dio _dio;

  Future<List<Friendship>> friends() => _list('/friends');

  Future<List<Friendship>> requests() => _list('/friends/requests');

  Future<List<Friendship>> _list(String path) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: {'per_page': 50});

      return [for (final json in asJsonList(response.data!['data'])) Friendship.fromJson(json)];
    });
  }

  /// The customer with this exact username, or null if there is none.
  Future<Foodie?> lookup(String username) async {
    try {
      return await guardApi(() async {
        final response = await _dio.get<Map<String, dynamic>>('/users/lookup', queryParameters: {'username': username.trim()});

        return Foodie.fromJson(asJsonMap(response.data!['data']));
      });
    } on ApiFailure catch (failure) {
      if (failure.statusCode == 404) return null;

      rethrow;
    }
  }

  /// Sends a request. Returns the friendship; the server answers 409 (as an
  /// [ApiFailure] with its message) if you are already friends or they already asked you.
  Future<Friendship> send(String username) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>('/friends', data: {'username': username.trim()});

      return Friendship.fromJson(asJsonMap(response.data!['data']));
    });
  }

  Future<void> respond(int friendshipId, {required bool accept}) {
    return guardApi(() async {
      await _dio.patch<void>('/friends/$friendshipId', data: {'status': accept ? 'accepted' : 'declined'});
    });
  }

  Future<void> remove(int friendshipId) => guardApi(() async {
        await _dio.delete<void>('/friends/$friendshipId');
      });
}

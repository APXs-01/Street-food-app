import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../core/api/json.dart';
import '../../consumer/data/discovery_stall.dart';
import '../../consumer/data/stall_repository.dart';
import '../onboarding/data/onboarding_draft.dart' show formatApiTime;
import 'vendor_models.dart';

/// What a vendor does to their own stall (docs/API.md):
///
///   GET   /vendors/{id}                 their stall
///   PATCH /vendors/{id}/status          `is_open`
///   PATCH /vendors/{id}/hours           `opens_at`, `closes_at`, `open_days`
///   GET   /vendors/{id}/analytics       rating, hygiene trend, engagement
///   GET/POST /menu-items, PATCH/DELETE /menu-items/{id}
class VendorRepository {
  VendorRepository(this._dio, this._stalls);

  final Dio _dio;
  final StallRepository _stalls;

  Future<DiscoveryStall> stall(int vendorId) => _stalls.vendor(vendorId);

  /// The live open/closed switch. Opening starts the server's auto-close clock.
  Future<DiscoveryStall> setOpen(int vendorId, {required bool open}) {
    return guardApi(() async {
      final response = await _dio.patch<Map<String, dynamic>>('/vendors/$vendorId/status', data: {'is_open': open});

      return DiscoveryStall.fromVendorJson(asJsonMap(response.data!['data']));
    });
  }

  /// The daily hours. [openDays] is left out to keep every day.
  Future<DiscoveryStall> setHours(int vendorId, {required TimeOfDay opens, required TimeOfDay closes, List<int>? openDays}) {
    return guardApi(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/vendors/$vendorId/hours',
        data: {
          'opens_at': formatApiTime(opens),
          'closes_at': formatApiTime(closes),
          'open_days': ?openDays,
        },
      );

      return DiscoveryStall.fromVendorJson(asJsonMap(response.data!['data']));
    });
  }

  Future<VendorAnalytics> analytics(int vendorId) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/vendors/$vendorId/analytics');

      return VendorAnalytics.fromJson(asJsonMap(response.data!['data']));
    });
  }

  // ---- menu ------------------------------------------------------------------

  Future<List<StallMenuItem>> menu() {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/menu-items');

      return [for (final json in asJsonList(response.data!['data'])) StallMenuItem.fromJson(json)];
    });
  }

  Future<StallMenuItem> addMenuItem({required String name, required double price, bool available = true}) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/menu-items',
        data: {'name': name, 'price': price.toStringAsFixed(2), 'is_available': available},
      );

      return StallMenuItem.fromJson(asJsonMap(response.data!['data']));
    });
  }

  /// Changes only the fields given. Used for edits, "sold out" (`isAvailable`)
  /// and "fresh today" (`freshToday`).
  Future<StallMenuItem> updateMenuItem(
    int id, {
    String? name,
    double? price,
    bool? isAvailable,
    bool? freshToday,
  }) {
    return guardApi(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/menu-items/$id',
        data: {
          'name': ?name,
          if (price != null) 'price': price.toStringAsFixed(2),
          'is_available': ?isAvailable,
          'fresh_today': ?freshToday,
        },
      );

      return StallMenuItem.fromJson(asJsonMap(response.data!['data']));
    });
  }

  Future<void> deleteMenuItem(int id) => guardApi(() async {
        await _dio.delete<void>('/menu-items/$id');
      });
}

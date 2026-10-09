import 'package:dio/dio.dart';

import '../localization/l10n.dart';
import 'api_failure.dart';

/// Reads the pieces of decoded API JSON. The API sends numbers as numbers, but a
/// decimal can arrive as a string, so these accept both.

Map<String, dynamic> asJsonMap(Object? value) => (value as Map).cast<String, dynamic>();

List<Map<String, dynamic>> asJsonList(Object? value) {
  if (value == null) return const [];

  return [for (final item in value as List) asJsonMap(item)];
}

double? toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  return double.tryParse(value.toString());
}

int? toInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}

DateTime? toDate(Object? value) {
  if (value is! String || value.isEmpty) return null;

  return DateTime.tryParse(value)?.toLocal();
}

/// `17:00:00` or `17:00` as `17:00`; null when absent.
String? toClock(Object? value) {
  if (value is! String || value.length < 5) return null;

  return value.substring(0, 5);
}

/// Runs an API call and turns every failure into an [ApiFailure], so screens
/// only ever see one kind of error.
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (error) {
    throw ApiFailure.fromDio(error);
  } on ApiFailure {
    rethrow;
  } catch (error) {
    if (error is TypeError || error is FormatException) {
      throw ApiFailure.unexpectedResponse();
    }

    rethrow;
  }
}

/// The message to show for any error a provider can hold.
String errorMessage(Object error) {
  if (error is ApiFailure) return error.message;

  return l10n.errorGeneric;
}

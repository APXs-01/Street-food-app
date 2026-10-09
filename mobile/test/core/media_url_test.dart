import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_client.dart';

void main() {
  const api = 'http://10.0.2.2:8000/api';

  group('resolveMedia', () {
    test('a localhost photo URL points at the API host, keeping the path', () {
      expect(
        ApiConfig.resolveMedia('http://localhost:8000/storage/vendors/covers/a.jpg', apiBaseUrl: api),
        'http://10.0.2.2:8000/storage/vendors/covers/a.jpg',
      );
      expect(
        ApiConfig.resolveMedia('http://127.0.0.1:8000/storage/a.jpg', apiBaseUrl: api),
        'http://10.0.2.2:8000/storage/a.jpg',
      );
    });

    test('a URL on any other host is left alone', () {
      const cdn = 'https://cdn.example.com/a.jpg';

      expect(ApiConfig.resolveMedia(cdn, apiBaseUrl: api), cdn);
    });

    test('a value that is not a full URL is left alone', () {
      expect(ApiConfig.resolveMedia('', apiBaseUrl: api), '');
      expect(ApiConfig.resolveMedia('storage/a.jpg', apiBaseUrl: api), 'storage/a.jpg');
    });
  });
}

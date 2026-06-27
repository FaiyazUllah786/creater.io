// Unit tests for Issue 9: Refresh response parsing in AuthInterceptor
//
// The bug: AuthInterceptor was attempting to read accessToken and refreshToken
// directly from the root of response.data, completely ignoring the ApiResponse
// envelope { success: true, data: { accessToken: "...", refreshToken: "..." } }
// returned by the Node.js backend.
//
// Run with:
//   flutter test test/auth_interceptor_parse_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:creatorio/core/models/api_response.dart';

void main() {
  group('Backend Response Parsing', () {
    // This is exactly what the backend returns for a successful refresh
    final Map<String, dynamic> mockBackendResponse = {
      'statusCode': 200,
      'message': 'Tokens refreshed successfully',
      'success': true,
      'data': {
        'user': {
          '_id': '123',
          'email': 'test@test.com',
        },
        'accessToken': 'new_access_token',
        'refreshToken': 'new_refresh_token',
      }
    };

    test('BUG: direct access returns null (demonstrating the failure)', () {
      // Simulate response.data['accessToken'] from the buggy code
      final buggyAccessToken = mockBackendResponse['accessToken'];
      final buggyRefreshToken = mockBackendResponse['refreshToken'];

      // They are null because they are nested inside 'data'
      expect(buggyAccessToken, isNull);
      expect(buggyRefreshToken, isNull);
    });

    test('FIX: ApiResponse.fromMap correctly extracts tokens', () {
      // Use the model to parse the envelope, just like the fix does
      final resMap = ApiResponse.fromMap(mockBackendResponse);

      final fixedAccessToken = resMap.data['accessToken'];
      final fixedRefreshToken = resMap.data['refreshToken'];

      expect(fixedAccessToken, equals('new_access_token'));
      expect(fixedRefreshToken, equals('new_refresh_token'));
    });

    test('ApiResponse gracefully handles missing fields in data', () {
      final Map<String, dynamic> malformedResponse = {
        'statusCode': 200,
        'message': 'success',
        'success': true,
        'data': {
          'accessToken': 'only_access_token',
          // refreshToken is missing
        }
      };

      final resMap = ApiResponse.fromMap(malformedResponse);

      expect(resMap.data['accessToken'], equals('only_access_token'));
      expect(resMap.data['refreshToken'], isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:creatorio/core/models/api_error.dart';

void main() {
  group('ApiError', () {
    test('fromMap() correctly parses valid JSON map', () {
      final map = {
        'statusCode': 400,
        'message': 'Bad Request',
        'data': null,
        'errors': ['Invalid email'],
        'success': false,
      };

      final error = ApiError.fromMap(map);

      expect(error.statusCode, equals(400));
      expect(error.message, equals('Bad Request'));
      expect(error.success, isFalse);
      expect(error.data, isNull);
      expect(error.errors, isA<List>());
      expect(error.errors.length, equals(1));
      expect(error.errors[0], equals('Invalid email'));
    });

    test(
        'fromMap() correctly handles missing errors list by using null or default',
        () {
      final map = {
        'statusCode': 500,
        'message': 'Internal Server Error',
        'data': null,
        'success': false,
        // missing 'errors'
      };

      final error = ApiError.fromMap(map);

      expect(error.statusCode, equals(500));
      expect(error.message, equals('Internal Server Error'));
      expect(
          error.errors, isEmpty); // Since map['errors'] is null, defaults to []
    });

    test('toMap() correctly serializes object to map', () {
      final error = ApiError(
        statusCode: 404,
        message: 'Not Found',
        data: 'Some string data',
        errors: ['Missing ID'],
        success: false,
      );

      final map = error.toMap();

      expect(map['statusCode'], equals(404));
      expect(map['message'], equals('Not Found'));
      expect(map['success'], isFalse);
      expect(map['data'], equals('Some string data'));
      expect(map['errors'], isA<List>());
      expect((map['errors'] as List)[0], equals('Missing ID'));
    });
  });
}

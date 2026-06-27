import 'package:flutter_test/flutter_test.dart';
import 'package:creatorio/core/models/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('fromMap() correctly parses valid JSON map', () {
      final map = {
        'statusCode': 200,
        'message': 'Success',
        'data': {'userId': '123'},
        'success': true,
      };

      final response = ApiResponse.fromMap(map);

      expect(response.statusCode, equals(200));
      expect(response.message, equals('Success'));
      expect(response.success, isTrue);
      expect(response.data, isA<Map>());
      expect(response.data['userId'], equals('123'));
    });

    test('toMap() correctly serializes object to map', () {
      final response = ApiResponse(
        statusCode: 201,
        message: 'Created',
        data: ['item1', 'item2'],
        success: true,
      );

      final map = response.toMap();

      expect(map['statusCode'], equals(201));
      expect(map['message'], equals('Created'));
      expect(map['success'], isTrue);
      expect(map['data'], isA<List>());
      expect((map['data'] as List).length, equals(2));
    });
  });
}

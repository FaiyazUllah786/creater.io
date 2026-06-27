import 'package:flutter_test/flutter_test.dart';
import 'package:creatorio/model/image_model.dart';

void main() {
  group('ImageModel', () {
    test('fromMap() correctly parses valid JSON map', () {
      final map = {
        '_id': 'img_123',
        'publicId': 'pub_123',
        'secureUrl': 'https://example.com/img.png',
        'height': 1080,
        'width': 1920,
        'author': 'user_456',
        'createdAt': '2023-10-01T12:00:00.000Z',
      };

      final image = ImageModel.fromMap(map);

      expect(image.id, equals('img_123'));
      expect(image.publicId, equals('pub_123'));
      expect(image.secureUrl, equals('https://example.com/img.png'));
      expect(image.height, equals(1080));
      expect(image.width, equals(1920));
      expect(image.author, equals('user_456'));
      expect(image.createdAt, equals(DateTime.parse('2023-10-01T12:00:00.000Z')));
    });

    test('toMap() correctly serializes object to map', () {
      final image = ImageModel(
        id: 'img_999',
        publicId: 'pub_999',
        secureUrl: 'https://example.com/999.jpg',
        height: 600,
        width: 800,
        author: 'user_111',
        createdAt: DateTime.parse('2023-12-25T00:00:00.000Z'),
      );

      final map = image.toMap();

      expect(map['id'], equals('img_999'));
      expect(map['publicId'], equals('pub_999'));
      expect(map['secureUrl'], equals('https://example.com/999.jpg'));
      expect(map['height'], equals(600));
      expect(map['width'], equals(800));
      expect(map['author'], equals('user_111'));
      expect(map['createdAt'], equals(DateTime.parse('2023-12-25T00:00:00.000Z')));
    });
  });
}

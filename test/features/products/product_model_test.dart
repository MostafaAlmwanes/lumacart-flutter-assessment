import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/features/products/domain/product.dart';

void main() {
  group('Product.fromJson', () {
    test('parses a complete Fake Store API product', () {
      final Product product = Product.fromJson(<String, Object?>{
        'id': 3,
        'title': 'Cotton jacket',
        'price': 55.99,
        'description': 'Warm and comfortable',
        'category': "men's clothing",
        'image': 'https://example.com/image.png',
        'rating': <String, Object?>{'rate': 4.7, 'count': 500},
      });

      expect(product.id, 3);
      expect(product.priceCents, 5599);
      expect(product.rating, const Rating(rate: 4.7, count: 500));
      expect(product.isUsable, isTrue);
    });

    test('clamps invalid and negative numeric values safely', () {
      final Product product = Product.fromJson(<String, Object?>{
        'id': 5,
        'title': 'Malformed price',
        'price': double.nan,
        'rating': <String, Object?>{
          'rate': double.infinity,
          'count': -4,
        },
      });
      final Product negative = Product.fromJson(<String, Object?>{
        'id': 6,
        'title': 'Negative price',
        'price': -10,
      });

      expect(product.price, 0);
      expect(product.rating, Rating.empty);
      expect(negative.price, 0);
    });

    test('uses defensive defaults for malformed fields', () {
      final Product product = Product.fromJson(<String, Object?>{
        'id': '4',
        'price': '12.50',
        'rating': null,
      });

      expect(product.id, 4);
      expect(product.title, 'Untitled product');
      expect(product.priceCents, 1250);
      expect(product.rating, Rating.empty);
    });
  });
}

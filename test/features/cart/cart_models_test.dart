import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  test('calculates item count and totals in integer cents', () {
    final LocalCart cart = LocalCart(
      ownerKey: 'local:test',
      lines: const <CartLine>[
        CartLine(product: testProduct, quantity: 3),
        CartLine(product: secondProduct, quantity: 2),
      ],
      updatedAt: DateTime.utc(2026, 7, 13),
    );

    expect(cart.itemCount, 5);
    expect(cart.subtotalCents, 11097);
    expect(cart.grandTotalCents, 11097);
  });

  test('clamps persisted quantities to supported bounds', () {
    final CartLine line = CartLine.fromJson(<String, Object?>{
      'product': testProduct.toJson(),
      'quantity': 1000,
    });

    expect(line.quantity, 99);
  });
}

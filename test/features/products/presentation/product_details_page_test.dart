import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:lumacart/features/products/presentation/bloc/product_details_cubit.dart';
import 'package:lumacart/features/products/presentation/pages/product_details_page.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  testWidgets('adds selected product quantity to the active cart', (
    WidgetTester tester,
  ) async {
    final FakeProductsRepository productsRepository = FakeProductsRepository()
      ..product = testProduct;
    final ProductDetailsCubit detailsCubit = ProductDetailsCubit(
      repository: productsRepository,
      initialProduct: testProduct,
    );
    final CartBloc cartBloc = CartBloc(repository: MemoryCartRepository())
      ..add(CartOwnerChanged(testSession));
    await cartBloc.stream.firstWhere(
      (CartState state) => state.status == CartStatus.ready,
    );
    addTearDown(detailsCubit.close);
    addTearDown(cartBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProductDetailsCubit>.value(value: detailsCubit),
          BlocProvider<CartBloc>.value(value: cartBloc),
        ],
        child: const MaterialApp(
          home: ProductDetailsPage(productId: 1),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    await tester.tap(find.text(r'Add 2 to cart · $39.98'));
    await tester.pumpAndSettle();

    expect(cartBloc.state.cart?.lines.single.quantity, 2);
  });
}

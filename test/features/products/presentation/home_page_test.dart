import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:lumacart/features/products/domain/product.dart';
import 'package:lumacart/features/products/domain/products_repository.dart';
import 'package:lumacart/features/products/presentation/bloc/products_bloc.dart';
import 'package:lumacart/features/products/presentation/pages/home_page.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  testWidgets('renders product grid success state and search empty state', (
    WidgetTester tester,
  ) async {
    final FakeProductsRepository productsRepository = FakeProductsRepository()
      ..result = const ProductCatalogResult(
        products: <Product>[testProduct, secondProduct],
        categories: <String>['bags', 'clothing'],
        fromCache: false,
      );
    final ProductsBloc productsBloc = ProductsBloc(
      repository: productsRepository,
    )..add(const ProductsLoadRequested());
    final AuthBloc authBloc = AuthBloc(
      repository: FakeAuthRepository(),
    );
    final CartBloc cartBloc = CartBloc(repository: MemoryCartRepository())
      ..add(CartOwnerChanged(testSession));
    addTearDown(productsBloc.close);
    addTearDown(authBloc.close);
    addTearDown(cartBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<ProductsBloc>.value(value: productsBloc),
          BlocProvider<CartBloc>.value(value: cartBloc),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test backpack'), findsOneWidget);
    expect(find.text('Test jacket'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'no-match');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('No products found'), findsOneWidget);
  });
}

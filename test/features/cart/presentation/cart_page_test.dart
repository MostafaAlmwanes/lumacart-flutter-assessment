import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:lumacart/features/cart/presentation/pages/cart_page.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  testWidgets('renders the empty-cart state', (WidgetTester tester) async {
    final CartBloc bloc = CartBloc(repository: MemoryCartRepository())
      ..add(CartOwnerChanged(testSession));
    await bloc.stream.firstWhere((CartState state) => state.status == CartStatus.ready);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<CartBloc>.value(
        value: bloc,
        child: const MaterialApp(home: CartPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('renders quantity, line item, and integer-cent total', (
    WidgetTester tester,
  ) async {
    final MemoryCartRepository repository = MemoryCartRepository()
      ..current[testSession.accountKey] = testCart();
    final CartBloc bloc = CartBloc(repository: repository)
      ..add(CartOwnerChanged(testSession));
    await bloc.stream.firstWhere((CartState state) => state.status == CartStatus.ready);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<CartBloc>.value(
        value: bloc,
        child: const MaterialApp(home: CartPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Test backpack'), findsOneWidget);
    expect(find.text(r'$39.98'), findsWidgets);
    expect(find.text('2'), findsWidgets);
  });
}

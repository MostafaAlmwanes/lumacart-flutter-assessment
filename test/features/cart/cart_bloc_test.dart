import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  late MemoryCartRepository repository;

  setUp(() => repository = MemoryCartRepository());

  blocTest<CartBloc, CartState>(
    'loads an owner cart and adds duplicate products by increasing quantity',
    build: () => CartBloc(repository: repository),
    act: (CartBloc bloc) async {
      bloc.add(CartOwnerChanged(testSession));
      await bloc.stream.firstWhere((CartState state) => state.status == CartStatus.ready);
      bloc.add(const CartProductAdded(testProduct));
      await bloc.stream.firstWhere((CartState state) => state.itemCount == 1);
      bloc.add(const CartProductAdded(testProduct, quantity: 2));
    },
    verify: (CartBloc bloc) {
      expect(bloc.state.cart?.lines, hasLength(1));
      expect(bloc.state.cart?.lines.single.quantity, 3);
      expect(repository.saveCurrentCalls, 2);
    },
  );

  blocTest<CartBloc, CartState>(
    'does not decrement an existing line below one',
    build: () {
      repository.current[testSession.accountKey] = LocalCart(
        ownerKey: testSession.accountKey,
        lines: const <CartLine>[CartLine(product: testProduct, quantity: 1)],
        updatedAt: DateTime.utc(2026, 7, 13),
      );
      return CartBloc(repository: repository);
    },
    act: (CartBloc bloc) async {
      bloc.add(CartOwnerChanged(testSession));
      await bloc.stream.firstWhere((CartState state) => state.status == CartStatus.ready);
      bloc.add(const CartQuantityDecremented(1));
    },
    verify: (CartBloc bloc) =>
        expect(bloc.state.cart?.lines.single.quantity, 1),
  );

  blocTest<CartBloc, CartState>(
    'restores a saved cart by replacing the current lines',
    build: () {
      repository.current[testSession.accountKey] = testCart();
      repository.saved.add(
        SavedCart(
          id: 'replacement',
          ownerKey: testSession.accountKey,
          name: 'Replacement',
          lines: const <CartLine>[
            CartLine(product: secondProduct, quantity: 3),
          ],
          createdAt: DateTime.utc(2026, 7, 13),
        ),
      );
      return CartBloc(repository: repository);
    },
    act: (CartBloc bloc) async {
      bloc.add(CartOwnerChanged(testSession));
      await bloc.stream.firstWhere(
        (CartState state) => state.status == CartStatus.ready,
      );
      bloc.add(
        const CartRestoreRequested('replacement', RestoreMode.replace),
      );
    },
    verify: (CartBloc bloc) {
      expect(bloc.state.cart?.lines, hasLength(1));
      expect(bloc.state.cart?.lines.single.product, secondProduct);
      expect(bloc.state.cart?.lines.single.quantity, 3);
    },
  );

  blocTest<CartBloc, CartState>(
    'saves, restores with merge, and deletes a snapshot',
    build: () {
      repository.current[testSession.accountKey] = testCart();
      return CartBloc(repository: repository);
    },
    act: (CartBloc bloc) async {
      bloc.add(CartOwnerChanged(testSession));
      await bloc.stream.firstWhere((CartState state) => state.status == CartStatus.ready);
      bloc.add(const CartSaveRequested('Weekend cart'));
      await bloc.stream.firstWhere((CartState state) => state.savedCarts.isNotEmpty);
      final String id = bloc.state.savedCarts.single.id;
      bloc.add(CartRestoreRequested(id, RestoreMode.merge));
      await bloc.stream.firstWhere(
        (CartState state) => state.cart?.lines.single.quantity == 4,
      );
      bloc.add(CartSavedDeleted(id));
    },
    verify: (CartBloc bloc) {
      expect(bloc.state.cart?.lines.single.quantity, 4);
      expect(bloc.state.savedCarts, isEmpty);
    },
  );
}

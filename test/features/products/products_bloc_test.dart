import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/features/products/domain/product.dart';
import 'package:lumacart/features/products/domain/products_repository.dart';
import 'package:lumacart/features/products/presentation/bloc/products_bloc.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  late FakeProductsRepository repository;

  setUp(() {
    repository = FakeProductsRepository()
      ..result = const ProductCatalogResult(
        products: <Product>[testProduct, secondProduct],
        categories: <String>['bags', 'clothing'],
        fromCache: false,
      );
  });

  blocTest<ProductsBloc, ProductsState>(
    'loads products and categories',
    build: () => ProductsBloc(repository: repository),
    act: (ProductsBloc bloc) => bloc.add(const ProductsLoadRequested()),
    verify: (ProductsBloc bloc) {
      expect(bloc.state.status, ProductsStatus.success);
      expect(bloc.state.visibleProducts, hasLength(2));
      expect(bloc.state.categories, <String>['bags', 'clothing']);
    },
  );

  blocTest<ProductsBloc, ProductsState>(
    'filters by category without doing work inside widgets',
    build: () => ProductsBloc(repository: repository),
    act: (ProductsBloc bloc) async {
      bloc.add(const ProductsLoadRequested());
      await bloc.stream.firstWhere(
        (ProductsState state) => state.status == ProductsStatus.success,
      );
      bloc.add(const ProductsCategorySelected('clothing'));
    },
    verify: (ProductsBloc bloc) {
      expect(bloc.state.visibleProducts, const <Product>[secondProduct]);
    },
  );

  blocTest<ProductsBloc, ProductsState>(
    'emits failure when neither network nor cache is available',
    build: () {
      repository.error = const Failure(
        message: 'Offline',
        type: FailureType.network,
      );
      return ProductsBloc(repository: repository);
    },
    act: (ProductsBloc bloc) => bloc.add(const ProductsLoadRequested()),
    verify: (ProductsBloc bloc) {
      expect(bloc.state.status, ProductsStatus.failure);
      expect(bloc.state.message, 'Offline');
    },
  );
}

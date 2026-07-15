import 'package:flutter_test/flutter_test.dart';
import 'package:lumacart/core/constants/api_paths.dart';
import 'package:lumacart/core/constants/storage_keys.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/core/network/api_client.dart';
import 'package:lumacart/core/storage/local_store.dart';
import 'package:lumacart/features/products/data/products_repository_impl.dart';
import 'package:lumacart/features/products/domain/products_repository.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/test_fixtures.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockLocalStore extends Mock implements LocalStore {}

void main() {
  late _MockApiClient apiClient;
  late _MockLocalStore localStore;
  late ProductsRepositoryImpl repository;

  setUp(() {
    apiClient = _MockApiClient();
    localStore = _MockLocalStore();
    repository = ProductsRepositoryImpl(
      apiClient: apiClient,
      localStore: localStore,
    );
    when(() => localStore.writeCatalog(any(), any()))
        .thenAnswer((_) async {});
  });

  test('returns remote catalog and caches the successful payload', () async {
    when(() => apiClient.get(ApiPaths.products)).thenAnswer(
      (_) async => <Object?>[testProduct.toJson()],
    );
    when(() => apiClient.get(ApiPaths.categories)).thenAnswer(
      (_) async => <Object?>['bags'],
    );

    final ProductCatalogResult result = await repository.loadCatalog();

    expect(result.fromCache, isFalse);
    expect(result.products, <Object>[testProduct]);
    verify(
      () => localStore.writeCatalog(
        StorageKeys.cachedProducts,
        any(),
      ),
    ).called(1);
  });

  test('falls back to cached catalog after a network failure', () async {
    when(() => apiClient.get(ApiPaths.products)).thenThrow(
      const Failure(message: 'Offline', type: FailureType.network),
    );
    when(
      () => localStore.readCatalog<Object?>(StorageKeys.cachedProducts),
    ).thenReturn(<Object?>[testProduct.toJson()]);

    final ProductCatalogResult result = await repository.loadCatalog();

    expect(result.fromCache, isTrue);
    expect(result.products, <Object>[testProduct]);
    expect(result.warning, contains('Showing the last saved catalog'));
  });
}

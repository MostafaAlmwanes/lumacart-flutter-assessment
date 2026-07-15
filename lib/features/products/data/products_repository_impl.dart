import 'package:lumacart/core/constants/api_paths.dart';
import 'package:lumacart/core/constants/storage_keys.dart';
import 'package:lumacart/core/errors/failure.dart';
import 'package:lumacart/core/network/api_client.dart';
import 'package:lumacart/core/storage/local_store.dart';
import 'package:lumacart/core/utils/json_parsing.dart';
import 'package:lumacart/features/products/domain/product.dart';
import 'package:lumacart/features/products/domain/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl({
    required ApiClient apiClient,
    required LocalStore localStore,
  })  : _apiClient = apiClient,
        _localStore = localStore;

  final ApiClient _apiClient;
  final LocalStore _localStore;

  @override
  Future<ProductCatalogResult> loadCatalog() async {
    try {
      final Object? productsResponse = await _apiClient.get(ApiPaths.products);
      final List<Product> products = _parseProducts(productsResponse);
      if (products.isEmpty) {
        throw const Failure(
          message: 'The store returned an empty product catalog.',
          type: FailureType.parsing,
        );
      }

      late final List<String> categories;
      try {
        final Object? categoriesResponse =
            await _apiClient.get(ApiPaths.categories);
        categories = listValue(categoriesResponse)
            .map((Object? item) => stringValue(item))
            .where((String category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
      } on Failure {
        categories = _deriveCategories(products);
      }

      String? warning;
      try {
        await _localStore.writeCatalog(
          StorageKeys.cachedProducts,
          products.map((Product item) => item.toJson()).toList(),
        );
        await _localStore.writeCatalog(
          StorageKeys.cachedProductsAt,
          DateTime.now().toUtc().toIso8601String(),
        );
      } on Failure {
        warning = 'Products loaded, but the offline cache could not be updated.';
      }
      return ProductCatalogResult(
        products: products,
        categories: categories,
        fromCache: false,
        warning: warning,
      );
    } on Failure catch (failure) {
      final List<Product> cached = _readCachedProducts();
      if (cached.isEmpty) rethrow;
      return ProductCatalogResult(
        products: cached,
        categories: _deriveCategories(cached),
        fromCache: true,
        warning: '${failure.message} Showing the last saved catalog.',
      );
    }
  }

  @override
  Future<Product> getProduct(int id) async {
    try {
      final Product product = Product.fromJson(
        await _apiClient.get(ApiPaths.product(id)),
      );
      if (!product.isUsable) {
        throw const Failure(
          message: 'The product response was incomplete.',
          type: FailureType.parsing,
        );
      }
      return product;
    } on Failure {
      final Product? cached = _readCachedProducts()
          .where((Product product) => product.id == id)
          .firstOrNull;
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      return _parseProducts(
        await _apiClient.get(ApiPaths.productsByCategory(category)),
      );
    } on Failure {
      final String normalized = category.toLowerCase();
      final List<Product> cached = _readCachedProducts()
          .where((Product product) =>
              product.category.toLowerCase() == normalized)
          .toList(growable: false);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  List<Product> _readCachedProducts() {
    final Object? raw =
        _localStore.readCatalog<Object?>(StorageKeys.cachedProducts);
    return _parseProducts(raw);
  }

  List<Product> _parseProducts(Object? raw) {
    return listValue(raw)
        .map(Product.fromJson)
        .where((Product product) => product.isUsable)
        .toList(growable: false);
  }

  List<String> _deriveCategories(List<Product> products) {
    return products
        .map((Product product) => product.category)
        .where((String category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }
}


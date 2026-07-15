import 'package:equatable/equatable.dart';
import 'package:lumacart/features/products/domain/product.dart';

class ProductCatalogResult extends Equatable {
  const ProductCatalogResult({
    required this.products,
    required this.categories,
    required this.fromCache,
    this.warning,
  });

  final List<Product> products;
  final List<String> categories;
  final bool fromCache;
  final String? warning;

  @override
  List<Object?> get props => <Object?>[
        products,
        categories,
        fromCache,
        warning,
      ];
}

abstract class ProductsRepository {
  Future<ProductCatalogResult> loadCatalog();

  Future<Product> getProduct(int id);

  Future<List<Product>> getProductsByCategory(String category);
}

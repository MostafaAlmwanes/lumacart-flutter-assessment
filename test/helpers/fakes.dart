import 'package:lumacart/features/auth/domain/auth_models.dart';
import 'package:lumacart/features/auth/domain/auth_repository.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';
import 'package:lumacart/features/cart/domain/cart_repository.dart';
import 'package:lumacart/features/products/domain/product.dart';
import 'package:lumacart/features/products/domain/products_repository.dart';

class FakeAuthRepository implements AuthRepository {
  AuthSession? restoredSession;
  AuthResult? signInResult;
  AuthResult? signUpResult;
  Object? error;
  bool signedOut = false;

  @override
  Future<AuthSession?> restoreSession() async {
    if (error != null) throw error!;
    return restoredSession;
  }

  @override
  Future<StoreUser> getUser(int id) async {
    if (error != null) throw error!;
    final StoreUser? user = restoredSession?.user ??
        signInResult?.session.user ??
        signUpResult?.session.user;
    if (user == null) throw StateError('No fake user configured.');
    return user;
  }

  @override
  Future<AuthResult> signIn({
    required String username,
    required String password,
  }) async {
    if (error != null) throw error!;
    return signInResult!;
  }

  @override
  Future<AuthResult> signUp(SignUpInput input) async {
    if (error != null) throw error!;
    return signUpResult!;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

class FakeProductsRepository implements ProductsRepository {
  ProductCatalogResult result = const ProductCatalogResult(
    products: <Product>[],
    categories: <String>[],
    fromCache: false,
  );
  Product? product;
  Object? error;

  @override
  Future<Product> getProduct(int id) async {
    if (error != null) throw error!;
    return product!;
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    if (error != null) throw error!;
    return result.products
        .where((Product item) => item.category == category)
        .toList();
  }

  @override
  Future<ProductCatalogResult> loadCatalog() async {
    if (error != null) throw error!;
    return result;
  }
}

class MemoryCartRepository implements CartRepository {
  final Map<String, LocalCart> current = <String, LocalCart>{};
  final List<SavedCart> saved = <SavedCart>[];
  int saveCurrentCalls = 0;

  @override
  Future<void> deleteSaved(String savedCartId) async {
    saved.removeWhere((SavedCart cart) => cart.id == savedCartId);
  }

  @override
  Future<LocalCart> loadCurrent(String ownerKey) async =>
      current[ownerKey] ?? LocalCart.empty(ownerKey);

  @override
  Future<List<Cart>> loadRemoteHistory(int userId) async => <Cart>[];

  @override
  Future<List<SavedCart>> loadSaved(String ownerKey) async => saved
      .where((SavedCart cart) => cart.ownerKey == ownerKey)
      .toList(growable: false);

  @override
  Future<void> saveCurrent(LocalCart cart) async {
    saveCurrentCalls += 1;
    current[cart.ownerKey] = cart;
  }

  @override
  Future<SavedCartResult> saveSnapshot({
    required LocalCart cart,
    required String name,
    int? apiUserId,
  }) async {
    final SavedCart snapshot = SavedCart(
      id: 'saved-${saved.length + 1}',
      ownerKey: cart.ownerKey,
      name: name,
      lines: cart.lines,
      createdAt: DateTime.utc(2026, 7, 13, saved.length),
    );
    saved.insert(0, snapshot);
    return SavedCartResult(savedCart: snapshot);
  }
}

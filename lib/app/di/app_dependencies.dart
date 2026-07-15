import 'package:lumacart/core/network/api_client.dart';
import 'package:lumacart/core/storage/local_store.dart';
import 'package:lumacart/features/auth/data/auth_repository_impl.dart';
import 'package:lumacart/features/auth/data/secure_session_store.dart';
import 'package:lumacart/features/auth/domain/auth_repository.dart';
import 'package:lumacart/features/cart/data/cart_repository_impl.dart';
import 'package:lumacart/features/cart/domain/cart_repository.dart';
import 'package:lumacart/features/products/data/products_repository_impl.dart';
import 'package:lumacart/features/products/domain/products_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.productsRepository,
    required this.cartRepository,
  });

  final AuthRepository authRepository;
  final ProductsRepository productsRepository;
  final CartRepository cartRepository;

  static Future<AppDependencies> initialize() async {
    final LocalStore localStore = await LocalStore.initialize();
    final ApiClient apiClient = ApiClient();
    final SecureSessionStore sessionStore = SecureSessionStore();
    return AppDependencies(
      authRepository: AuthRepositoryImpl(
        apiClient: apiClient,
        localStore: localStore,
        sessionStore: sessionStore,
      ),
      productsRepository: ProductsRepositoryImpl(
        apiClient: apiClient,
        localStore: localStore,
      ),
      cartRepository: CartRepositoryImpl(
        localStore: localStore,
        apiClient: apiClient,
      ),
    );
  }
}

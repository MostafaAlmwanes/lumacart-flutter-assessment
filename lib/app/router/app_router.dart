import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumacart/app/router/app_shell.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lumacart/features/auth/presentation/pages/sign_in_page.dart';
import 'package:lumacart/features/auth/presentation/pages/sign_up_page.dart';
import 'package:lumacart/features/auth/presentation/pages/splash_page.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';
import 'package:lumacart/features/cart/presentation/pages/cart_page.dart';
import 'package:lumacart/features/cart/presentation/pages/saved_cart_details_page.dart';
import 'package:lumacart/features/cart/presentation/pages/saved_carts_page.dart';
import 'package:lumacart/features/products/domain/product.dart';
import 'package:lumacart/features/products/domain/products_repository.dart';
import 'package:lumacart/features/products/presentation/bloc/product_details_cubit.dart';
import 'package:lumacart/features/products/presentation/pages/home_page.dart';
import 'package:lumacart/features/products/presentation/pages/product_details_page.dart';
import 'package:lumacart/features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  AppRouter({
    required AuthBloc authBloc,
    required ProductsRepository productsRepository,
  })  : _authBloc = authBloc,
        _productsRepository = productsRepository,
        _refresh = GoRouterRefreshStream(authBloc.stream) {
    router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _refresh,
      redirect: _redirect,
      routes: <RouteBase>[
        GoRoute(
          path: '/splash',
          builder: (BuildContext context, GoRouterState state) =>
              const SplashPage(),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (BuildContext context, GoRouterState state) =>
              const SignInPage(),
        ),
        GoRoute(
          path: '/sign-up',
          builder: (BuildContext context, GoRouterState state) =>
              const SignUpPage(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) => AppShell(navigationShell: navigationShell),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/home',
                  builder: (BuildContext context, GoRouterState state) =>
                      const HomePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/cart',
                  builder: (BuildContext context, GoRouterState state) =>
                      const CartPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/saved',
                  builder: (BuildContext context, GoRouterState state) =>
                      const SavedCartsPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: '/profile',
                  builder: (BuildContext context, GoRouterState state) =>
                      const ProfilePage(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/products/:id',
          builder: (BuildContext context, GoRouterState state) {
            final int id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            final Product? initialProduct = state.extra is Product
                ? state.extra! as Product
                : null;
            return BlocProvider<ProductDetailsCubit>(
              create: (_) {
                final ProductDetailsCubit cubit = ProductDetailsCubit(
                  repository: _productsRepository,
                  initialProduct: initialProduct,
                );
                unawaited(cubit.load(id));
                return cubit;
              },
              child: ProductDetailsPage(productId: id),
            );
          },
        ),
        GoRoute(
          path: '/saved/:id',
          builder: (BuildContext context, GoRouterState state) {
            final SavedCart? cart = state.extra is SavedCart
                ? state.extra! as SavedCart
                : null;
            if (cart == null) return const SavedCartsPage();
            return SavedCartDetailsPage(savedCart: cart);
          },
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Return home'),
          ),
        ),
      ),
    );
  }

  final AuthBloc _authBloc;
  final ProductsRepository _productsRepository;
  final GoRouterRefreshStream _refresh;
  late final GoRouter router;

  String? _redirect(BuildContext context, GoRouterState state) {
    final AuthState auth = _authBloc.state;
    final String path = state.uri.path;
    final bool authRoute = path == '/sign-in' || path == '/sign-up';
    if (auth.status == AuthStatus.initial ||
        auth.status == AuthStatus.restoringSession) {
      return path == '/splash' ? null : '/splash';
    }
    if (auth.isAuthenticated) {
      return path == '/splash' || authRoute ? '/home' : null;
    }
    if (path == '/splash') return '/sign-in';
    final bool publicRoute = authRoute;
    return publicRoute ? null : '/sign-in';
  }

  void dispose() {
    _refresh.dispose();
    router.dispose();
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<Object?> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

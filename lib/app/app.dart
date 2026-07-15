import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumacart/app/di/app_dependencies.dart';
import 'package:lumacart/app/router/app_router.dart';
import 'package:lumacart/app/theme/app_theme.dart';
import 'package:lumacart/core/constants/app_constants.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:lumacart/features/products/presentation/bloc/products_bloc.dart';

class LumaCartApp extends StatefulWidget {
  const LumaCartApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<LumaCartApp> createState() => _LumaCartAppState();
}

class _LumaCartAppState extends State<LumaCartApp> {
  late final AuthBloc _authBloc = AuthBloc(
    repository: widget.dependencies.authRepository,
  )..add(const AuthSessionRestoreRequested());
  late final ProductsBloc _productsBloc = ProductsBloc(
    repository: widget.dependencies.productsRepository,
  );
  late final CartBloc _cartBloc = CartBloc(
    repository: widget.dependencies.cartRepository,
  );
  late final AppRouter _appRouter = AppRouter(
    authBloc: _authBloc,
    productsRepository: widget.dependencies.productsRepository,
  );

  @override
  void dispose() {
    _appRouter.dispose();
    unawaited(_authBloc.close());
    unawaited(_productsBloc.close());
    unawaited(_cartBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<ProductsBloc>.value(value: _productsBloc),
        BlocProvider<CartBloc>.value(value: _cartBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (AuthState previous, AuthState current) =>
            previous.session != current.session ||
            previous.status != current.status,
        listener: (BuildContext context, AuthState state) {
          if (state.isAuthenticated) {
            _cartBloc.add(CartOwnerChanged(state.session));
            if (_productsBloc.state.status == ProductsStatus.initial) {
              _productsBloc.add(const ProductsLoadRequested());
            }
          } else if (state.status == AuthStatus.unauthenticated) {
            _cartBloc.add(const CartOwnerChanged(null));
          }
        },
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (CartState previous, CartState current) =>
          previous != current &&
          (current.message != null || current.notice != null),
      listener: (BuildContext context, CartState state) {
        final String? feedback = state.message ?? state.notice;
        if (feedback == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(feedback)));
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (int index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: <NavigationDestination>[
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: BlocSelector<CartBloc, CartState, int>(
                selector: (CartState state) => state.itemCount,
                builder: (BuildContext context, int count) =>
                    _AnimatedCartIcon(count: count),
              ),
              selectedIcon: BlocSelector<CartBloc, CartState, int>(
                selector: (CartState state) => state.itemCount,
                builder: (BuildContext context, int count) =>
                    _AnimatedCartIcon(count: count, selected: true),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bookmarks_outlined),
              selectedIcon: Icon(Icons.bookmarks),
              label: 'Saved',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCartIcon extends StatelessWidget {
  const _AnimatedCartIcon({required this.count, this.selected = false});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Badge(
      isLabelVisible: count > 0,
      label: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        transitionBuilder: (Widget child, Animation<double> animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Text(
          count > 99 ? '99+' : '$count',
          key: ValueKey<int>(count),
        ),
      ),
      child: Icon(
        selected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
      ),
    );
  }
}

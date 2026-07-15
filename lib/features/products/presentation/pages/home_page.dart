import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumacart/app/theme/design_tokens.dart';
import 'package:lumacart/core/widgets/loading_skeleton.dart';
import 'package:lumacart/core/widgets/state_panels.dart';
import 'package:lumacart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:lumacart/features/products/domain/product.dart';
import 'package:lumacart/features/products/presentation/bloc/products_bloc.dart';
import 'package:lumacart/features/products/presentation/widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final String? authWarning = context.select<AuthBloc, String?>(
      (AuthBloc bloc) => bloc.state.warning,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('LumaCart'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh products',
            onPressed: () => context
                .read<ProductsBloc>()
                .add(const ProductsRefreshRequested()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<ProductsBloc, ProductsState>(
        listenWhen: (ProductsState previous, ProductsState current) =>
            previous.message != current.message && current.message != null,
        listener: (BuildContext context, ProductsState state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        },
        builder: (BuildContext context, ProductsState state) {
          final Widget content;
          final String contentKey;
          if (state.status == ProductsStatus.loading &&
              state.allProducts.isEmpty) {
            content = const ProductGridSkeleton();
            contentKey = 'loading';
          } else if (state.status == ProductsStatus.failure &&
              state.allProducts.isEmpty) {
            content = ErrorPanel(
              message: state.message ?? 'Products could not be loaded.',
              onRetry: () => context
                  .read<ProductsBloc>()
                  .add(const ProductsLoadRequested()),
            );
            contentKey = 'failure';
          } else {
            content = _catalogScaffold(
              context,
              state,
              authWarning: authWarning,
              textScale: textScale,
            );
            contentKey = 'catalog';
          }
          return AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppDurations.standard,
            child: KeyedSubtree(
              key: ValueKey<String>(contentKey),
              child: content,
            ),
          );
        },
      ),
    );
  }

  Widget _catalogScaffold(
    BuildContext context,
    ProductsState state, {
    required String? authWarning,
    required double textScale,
  }) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search products or categories',
            leading: const Icon(Icons.search),
            trailing: <Widget>[
              if (state.searchQuery.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<ProductsBloc>()
                        .add(const ProductsSearchChanged(''));
                  },
                  icon: const Icon(Icons.clear),
                ),
            ],
            onChanged: (String value) => context
                .read<ProductsBloc>()
                .add(ProductsSearchChanged(value)),
          ),
        ),
        SizedBox(
          height: textScale > 1.3 ? 72 : 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            children: <Widget>[
              ChoiceChip(
                label: const Text('All'),
                selected: state.selectedCategory == null,
                onSelected: (_) => context
                    .read<ProductsBloc>()
                    .add(const ProductsCategorySelected(null)),
              ),
              for (final String category in state.categories) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                ChoiceChip(
                  label: Text(category),
                  selected: state.selectedCategory == category,
                  onSelected: (_) => context
                      .read<ProductsBloc>()
                      .add(ProductsCategorySelected(category)),
                ),
              ],
            ],
          ),
        ),
        if (state.warning != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: InlineNotice(message: state.warning!),
          ),
        if (authWarning != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: InlineNotice(message: authWarning),
          ),
        Expanded(child: _catalog(context, state)),
      ],
    );
  }

  Widget _catalog(BuildContext context, ProductsState state) {
    if (state.visibleProducts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: EmptyStatePanel(
                illustration: Image.asset(
                  'assets/generated/no_results.png',
                  width: 220,
                  height: 165,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                title: 'No products found',
                message: 'Try a different search or clear the category filter.',
                actionLabel: 'Clear filters',
                onAction: () {
                  _searchController.clear();
                  context
                      .read<ProductsBloc>()
                      .add(const ProductsSearchChanged(''));
                  context
                      .read<ProductsBloc>()
                      .add(const ProductsCategorySelected(null));
                },
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final int columns;
        if (constraints.maxWidth < 360 || textScale > 1.3) {
          columns = 1;
        } else if (constraints.maxWidth >= 840) {
          columns = 4;
        } else if (constraints.maxWidth >= 600) {
          columns = 3;
        } else {
          columns = 2;
        }
        final double aspectRatio = columns == 1 ? 0.95 : 0.60;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: aspectRatio,
            ),
            itemCount: state.visibleProducts.length,
            itemBuilder: (BuildContext context, int index) {
              final Product product = state.visibleProducts[index];
              return ProductCard(
                product: product,
                onTap: () => unawaited(
                  context.push(
                    '/products/${product.id}',
                    extra: product,
                  ),
                ),
                onAdd: () => context
                    .read<CartBloc>()
                    .add(CartProductAdded(product)),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _refresh() async {
    final ProductsBloc bloc = context.read<ProductsBloc>();
    bloc.add(const ProductsRefreshRequested());
    await bloc.stream.firstWhere(
      (ProductsState state) => !state.isRefreshing,
    );
  }
}

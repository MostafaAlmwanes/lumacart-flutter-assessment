import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumacart/app/theme/design_tokens.dart';
import 'package:lumacart/core/utils/money.dart';
import 'package:lumacart/core/widgets/product_image.dart';
import 'package:lumacart/core/widgets/quantity_stepper.dart';
import 'package:lumacart/core/widgets/state_panels.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:lumacart/features/products/domain/product.dart';
import 'package:lumacart/features/products/presentation/bloc/product_details_cubit.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailsCubit, ProductDetailsState>(
      listenWhen: (ProductDetailsState previous, ProductDetailsState current) =>
          previous.message != current.message && current.message != null,
      listener: (BuildContext context, ProductDetailsState state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message!)),
        );
      },
      builder: (BuildContext context, ProductDetailsState state) {
        final Product? product = state.product;
        return Scaffold(
          appBar: AppBar(title: const Text('Product details')),
          body: _body(context, state, product),
          bottomNavigationBar: product == null
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.all(AppSpacing.md),
                  child: FilledButton.icon(
                    onPressed: () => context.read<CartBloc>().add(
                          CartProductAdded(
                            product,
                            quantity: state.quantity,
                          ),
                        ),
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: Text(
                      'Add ${state.quantity} to cart · '
                      '${Money.formatCents(product.priceCents * state.quantity)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    ProductDetailsState state,
    Product? product,
  ) {
    if (product == null &&
        (state.status == ProductDetailsStatus.initial ||
            state.status == ProductDetailsStatus.loading)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (product == null) {
      return ErrorPanel(
        message: state.message ?? 'Product details could not be loaded.',
        onRetry: () => unawaited(
          context.read<ProductDetailsCubit>().load(productId),
        ),
      );
    }
    return _content(context, state, product);
  }

  Widget _content(
    BuildContext context,
    ProductDetailsState state,
    Product product,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        112,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: HeroMode(
                      enabled: !MediaQuery.disableAnimationsOf(context),
                      child: Hero(
                        tag: 'product-${product.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: ProductImage(
                            imageUrl: product.imageUrl,
                            semanticLabel: product.title,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                product.category.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                product.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  Text(
                    Money.formatCents(product.priceCents),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.star_rounded),
                      const SizedBox(width: AppSpacing.xxs),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          '${product.rating.rate.toStringAsFixed(1)} · '
                          '${product.rating.count} ratings',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Quantity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              QuantityStepper(
                quantity: state.quantity,
                onDecrement: state.quantity <= 1
                    ? null
                    : context.read<ProductDetailsCubit>().decrement,
                onIncrement: context.read<ProductDetailsCubit>().increment,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                product.description.isEmpty
                    ? 'No description is available for this product.'
                    : product.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

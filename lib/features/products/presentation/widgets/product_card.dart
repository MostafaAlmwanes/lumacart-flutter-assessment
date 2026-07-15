import 'package:flutter/material.dart';
import 'package:lumacart/app/theme/design_tokens.dart';
import 'package:lumacart/core/utils/money.dart';
import 'package:lumacart/core/widgets/product_image.dart';
import 'package:lumacart/features/products/domain/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
    super.key,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                product.category.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  const Icon(Icons.star_rounded, size: 18),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${product.rating.rate.toStringAsFixed(1)} (${product.rating.count})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      Money.formatCents(product.priceCents),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Add ${product.title} to cart',
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

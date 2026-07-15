import 'package:flutter/material.dart';
import 'package:lumacart/app/theme/design_tokens.dart';
import 'package:lumacart/core/utils/money.dart';
import 'package:lumacart/core/widgets/product_image.dart';
import 'package:lumacart/core/widgets/quantity_stepper.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';

class CartLineCard extends StatelessWidget {
  const CartLineCard({
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    super.key,
  });

  final CartLine line;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox.square(
                  dimension: 88,
                  child: ProductImage(
                    imageUrl: line.product.imageUrl,
                    semanticLabel: line.product.title,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        line.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${Money.formatCents(line.product.priceCents)} each',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove ${line.product.title}',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                QuantityStepper(
                  quantity: line.quantity,
                  onDecrement: onDecrement,
                  onIncrement: onIncrement,
                  compact: true,
                ),
                Text(
                  Money.formatCents(line.lineTotalCents),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

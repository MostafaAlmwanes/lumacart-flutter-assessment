import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lumacart/app/theme/design_tokens.dart';
import 'package:lumacart/core/utils/money.dart';
import 'package:lumacart/core/widgets/product_image.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';

class SavedCartDetailsPage extends StatelessWidget {
  const SavedCartDetailsPage({required this.savedCart, super.key});

  final SavedCart savedCart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(savedCart.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Text(
            DateFormat.yMMMMd().add_jm().format(savedCart.createdAt.toLocal()),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final CartLine line in savedCart.lines) ...<Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 64,
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
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${line.quantity} × ${Money.formatCents(line.product.priceCents)}',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            Money.formatCents(line.lineTotalCents),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  Text('Total', style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    Money.formatCents(savedCart.totalCents),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stackButtons =
                constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final OutlinedButton mergeButton = OutlinedButton(
              onPressed: () => unawaited(
                _confirmRestore(context, RestoreMode.merge),
              ),
              child: const Text('Merge'),
            );
            final FilledButton replaceButton = FilledButton(
              onPressed: () => unawaited(
                _confirmRestore(context, RestoreMode.replace),
              ),
              child: const Text('Replace cart'),
            );
            if (stackButtons) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  mergeButton,
                  const SizedBox(height: AppSpacing.sm),
                  replaceButton,
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: mergeButton),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: replaceButton),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, RestoreMode mode) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(
              mode == RestoreMode.replace
                  ? 'Replace current cart?'
                  : 'Merge with current cart?',
            ),
            content: Text(
              mode == RestoreMode.replace
                  ? 'The current cart will be replaced by ${savedCart.name}.'
                  : 'Quantities from ${savedCart.name} will be added to matching products.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Restore'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      context.read<CartBloc>().add(CartRestoreRequested(savedCart.id, mode));
      context.go('/cart');
    }
  }
}

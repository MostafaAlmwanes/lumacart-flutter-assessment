import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lumacart/app/theme/design_tokens.dart';
import 'package:lumacart/core/utils/money.dart';
import 'package:lumacart/core/widgets/state_panels.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:lumacart/features/cart/presentation/widgets/cart_line_card.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: <Widget>[
          BlocBuilder<CartBloc, CartState>(
            builder: (BuildContext context, CartState state) {
              final bool enabled = state.cart?.isEmpty == false;
              return IconButton(
                tooltip: 'Clear cart',
                onPressed: enabled
                    ? () => unawaited(_confirmClear(context))
                    : null,
                icon: const Icon(Icons.delete_sweep_outlined),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (BuildContext context, CartState state) {
          if (state.status == CartStatus.loading || state.cart == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final LocalCart cart = state.cart!;
          if (state.status == CartStatus.failure &&
              cart.isEmpty &&
              state.message != null) {
            return ErrorPanel(
              message: state.message!,
              onRetry: state.session == null
                  ? null
                  : () => context.read<CartBloc>().add(
                      CartOwnerChanged(state.session),
                    ),
            );
          }
          if (cart.isEmpty) {
            return EmptyStatePanel(
              illustration: Image.asset(
                'assets/generated/empty_cart.png',
                width: 220,
                height: 165,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              title: 'Your cart is empty',
              message:
                  'Browse the catalog and add something worth carrying around.',
              actionLabel: 'Browse products',
              onAction: () => context.go('/home'),
            );
          }
          return Column(
            children: <Widget>[
              Expanded(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppDurations.standard,
                  child: ListView.separated(
                    key: ValueKey<String>(
                      cart.lines
                          .map((CartLine line) => line.product.id)
                          .join(','),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int index) {
                      final CartLine line = cart.lines[index];
                      return CartLineCard(
                        key: ValueKey<int>(line.product.id),
                        line: line,
                        onIncrement: () => context.read<CartBloc>().add(
                          CartQuantityIncremented(line.product.id),
                        ),
                        onDecrement: line.quantity <= 1
                            ? null
                            : () => context.read<CartBloc>().add(
                                CartQuantityDecremented(line.product.id),
                              ),
                        onRemove: () => _removeWithUndo(context, line),
                      );
                    },
                  ),
                ),
              ),
              _summary(context, cart, state.status == CartStatus.saving),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(BuildContext context, LocalCart cart, bool saving) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Items',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text('${cart.itemCount}', textAlign: TextAlign.end),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Subtotal',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    Money.formatCents(cart.subtotalCents),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    Money.formatCents(cart.grandTotalCents),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving
                    ? null
                    : () => unawaited(_showSaveDialog(context)),
                icon: saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeWithUndo(BuildContext context, CartLine line) {
    context.read<CartBloc>().add(CartProductRemoved(line.product.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${line.product.title} removed.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => context.read<CartBloc>().add(
              CartProductAdded(line.product, quantity: line.quantity),
            ),
          ),
        ),
      );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    final DateTime now = DateTime.now();
    final TextEditingController controller = TextEditingController(
      text:
          'Cart ${now.year}-${now.month.toString().padLeft(2, '0')}'
          '-${now.day.toString().padLeft(2, '0')}',
    );
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Save this cart'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Cart name'),
          onSubmitted: (String value) =>
              Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    context.read<CartBloc>().add(CartSaveRequested(name));
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Clear cart?'),
            content: const Text(
              'All current cart items will be removed. Saved carts are not affected.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Clear'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      context.read<CartBloc>().add(const CartClearRequested());
    }
  }
}

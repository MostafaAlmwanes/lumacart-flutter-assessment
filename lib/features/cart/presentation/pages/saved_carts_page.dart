import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lumacart/app/theme/design_tokens.dart';
import 'package:lumacart/core/utils/money.dart';
import 'package:lumacart/core/widgets/state_panels.dart';
import 'package:lumacart/features/cart/domain/cart_models.dart';
import 'package:lumacart/features/cart/presentation/bloc/cart_bloc.dart';

class SavedCartsPage extends StatelessWidget {
  const SavedCartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved carts')),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (BuildContext context, CartState state) {
          if (state.status == CartStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == CartStatus.failure &&
              state.savedCarts.isEmpty &&
              state.message != null) {
            return ErrorPanel(
              message: state.message!,
              onRetry: state.session == null
                  ? null
                  : () => context
                      .read<CartBloc>()
                      .add(CartOwnerChanged(state.session)),
            );
          }
          if (state.savedCarts.isEmpty) {
            return EmptyStatePanel(
              icon: Icons.bookmarks_outlined,
              title: 'No saved carts yet',
              message: 'Save a current cart to keep a reusable snapshot here.',
              actionLabel: 'Open cart',
              onAction: () => context.go('/cart'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.savedCarts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) {
              final SavedCart cart = state.savedCarts[index];
              return Card(
                child: InkWell(
                  onTap: () => unawaited(
                    context.push('/saved/${cart.id}', extra: cart),
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                cart.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Saved cart actions',
                              onSelected: (String action) {
                                if (action == 'restore') {
                                  unawaited(_restore(context, cart));
                                } else if (action == 'delete') {
                                  unawaited(_delete(context, cart));
                                }
                              },
                              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'restore',
                                  child: ListTile(
                                    leading: Icon(Icons.restore),
                                    title: Text('Restore'),
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline),
                                    title: Text('Delete'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          DateFormat.yMMMd()
                              .add_jm()
                              .format(cart.createdAt.toLocal()),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: <Widget>[
                            Chip(
                              avatar: const Icon(
                                Icons.shopping_bag_outlined,
                                size: 18,
                              ),
                              label: Text('${cart.itemCount} items'),
                            ),
                            Chip(
                              avatar: const Icon(
                                Icons.payments_outlined,
                                size: 18,
                              ),
                              label: Text(Money.formatCents(cart.totalCents)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _restore(BuildContext context, SavedCart cart) async {
    final RestoreMode? mode = await showDialog<RestoreMode>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Restore ${cart.name}?'),
        content: const Text(
          'Replace the current cart or merge matching products by adding '
          'their quantities.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(RestoreMode.merge),
            child: const Text('Merge'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(RestoreMode.replace),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (mode == null || !context.mounted) return;
    context.read<CartBloc>().add(CartRestoreRequested(cart.id, mode));
    context.go('/cart');
  }

  Future<void> _delete(BuildContext context, SavedCart cart) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Delete saved cart?'),
            content: Text(
              '${cart.name} will be permanently removed from this device.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      context.read<CartBloc>().add(CartSavedDeleted(cart.id));
    }
  }
}

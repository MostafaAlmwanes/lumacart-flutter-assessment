import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.compact = false,
    super.key,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final double iconSize = compact ? 20 : 24;
    return Semantics(
      label: 'Quantity $quantity',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: 'Decrease quantity',
              onPressed: onDecrement,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              iconSize: iconSize,
              icon: const Icon(Icons.remove),
            ),
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                '$quantity',
                key: ValueKey<int>(quantity),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Increase quantity',
              onPressed: onIncrement,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              iconSize: iconSize,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

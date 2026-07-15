import 'package:flutter/material.dart';
import 'package:lumacart/app/theme/design_tokens.dart';

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final int columns = constraints.maxWidth < 360 || textScale > 1.3 ? 1 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: columns == 1 ? 1.4 : 0.62,
          ),
          itemCount: columns == 1 ? 4 : 6,
          itemBuilder: (BuildContext context, int index) =>
              const _SkeletonCard(),
        );
      },
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final Widget card = Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _block(base, double.infinity)),
            const SizedBox(height: AppSpacing.sm),
            _block(base, 100),
            const SizedBox(height: AppSpacing.xs),
            _block(base, 140),
            const Spacer(),
            _block(base, 72),
          ],
        ),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return card;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) => Opacity(
        opacity: 0.45 + (_controller.value * 0.35),
        child: child,
      ),
      child: card,
    );
  }

  Widget _block(Color color, double width) {
    return Container(
      height: 14,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
    );
  }
}

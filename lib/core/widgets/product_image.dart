import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.imageUrl,
    required this.semanticLabel,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String imageUrl;
  final String semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final Duration fadeDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: imageUrl.isEmpty
            ? _fallback(context)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: fit,
                fadeInDuration: fadeDuration,
                fadeOutDuration: fadeDuration,
                placeholder: (BuildContext context, String url) => const Center(
                  child: SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget:
                    (BuildContext context, String url, Object error) =>
                        _fallback(context),
              ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

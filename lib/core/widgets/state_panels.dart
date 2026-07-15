import 'package:flutter/material.dart';
import 'package:lumacart/app/theme/design_tokens.dart';

class EmptyStatePanel extends StatelessWidget {
  const EmptyStatePanel({
    required this.title,
    required this.message,
    this.icon,
    this.illustration,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
          icon != null || illustration != null,
          'Provide either an icon or an illustration.',
        );

  final IconData? icon;
  final Widget? illustration;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                label: title,
                child: illustration ??
                    Icon(
                      icon,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    required this.message,
    this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStatePanel(
      illustration: Image.asset(
        'assets/generated/offline.png',
        width: 220,
        height: 165,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}

class InlineNotice extends StatelessWidget {
  const InlineNotice({
    required this.message,
    this.isError = false,
    super.key,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = isError
        ? colors.errorContainer
        : colors.secondaryContainer;
    final Color foreground = isError
        ? colors.onErrorContainer
        : colors.onSecondaryContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}

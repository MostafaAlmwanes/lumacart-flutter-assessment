import 'package:flutter/material.dart';
import 'package:lumacart/app/theme/design_tokens.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/generated/auth_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.18,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/generated/splash_logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.xl),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

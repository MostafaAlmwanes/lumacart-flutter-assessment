import 'package:flutter/material.dart';
import 'package:lumacart/app/theme/design_tokens.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'LumaCart is starting',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(
                'assets/generated/splash_logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('LumaCart', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

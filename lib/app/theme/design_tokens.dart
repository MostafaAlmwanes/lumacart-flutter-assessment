import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primary = Color(0xFF3C4CC7);
  static const Color secondary = Color(0xFF6474E7);
  static const Color accent = Color(0xFFF07A5A);
  static const Color success = Color(0xFF237A57);
  static const Color warning = Color(0xFF9A6700);
  static const Color error = Color(0xFFB3261E);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B1B21);
  static const Color textSecondary = Color(0xFF5D5E6A);
  static const Color outline = Color(0xFFD9DAE5);
}

abstract class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract class AppRadii {
  static const double small = 8;
  static const double medium = 14;
  static const double large = 20;
  static const double pill = 999;
}

abstract class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

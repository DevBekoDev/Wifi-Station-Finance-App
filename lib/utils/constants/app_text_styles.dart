import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Roboto';

  // LIGHT
  static const TextStyle headingLight = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle bodyLight = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondaryLight,
  );

  // DARK
  static const TextStyle headingDark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle bodyDark = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondaryDark,
  );
}
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:jenga/presentation/theme/theme.dart';

class ToastUtility {
  /// Show a development warning toast
  static void showDevelopmentWarning(
    BuildContext context, {
    String message = 'Settings are still under development',
  }) {
    DelightToastBar(
      builder: (context) => ToastCard(
        leading: const Text('🚧', style: TextStyle(fontSize: 24)),
        title: Text(
          message,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w600,
            color: AppColors.walnut,
          ),
        ),
        color: AppColors.amberPale,
        shadowColor: AppColors.cardShadow,
      ),
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 3),
    ).show(context);
  }

  /// Show a success toast
  static void showSuccess(BuildContext context, {required String message}) {
    DelightToastBar(
      builder: (context) => ToastCard(
        leading: const Text(
          '✓',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        title: Text(
          message,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        color: AppColors.felt,
        shadowColor: AppColors.cardShadow,
      ),
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
    ).show(context);
  }

  /// Show an error toast
  static void showError(BuildContext context, {required String message}) {
    DelightToastBar(
      builder: (context) => ToastCard(
        leading: const Text(
          '✕',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        title: Text(
          message,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        color: AppColors.coral,
        shadowColor: AppColors.cardShadow,
      ),
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 2),
    ).show(context);
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ToastType { success, error, warning, info }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remove any existing snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final config = _getConfig(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _ToastContent(
          message: message,
          icon: config.icon,
          iconColor: config.iconColor,
          bgColor: config.bgColor,
          borderColor: config.borderColor,
          textColor: config.textColor,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        padding: EdgeInsets.zero,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, type: ToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: ToastType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: ToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: ToastType.info);
  }

  static _ToastConfig _getConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFF1F8E9),
          borderColor: const Color(0xFF81C784),
          textColor: const Color(0xFF1B5E20),
        );
      case ToastType.error:
        return _ToastConfig(
          icon: Icons.error_rounded,
          iconColor: AppTheme.error,
          bgColor: const Color(0xFFFFF0EF),
          borderColor: const Color(0xFFEF9A9A),
          textColor: const Color(0xFFB71C1C),
        );
      case ToastType.warning:
        return _ToastConfig(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF57F17),
          bgColor: const Color(0xFFFFF8E1),
          borderColor: const Color(0xFFFFD54F),
          textColor: const Color(0xFFE65100),
        );
      case ToastType.info:
        return _ToastConfig(
          icon: Icons.info_rounded,
          iconColor: AppTheme.tertiary,
          bgColor: const Color(0xFFE3F2FD),
          borderColor: const Color(0xFF90CAF9),
          textColor: const Color(0xFF0D47A1),
        );
    }
  }
}

class _ToastConfig {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  _ToastConfig({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}

class _ToastContent extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _ToastContent({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 5,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Icon with subtle background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Message text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: textColor,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Close button
            GestureDetector(
              onTap: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

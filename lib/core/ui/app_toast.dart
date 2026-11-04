import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/guardian_theme.dart';

/// Root messenger so toasts can be shown from anywhere (providers,
/// interceptors) without a BuildContext.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum ToastKind { success, error, warning, info }

/// Elegant floating toasts with icon, accent bar and haptics.
class AppToast {
  AppToast._();

  static void success(String message) => show(message, kind: ToastKind.success);
  static void error(String message) => show(message, kind: ToastKind.error);
  static void warning(String message) => show(message, kind: ToastKind.warning);
  static void info(String message) => show(message, kind: ToastKind.info);

  static void show(
    String message, {
    ToastKind kind = ToastKind.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final context = messenger.context;

    final (IconData icon, Color accent) = switch (kind) {
      ToastKind.success => (Icons.check_circle_rounded, context.gm.brand),
      ToastKind.error => (Icons.error_rounded, context.gm.danger),
      ToastKind.warning => (Icons.warning_amber_rounded, context.gm.warning),
      ToastKind.info => (Icons.info_rounded, context.gm.info),
    };

    if (kind == ToastKind.error) {
      HapticFeedback.heavyImpact();
    } else if (kind == ToastKind.success) {
      HapticFeedback.lightImpact();
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          padding: EdgeInsets.zero,
          content: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
                    child: Row(
                      children: [
                        Icon(icon, color: accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
  }
}

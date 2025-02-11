import 'package:flutter/material.dart';
import '../widgets/custom_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static OverlayEntry? _currentNotification;
  static bool _isVisible = false;

  void _showOverlay(BuildContext context, Widget notification) {
    if (_isVisible) {
      _hideNotification();
    }

    _isVisible = true;
    final overlay = Overlay.of(context);
    _currentNotification = OverlayEntry(
      builder: (context) => notification,
    );

    overlay.insert(_currentNotification!);
  }

  void _hideNotification() {
    _currentNotification?.remove();
    _currentNotification = null;
    _isVisible = false;
  }

  void showNotification(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showOverlay(
      context,
      CustomNotification(
        message: message,
        type: type,
        duration: duration,
        onDismiss: _hideNotification,
      ),
    );
  }

  void showSuccess(BuildContext context, String message) {
    showNotification(context, message: message, type: NotificationType.success);
  }

  void showError(BuildContext context, String message) {
    showNotification(context, message: message, type: NotificationType.error);
  }

  void showWarning(BuildContext context, String message) {
    showNotification(context, message: message, type: NotificationType.warning);
  }

  void showInfo(BuildContext context, String message) {
    showNotification(context, message: message, type: NotificationType.info);
  }
} 
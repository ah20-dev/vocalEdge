import 'dart:async';

/// Global notification service for showing messages across the app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Stream controller for notifications
  final _notificationController = StreamController<NotificationMessage>.broadcast();

  // Stream that widgets can listen to
  Stream<NotificationMessage> get notificationStream => _notificationController.stream;

  /// Show a success notification
  void showSuccess(String message) {
    _notificationController.add(NotificationMessage(
      message: message,
      type: NotificationType.success,
    ));
  }

  /// Show an error notification
  void showError(String message) {
    _notificationController.add(NotificationMessage(
      message: message,
      type: NotificationType.error,
    ));
  }

  /// Show an info notification
  void showInfo(String message) {
    _notificationController.add(NotificationMessage(
      message: message,
      type: NotificationType.info,
    ));
  }

  /// Dispose the service
  void dispose() {
    _notificationController.close();
  }
}

/// Notification message model
class NotificationMessage {
  final String message;
  final NotificationType type;

  NotificationMessage({
    required this.message,
    required this.type,
  });
}

/// Notification types
enum NotificationType {
  success,
  error,
  info,
}



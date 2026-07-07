import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Suppress debug service errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Suppress debug service errors
    if (details.exception.toString().contains('DebugService') ||
        details.exception.toString().contains('Cannot send Null')) {
      return; // Suppress these specific errors
    }
    FlutterError.presentError(details);
  };
  
  // Initialize Supabase
  await SupabaseConfig.init();
  
  // Initialize Auth Service
  await AuthService().initialize();
  
  // Enable system status bar with edge-to-edge layout
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light, // iOS: light background = dark text
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const VocalEdgeApp());
}

class VocalEdgeApp extends StatefulWidget {
  const VocalEdgeApp({super.key});

  @override
  State<VocalEdgeApp> createState() => _VocalEdgeAppState();
}

class _VocalEdgeAppState extends State<VocalEdgeApp> with WidgetsBindingObserver {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _notificationService = NotificationService();
  StreamSubscription<NotificationMessage>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen for global notifications with proper disposal
    _notificationSubscription = _notificationService.notificationStream.listen((notification) {
      final messenger = _scaffoldMessengerKey.currentState;
      if (messenger != null && mounted) {
        // Clear any existing snackbars
        messenger.clearSnackBars();
        
        // Show new notification
        messenger.showSnackBar(
          SnackBar(
            content: Text(notification.message),
            backgroundColor: _getBackgroundColor(notification.type),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to progress page if it's a success notification
                if (notification.type == NotificationType.success) {
                  AppRouter.router.go('/progress');
                }
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.paused:
        // App went to background (e.g., user went to Settings)
        print('App backgrounded');
        break;
      case AppLifecycleState.resumed:
        // App came back to foreground
        print('App resumed');
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call, alert showing)
        print('App inactive');
        break;
      case AppLifecycleState.detached:
        // App is detached
        print('App detached');
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        print('App hidden');
        break;
    }
  }

  Color _getBackgroundColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF10B981); // Green
      case NotificationType.error:
        return const Color(0xFFEF4444); // Red
      case NotificationType.info:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );
  }
}

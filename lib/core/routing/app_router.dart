import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/practice/presentation/pages/practice_page.dart';
import '../../features/practice/presentation/pages/freestyle_practice_page.dart';
import '../../features/practice/presentation/pages/daily_lessons_page.dart';
import '../../features/practice/presentation/pages/lesson_details_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/progress/presentation/pages/session_details_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/welcome/presentation/pages/welcome_page.dart';
import '../services/auth_service.dart';

/// Helper function to create pages with iOS-style bidirectional slide transitions
/// Forward navigation: New page slides from right, old page slides to left
/// Backward navigation: Current page slides to right, previous page slides from left
Page<dynamic> _buildPageWithSlideTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // iOS-style transitions: animate BOTH the incoming and outgoing pages
      
      // Primary animation (for the page being pushed/popped)
      // Forward: slides from right (1.0, 0.0) to center (0.0, 0.0)
      // Backward: slides from center (0.0, 0.0) to right (1.0, 0.0) [automatic reverse]
      final primarySlide = Tween<Offset>(
        begin: const Offset(1.0, 0.0),  // Start from right
        end: Offset.zero,                // End at center
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ));
      
      // Secondary animation (for the page being covered/uncovered)
      // Forward: slides from center (0.0, 0.0) to left (-0.3, 0.0) [partial slide]
      // Backward: slides from left (-0.3, 0.0) to center (0.0, 0.0) [automatic reverse]
      final secondarySlide = Tween<Offset>(
        begin: Offset.zero,              // Start at center
        end: const Offset(-0.3, 0.0),    // End slightly to left (iOS-style)
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInOut,
      ));
      
      // Stack both animations: the new page slides over the old page
      return SlideTransition(
        position: secondarySlide,
        child: SlideTransition(
          position: primarySlide,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 350),
  );
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final authService = AuthService();
      final isAuthenticated = authService.isAuthenticated;
      final location = state.matchedLocation;
      
      // If authenticated and trying to access welcome/login/signup, redirect to dashboard
      if (isAuthenticated && (location == '/welcome' || location == '/login' || location == '/signup')) {
        print('AppRouter: User authenticated, redirecting to dashboard');
        return '/dashboard';
      }
      
      // No redirect needed
      return null;
    },
    routes: [
      // Welcome Flow
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const WelcomePage(),
        ),
      ),
      
      // Authentication Flow
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const SignupPage(),
        ),
      ),
      
      // Main App Flow
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const DashboardPage(),
        ),
      ),
      
      // Practice Flow
      GoRoute(
        path: '/practice',
        name: 'practice',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const PracticePage(),
        ),
      ),
      GoRoute(
        path: '/freestyle',
        name: 'freestyle',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const FreestylePracticePage(),
        ),
      ),
      GoRoute(
        path: '/lessons',
        name: 'lessons',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const DailyLessonsPage(),
        ),
      ),
      GoRoute(
        path: '/lesson-details',
        name: 'lesson-details',
        pageBuilder: (context, state) {
          final lesson = state.extra as Map<String, dynamic>;
          return _buildPageWithSlideTransition(
            context,
            state,
            LessonDetailsPage(lesson: lesson),
          );
        },
      ),
      
      // Progress Flow
      GoRoute(
        path: '/progress',
        name: 'progress',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const ProgressPage(),
        ),
      ),
      GoRoute(
        path: '/session-details',
        name: 'session-details',
        pageBuilder: (context, state) {
          final session = state.extra as Map<String, dynamic>;
          return _buildPageWithSlideTransition(
            context,
            state,
            SessionDetailsPage(session: session),
          );
        },
      ),
      
      // Settings Flow
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context,
          state,
          const SettingsPage(),
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/welcome'),
        ),
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    const SizedBox(height: 40),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF850CA3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPrimary), // PRIMARY - logo container
                      ),
                      child: const Icon(
                        Icons.mic,
                        size: 32,
                        color: Color(0xFF850CA3),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title and Description
                    const Text(
                      'Vocal Edge - AI',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D171B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enhance your speaking skills with AI-powered feedback. Sign in to get started.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4C809A),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Social Login Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement Apple Sign In
                        _handleAppleSignIn(context);
                      },
                      icon: const Icon(Icons.apple, size: 20),
                      label: const Text('Continue with Apple'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusTertiary), // TERTIARY - secondary button
                        ),
                        side: BorderSide.none,
                        backgroundColor: const Color(0xFFE7EFF3),
                        foregroundColor: const Color(0xFF0D171B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement Google Sign In
                        _handleGoogleSignIn(context);
                      },
                      icon: const Icon(Icons.email, size: 20),
                      label: const Text('Continue with Gmail'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusTertiary), // TERTIARY - secondary button
                        ),
                        side: BorderSide.none,
                        backgroundColor: const Color(0xFFE7EFF3),
                        foregroundColor: const Color(0xFF0D171B),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Terms and Privacy
              const Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4C809A),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _handleAppleSignIn(BuildContext context) {
    // TODO: Implement Apple Sign In with Supabase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign In coming soon!')),
    );
  }
  
  void _handleGoogleSignIn(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Sign in with Google
      final response = await SupabaseConfig.signInWithGoogle();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (response != null && response['user'] != null) {
        // Success - set user data in AuthService and navigate to dashboard
        if (context.mounted) {
          final isNewUser = response['isNewUser'] as bool;
          final userData = response['user'] as Map<String, dynamic>;
          
          // Set user data in global auth service
          await AuthService().setUserData(userData);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isNewUser ? 'Welcome! Account created successfully.' : 'Welcome back!'),
            ),
          );
          context.go('/dashboard');
        }
      } else if (response == null) {
        // User cancelled
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in cancelled')),
          );
        }
      } else {
        // Handle error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign In failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

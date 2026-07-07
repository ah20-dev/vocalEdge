import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // // Profile Section
            // _buildSettingsItem(
            //   context,
            //   icon: Icons.person,
            //   title: 'Profile',
            //   subtitle: 'Manage your account details',
            //   onTap: () => _navigateToProfile(context),
            // ),
            // 
            // const SizedBox(height: 16),
            // 
            // // Permissions Section
            // _buildPermissionsSection(context),
            // 
            // const SizedBox(height: 16),
            
            // Support Section
            _buildSettingsItem(
              context,
              icon: Icons.support_agent,
              title: 'Chat with us 24/7 (Coming Soon)',
              subtitle: 'Get help and support',
              onTap: () => _openSupport(context),
            ),
            
            const SizedBox(height: 16),
            
            // About Section
            _buildSettingsItem(
              context,
              icon: Icons.info,
              title: 'About',
              subtitle: 'Learn more about Vocal Edge - AI',
              onTap: () => _showAbout(context),
            ),
            
            const SizedBox(height: 16),
            
            // Logout Section
            _buildSettingsItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              isDestructive: true,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildPermissionsSection(BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.only(left: 4, bottom: 8),
  //         child: Text(
  //           'Permissions',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Theme.of(context).primaryColor,
  //           ),
  //         ),
  //       ),
  //       _buildMicrophonePermissionItem(context),
  //     ],
  //   );
  // }

  // Widget _buildMicrophonePermissionItem(BuildContext context) {
  //   return GestureDetector(
  //     onTap: () => _openAppSettings(context),
  //     child: Container(
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: Theme.of(context).cardColor,
  //         borderRadius: BorderRadius.circular(16),
  //       ),
  //       child: Row(
  //         children: [
  //           // Icon
  //           Container(
  //             width: 48,
  //             height: 48,
  //             decoration: BoxDecoration(
  //               color: const Color(0xFF850CA3).withOpacity(0.1),
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: const Icon(
  //               Icons.mic,
  //               color: Color(0xFF850CA3),
  //               size: 24,
  //             ),
  //           ),
  //           
  //           const SizedBox(width: 16),
  //           
  //           // Content
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Microphone',
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                     color: Theme.of(context).textTheme.bodyLarge?.color,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 4),
  //                 const Text(
  //                   'Manage microphone permissions',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     color: Color(0xFF4C809A),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           
  //           // Chevron Icon
  //           const Icon(
  //             Icons.chevron_right,
  //             color: Color(0xFF4C809A),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSecondary),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - settings item cards
          ),
          child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDestructive
                    ? const Color(0xFFEF4444).withOpacity(0.1)
                    : const Color(0xFF850CA3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - icon container
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF850CA3),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDestructive
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0D171B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4C809A),
                    ),
                  ),
                ],
              ),
            ),
            
            // Chevron Icon
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF4C809A),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // Future<void> _openAppSettings(BuildContext context) async {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Microphone Permissions'),
  //       content: const Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Vocal Edge needs microphone access to record your voice for AI analysis and vocal coaching.',
  //             style: TextStyle(fontSize: 16),
  //           ),
  //           SizedBox(height: 16),
  //           Text(
  //             'To manage microphone access:',
  //             style: TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           SizedBox(height: 8),
  //           Text('1. Tap "Open Settings" below'),
  //           Text('2. Find "Vocal Edge"'),
  //           Text('3. Toggle "Microphone" to ON'),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             Navigator.of(context).pop();
  //             // Open iOS Settings - UIApplicationOpenSettingsURLString
  //             final uri = Uri.parse('app-settings:');
  //             if (await canLaunchUrl(uri)) {
  //               await launchUrl(uri);
  //             }
  //           },
  //           child: const Text('Open Settings'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // void _navigateToProfile(BuildContext context) {
  //   // TODO: Navigate to profile page
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Profile page coming soon!')),
  //   );
  // }

  void _openSupport(BuildContext context) {
    // TODO: Open support chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support chat coming soon!')),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Vocal Edge - AI'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vocal Edge - AI is an AI-powered vocal coaching app that helps you improve your speaking skills through personalized feedback and guided lessons.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performLogout(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context) async {
    try {
      // Use AuthService to properly sign out
      await AuthService().signOut();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully!')),
        );
        context.go('/welcome');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout error: ${e.toString()}')),
        );
      }
    }
  }
}

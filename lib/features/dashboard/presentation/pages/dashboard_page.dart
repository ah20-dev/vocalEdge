import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  // int _selectedIndex = 0; // Hidden while bottom nav is disabled
  String _userName = 'User'; // Default name
  int _loginStreak = 0; // Default streak
  String _confidenceDisplay = 'Pending'; // Default confidence
  double _confidenceScore = 0.0; // Confidence score for progress bar (0.0 to 1.0)
  bool _isLoading = true;
  int _totalSessions = 0; // Track total sessions for tooltip
  final AuthService _authService = AuthService();
  
  // Animation controller for confidence chart
  late AnimationController _animationController;
  late Animation<double> _confidenceAnimation;


  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _confidenceAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _loadUserData();
    
    // Listen to auth service changes
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {
        _userName = _authService.userName;
        _loginStreak = _authService.loginStreak;
      });
      _loadConfidenceData();
    }
  }

  Future<void> _loadUserData() async {
    print('Dashboard: _loadUserData called.');
    
    // Use AuthService for user data
    if (_authService.isAuthenticated) {
      setState(() {
        _userName = _authService.userName;
        _loginStreak = _authService.loginStreak;
        _isLoading = false;
      });
      print('Dashboard: _userName set to: $_userName, _loginStreak set to: $_loginStreak');
      
      // Load confidence data
      await _loadConfidenceData();
    } else {
      print('Dashboard: User not authenticated');
      setState(() {
        _userName = 'User';
        _loginStreak = 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text('Vocal Edge - AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              _userName == 'User' ? 'Hello!' : 'Hello, $_userName!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D171B),
              ),
            ),
            const SizedBox(height: 24),
            
            // Progress Overview Section
            const Text(
              'Progress Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D171B),
              ),
            ),
            const SizedBox(height: 16),
            
            // Confidence Score Card (PRIMARY)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusPrimary),
              ),
              child: Column(
                children: [
                  // Circular Progress Indicator
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      children: [
                        // Background Circle
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE7EFF3),
                          ),
                        ),
                        // Progress Circle (Animated)
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: AnimatedBuilder(
                            animation: _confidenceAnimation,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _confidenceAnimation.value,
                                strokeWidth: 10,
                                backgroundColor: const Color(0xFFE7EFF3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF850CA3),
                                ),
                              );
                            },
                          ),
                        ),
                        // Center Content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusModal), // MODAL radius
                                      ),
                                      title: const Text('Confidence Score'),
                                      content: Text(
                                        _totalSessions < 10 
                                          ? 'Complete 10 sessions to unlock your confidence score. Your confidence score is calculated from your most recent 10 practice sessions.'
                                          : 'Your confidence score is calculated from your most recent 10 practice sessions, showing your average speaking confidence level.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Got it'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12), // ACCESSIBILITY: 44x44px touch target
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Confidence',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF4C809A),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.help_outline,
                                        size: 20, // Increased from 16px for better visibility
                                        color: Color(0xFF4C809A),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _confidenceDisplay,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D171B),
                                ),
                              ),
                              // Trend indicator (only show when we have data)
                              if (_totalSessions >= 10)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Last 10 sessions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF4C809A).withOpacity(0.8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Streak Badge (TERTIARY)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusTertiary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Color(0xFFF59E0B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _loginStreak == 0 
                              ? 'No streak yet' 
                              : _loginStreak == 1 
                                  ? '1-day streak'
                                  : '$_loginStreak-day streak',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D171B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Practice Modes Section
            const Text(
              'Practice Modes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D171B),
              ),
            ),
            const SizedBox(height: 16),
            
            // Practice Mode Cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildPracticeModeCard(
                    context,
                    icon: Icons.mic,
                    title: 'Practice',
                    subtitle: 'Record and get instant feedback',
                    onTap: () => context.push('/freestyle'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPracticeModeCard(
                    context,
                    icon: Icons.school,
                    title: 'Daily Lessons',
                    subtitle: 'Guided exercises to improve skills',
                    onTap: () => context.push('/lessons'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Always 0 since we only have Progress
        onTap: (index) {
          if (index == 0) {
            context.push('/progress');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: const Color(0xFF850CA3),
        unselectedItemColor: const Color(0xFF4C809A),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
  
  Widget _buildPracticeModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPrimary),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusPrimary), // PRIMARY - main practice cards
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF850CA3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - icon container
              ),
              child: Icon(
                icon,
                color: const Color(0xFF850CA3),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D171B),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4C809A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _loadConfidenceData() async {
    int totalSessions = 0; // Declare at method level for scope
    
    try {
      // Get current user ID
      String? userId;
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        userId = currentUser.id;
      } else {
        // Use AuthService for user ID
        userId = await _authService.getCurrentUserId();
      }

      if (userId != null) {
        // Get total sessions count for tooltip
        final totalSessionsResponse = await Supabase.instance.client
            .from('audio_clips')
            .select('id')
            .eq('user_id', userId);
        
        totalSessions = totalSessionsResponse.length;
        
        // Get recent sessions for this user
        final sessionsResponse = await Supabase.instance.client
            .from('audio_clips')
            .select('overall_score')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(10);

        if (sessionsResponse.length >= 10) {
          // Calculate average of overall scores
          double totalScore = 0;
          int validScores = 0;
          
          for (final session in sessionsResponse) {
            final overallScore = session['overall_score'];
            if (overallScore != null && overallScore is num) {
              totalScore += overallScore.toDouble();
              validScores++;
            }
          }
          
          if (validScores > 0) {
            final averageScore = totalScore / validScores;
            final targetScore = averageScore / 100.0; // Convert percentage to 0.0-1.0 range
            
            setState(() {
              _confidenceDisplay = '${averageScore.toStringAsFixed(0)}%';
              _confidenceScore = targetScore;
              _totalSessions = totalSessions;
              _isLoading = false;
            });
            
            // Animate the confidence chart
            _confidenceAnimation = Tween<double>(
              begin: 0.0,
              end: targetScore,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutCubic,
              ),
            );
            _animationController.forward(from: 0.0);
            
            return;
          }
        }
      }
      
      // Default to "TBD" if less than 10 sessions or no user ID
      setState(() {
        _confidenceDisplay = 'Pending';
        _confidenceScore = 0.0; // No progress bar for Pending
        _totalSessions = totalSessions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading confidence data: $e');
      setState(() {
        _confidenceDisplay = 'Pending';
        _confidenceScore = 0.0; // No progress bar for Pending
        _totalSessions = totalSessions;
        _isLoading = false;
      });
    }
  }
}

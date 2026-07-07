import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  List<Map<String, dynamic>> _recentSessions = [];
  bool _isLoading = true;
  
  // Progress stats
  int _totalSessions = 0;
  double _totalMinutes = 0;
  int _userStreak = 0;
  double _averageConfidence = 0;
  String? _currentUserId;
  
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProgressData();
    
    // Listen to auth service changes
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      // Refresh progress data when auth state changes
      _loadProgressData();
    }
  }

  Future<void> _loadProgressData() async {
    try {
      // First, get current user ID
      await _getCurrentUserId();
      
      if (_currentUserId == null) {
        print('No user ID found, loading all sessions for debugging');
        // Fallback: Load all sessions to see if there are any
        final allSessionsResponse = await Supabase.instance.client
            .from('audio_clips')
            .select('''
              id,
              user_id,
              user_filename,
              duration_sec,
              overall_score,
              created_at,
              whisper_analysis(*),
              prosody_analysis(*)
            ''')
            .order('created_at', ascending: false)
            .limit(10);
        
        print('All sessions found: ${allSessionsResponse.length}');
        final averageConfidence = _calculateAverageConfidence(allSessionsResponse);
        setState(() {
          _recentSessions = List<Map<String, dynamic>>.from(allSessionsResponse);
          _totalSessions = allSessionsResponse.length;
          _totalMinutes = _calculateTotalMinutes(allSessionsResponse);
          _userStreak = 0; // Can't get streak without user ID
          _averageConfidence = averageConfidence;
          _isLoading = false;
        });
        return;
      }

      // 1. Load recent sessions (for display)
      print('Loading recent sessions for user ID: $_currentUserId');
      final sessionsResponse = await Supabase.instance.client
          .from('audio_clips')
          .select('''
            id,
            user_id,
            user_filename,
            duration_sec,
            overall_score,
            created_at,
            whisper_analysis(*),
            prosody_analysis(*)
          ''')
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false)
          .limit(10);
      
      print('Sessions response: ${sessionsResponse.length} sessions found');
      
      // 3. Get all sessions for this user to calculate totals
      final allSessionsResponse = await Supabase.instance.client
          .from('audio_clips')
          .select('duration_sec, overall_score')
          .eq('user_id', _currentUserId!);
      
      // 2. Load user streak from AuthService
      final userStreak = _authService.loginStreak;
      
      // 3. Calculate totals
      final totalSessions = allSessionsResponse.length;
      final totalMinutes = _calculateTotalMinutes(allSessionsResponse);
      final averageConfidence = _calculateAverageConfidence(sessionsResponse);
      
      setState(() {
        _recentSessions = List<Map<String, dynamic>>.from(sessionsResponse);
        _totalSessions = totalSessions;
        _totalMinutes = totalMinutes;
        _userStreak = userStreak;
        _averageConfidence = averageConfidence;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentUserId() async {
    try {
      print('Getting current user ID...');
      
      // Use AuthService for user ID
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        _currentUserId = userId;
        print('Got user ID from AuthService: $_currentUserId');
      } else {
        print('No user ID found from AuthService');
        _currentUserId = null;
      }
    } catch (e) {
      print('Error getting current user ID: $e');
      _currentUserId = null;
    }
  }

  double _calculateTotalMinutes(List<dynamic> sessions) {
    double totalMinutes = 0;
    for (final session in sessions) {
      // Try to get duration from prosody_analysis first, then fallback to audio_clips
      final prosodyData = session['prosody_analysis'];
      if (prosodyData is List && prosodyData.isNotEmpty) {
        final duration = prosodyData[0]['duration_sec'] ?? 0;
        totalMinutes += duration / 60; // Convert seconds to minutes
      } else if (session['duration_sec'] != null) {
        totalMinutes += (session['duration_sec'] as num) / 60;
      }
    }
    return totalMinutes;
  }

  double _calculateAverageConfidence(List<dynamic> recentSessions) {
    if (recentSessions.isEmpty) return 0;
    
    double totalScore = 0;
    int validScores = 0;
    
    for (final session in recentSessions) {
      final overallScore = session['overall_score'];
      if (overallScore != null && overallScore is num) {
        totalScore += overallScore.toDouble();
        validScores++;
      }
    }
    
    return validScores > 0 ? totalScore / validScores : 0;
  }

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
        title: const Text('Progress'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Sessions Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: const Text(
              'Recent Sessions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D171B),
              ),
            ),
          ),
          const SizedBox(height: 10),
          
          // Sessions List (Scrollable)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recentSessions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'No sessions yet. Start practicing to see your progress!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4C809A),
                          ),
                        ),
                      )
                    : Scrollbar(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _recentSessions.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _buildSessionCard(
                                context,
                                session: _recentSessions[index],
                                onTap: () => _viewSessionDetails(context, _recentSessions[index]),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          
          // This Week's Progress (Fixed at bottom)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This Week\'s Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D171B),
                  ),
                ),
                const SizedBox(height: 4),
                
                // 2x2 Grid Layout
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Sessions',
                        value: '$_totalSessions',
                        icon: Icons.play_circle_outline,
                        color: const Color(0xFF850CA3),
                        tooltip: 'Total number of practice sessions you\'ve completed this week.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Minutes',
                        value: '${_totalMinutes.toStringAsFixed(0)}',
                        icon: Icons.timer,
                        color: const Color(0xFF10B981),
                        tooltip: 'Total minutes of practice time recorded this week.',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Streak',
                        value: '$_userStreak',
                        icon: Icons.local_fire_department,
                        color: const Color(0xFFF59E0B),
                        tooltip: 'Number of consecutive days you\'ve practiced. Keep it going!',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Confidence',
                        value: _recentSessions.length >= 10 
                            ? '${_averageConfidence.toStringAsFixed(0)}%'
                            : 'Pending',
                        icon: Icons.trending_up,
                        color: const Color(0xFF3B82F6),
                        tooltip: _recentSessions.length >= 10
                            ? 'Your average confidence score calculated from your last 10 sessions.'
                            : 'Complete 10 sessions to unlock your confidence score.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context, {
    required Map<String, dynamic> session,
    required VoidCallback onTap,
  }) {
    try {
      final createdAt = DateTime.parse(session['created_at']);
      final localTime = createdAt.isUtc ? createdAt.toLocal() : createdAt;
      final dateStr = '${localTime.month}/${localTime.day}/${localTime.year}';
      
      // Convert to 12-hour format with AM/PM
      final hour = localTime.hour;
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final period = hour >= 12 ? 'PM' : 'AM';
      final timeStr = '${hour12}:${localTime.minute.toString().padLeft(2, '0')} $period';
      
      // Determine session type and icon based on user_filename
      final userFilename = session['user_filename'] ?? '';
      final isFreestyle = userFilename.contains('freestyle');
      final title = isFreestyle ? 'Freestyle Practice' : 'Daily Practice';
      final icon = isFreestyle ? Icons.mic : Icons.school;
      
      // Get overall score from audio_clips table (pre-calculated)
      final score = (session['overall_score'] as num?)?.round() ?? 0;
      
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSecondary),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - session history cards
            ),
          child: Row(
            children: [
              // Session Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF850CA3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - icon container
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF850CA3),
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Session Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D171B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr at $timeStr',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4C809A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Score: $score',
                          style: TextStyle(
                            fontSize: 12,
                            color: score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
    } catch (e) {
      print('Error building session card: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 16),
            Text('Error loading session data'),
          ],
        ),
      );
    }
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? tooltip,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - stats cards
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: tooltip != null ? () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusModal), // MODAL radius
                  ),
                  title: Text(title),
                  content: Text(tooltip),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            } : null,
            child: Container(
              padding: const EdgeInsets.all(8), // ACCESSIBILITY: Expanded touch target
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4C809A),
                    ),
                  ),
                  if (tooltip != null) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.help_outline,
                      size: 18, // Increased from 14px for better visibility
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewSessionDetails(BuildContext context, Map<String, dynamic> session) {
    // Navigate to session details page with session data
    context.push('/session-details', extra: session);
  }
}
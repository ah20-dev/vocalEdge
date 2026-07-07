import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class DailyLessonsPage extends StatefulWidget {
  const DailyLessonsPage({super.key});

  @override
  State<DailyLessonsPage> createState() => _DailyLessonsPageState();
}

class _DailyLessonsPageState extends State<DailyLessonsPage> {
  List<Map<String, dynamic>> _lessons = [];
  bool _isLoading = true;
  String? _currentUserId;

  // User lesson data
  int? _userLessonDay;      // Current lesson day (1-19)
  DateTime? _userLastLogin; // Last login date
  DateTime? _userCreatedAt; // Account creation date

  final AuthService _authService = AuthService();

  @override
  void initState() {
    print('DEBUG: DailyLessonsPage initState() called');
    super.initState();
    _loadLessons();

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
      _loadLessons();
    }
  }

  /// Get current user email from AuthService
  Future<String?> _getCurrentUserEmail() async {
    print('DEBUG: _getCurrentUserEmail() called');
    
    // Use AuthService as single source of truth
    if (_authService.isAuthenticated && _authService.userEmail.isNotEmpty) {
      print('DEBUG: Found email from AuthService: ${_authService.userEmail}');
      return _authService.userEmail;
    }
    
    print('DEBUG: No email found - user not authenticated');
    return null;
  }

  /// Load user lesson data and initialize lessonday if missing
  Future<void> _loadUserLessonData(String email) async {
    try {
      print('DEBUG: Loading user lesson data for email: $email');
      
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('id, lessonday, created_at, last_login')
          .eq('email', email)
          .maybeSingle();

      if (userResponse == null) {
        print('DEBUG: No user found for email: $email');
        return;
      }

      print('DEBUG: User response from database: $userResponse');
      print('DEBUG: Raw lessonday from database: ${userResponse['lessonday']}');

      // Handle NULL lessonday (should not happen with Bug 1 fix, but keep as safety)
      int lessonDay = userResponse['lessonday'];
      if (lessonDay == null || lessonDay <= 0) {
        lessonDay = 1;
        print('DEBUG: Initializing lessonday to 1 for user (was NULL or <= 0)');
        await Supabase.instance.client
            .from('users')
            .update({'lessonday': 1})
            .eq('email', email);
      }

      print('DEBUG: Final lessonDay value: $lessonDay');

      setState(() {
        _currentUserId = userResponse['id'].toString();
        _userLessonDay = lessonDay;
        _userCreatedAt = DateTime.parse(userResponse['created_at']);
        _userLastLogin = userResponse['last_login'] != null
            ? DateTime.parse(userResponse['last_login'])
            : null;
      });

      print('DEBUG: Set state - _userLessonDay: $_userLessonDay, _userCreatedAt: $_userCreatedAt');

      // No longer need to check/advance here - AuthService handles it on app start
    } catch (e) {
      print('Error loading user lesson data: $e');
    }
  }

  /// Fetch all lessons and user data
  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);

    try {
      final email = await _getCurrentUserEmail();
      if (email != null) await _loadUserLessonData(email);

      final response = await Supabase.instance.client
          .from('lesson_plans')
          .select('*')
          .order('id', ascending: true);

      setState(() {
        _lessons = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      print('Loaded ${_lessons.length} lessons');
    } catch (e) {
      print('Error loading lessons: $e');
      setState(() => _isLoading = false);
    }
  }

  // NOTE: Lesson advancement now happens in AuthService.initialize()
  // This method is kept for reference but no longer called
  // If needed in future, uncomment and call from _loadUserLessonData()

  /// Get 0-based lesson index for _lessons list
  int _getUserLessonIndex() {
    return ((_userLessonDay ?? 1) - 1).clamp(0, 18);
  }

  String _getLessonDate(int lessonNumber) {
    // Use same logic as _checkAndUpdateLessonDay() for consistency
    if (_userLessonDay == null) return '';

    // Show "Today" for the current lesson day
    return lessonNumber == _userLessonDay ? 'Today' : '';
  }

  void _startLesson(BuildContext context, Map<String, dynamic> lesson) {
    context.push('/lesson-details', extra: lesson);
  }

  /// Build all lesson cards from lesson 1 to current lessonday
  /// Shows Today's lesson first, then Available Lessons in reverse order
  List<Widget> _buildAllLessonsUpToCurrent() {
    final currentLessonIndex = _getUserLessonIndex();
    final widgets = <Widget>[];
    
    // FIRST: Show "Today" section with current lesson
    widgets.add(_buildSectionHeader('Today'));
    widgets.add(const SizedBox(height: 8));
    
    if (currentLessonIndex < _lessons.length) {
      widgets.add(
        _buildLessonCard(
          context: context,
          lesson: _lessons[currentLessonIndex],
          lessonNumber: currentLessonIndex + 1,
          isCompleted: false,
          isAvailable: true,
        ),
      );
    }
    
    // SECOND: Show "Available Lessons" section with past lessons in REVERSE order
    if (currentLessonIndex > 0) {
      widgets.add(const SizedBox(height: 24));
      widgets.add(_buildSectionHeader('Available Lessons'));
      widgets.add(const SizedBox(height: 8));
      
      // Loop through lessons from currentLessonIndex-1 down to 0 (REVERSE)
      for (int i = currentLessonIndex - 1; i >= 0; i--) {
        final lessonNumber = i + 1; // Lesson numbers are 1-based
        
        widgets.add(
          _buildLessonCard(
            context: context,
            lesson: _lessons[i],
            lessonNumber: lessonNumber,
            isCompleted: false, // All lessons available, none marked complete
            isAvailable: true,
          ),
        );
        
        // Add spacing between cards (except after last one)
        if (i > 0) {
          widgets.add(const SizedBox(height: 12));
        }
      }
    }
    
    return widgets;
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4C809A),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildLessonCard({
    required BuildContext context,
    required Map<String, dynamic> lesson,
    required int lessonNumber,
    required bool isCompleted,
    required bool isAvailable,
  }) {
    final lessonName = lesson['Name'] ?? 'Untitled Lesson';
    final category = lesson['Category'] ?? 'General';
    final header = lesson['Header'] ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAvailable ? () => _startLesson(context, lesson) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSecondary),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - lesson cards
          ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFE7EFF3)
                    : const Color(0xFF850CA3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - icon container
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.play_arrow,
                color: isCompleted
                    ? const Color(0xFF4C809A)
                    : const Color(0xFF850CA3),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lessonName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? const Color(0xFF4C809A) : const Color(0xFF0D171B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF4C809A)),
                  ),
                  if (header.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      header,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4C809A),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
            else if (isAvailable)
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF850CA3), size: 20),
          ],
        ),
        ),
      ),
    );
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
        title: const Text('Daily Lessons'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_lessons.isEmpty)
                    const Center(
                      child: Text(
                        'No lessons available',
                        style: TextStyle(color: Color(0xFF4C809A)),
                      ),
                    )
                  else if (_getUserLessonIndex() >= _lessons.length)
                    const Center(
                      child: Text(
                        'All lessons completed!',
                        style: TextStyle(color: Color(0xFF4C809A)),
                      ),
                    )
                  else
                    // Show all lessons from 1 to current lessonday
                    ..._buildAllLessonsUpToCurrent(),
                ],
              ),
            ),
    );
  }
}

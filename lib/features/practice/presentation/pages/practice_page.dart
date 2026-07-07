import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  String _selectedLevel = 'beginner';

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
        title: const Text('Practice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Skill Level Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE7EFF3),
                borderRadius: BorderRadius.circular(AppTheme.radiusTertiary), // TERTIARY - tab selector
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLevelButton('beginner', 'Beginner'),
                  ),
                  Expanded(
                    child: _buildLevelButton('intermediate', 'Intermediate'),
                  ),
                  Expanded(
                    child: _buildLevelButton('professional', 'Professional'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Lessons List
            Expanded(
              child: _buildLessonsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(String level, String label) {
    final isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = level;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusTertiary - 2), // TERTIARY - tab item (slightly smaller)
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF850CA3) : const Color(0xFF4C809A),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsList() {
    final lessons = _getLessonsForLevel(_selectedLevel);
    
    return ListView.builder(
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return _buildLessonCard(lesson);
      },
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to lesson details
            context.push('/lesson-details', extra: lesson);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusSecondary),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - lesson cards
            ),
      child: Row(
        children: [
          // Lesson Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF850CA3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - icon container
            ),
            child: Icon(
              lesson['icon'],
              color: const Color(0xFF850CA3),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Lesson Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D171B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson['description'],
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
      ),
    );
  }

  List<Map<String, dynamic>> _getLessonsForLevel(String level) {
    switch (level) {
      case 'beginner':
        return [
          {
            'title': 'Lesson 1: Pace and Pauses',
            'description': 'Learn to control your speaking speed.',
            'icon': Icons.filter_1,
          },
          {
            'title': 'Lesson 2: Basic Tone Variation',
            'description': 'Introduce emotion into your voice.',
            'icon': Icons.filter_2,
          },
          {
            'title': 'Lesson 3: Introduction to Pitch',
            'description': 'Understand the fundamentals of pitch.',
            'icon': Icons.filter_3,
          },
        ];
      case 'intermediate':
        return [
          {
            'title': 'Lesson 4: Advanced Pitch Control',
            'description': 'Mastering vocal range and modulation.',
            'icon': Icons.filter_4,
          },
          {
            'title': 'Lesson 5: Rhythmic Speaking',
            'description': 'Using cadence to engage listeners.',
            'icon': Icons.filter_5,
          },
        ];
      case 'professional':
        return [
          {
            'title': 'Lesson 6: Eloquence and Articulation',
            'description': 'Perfecting your delivery for any audience.',
            'icon': Icons.filter_6,
          },
          {
            'title': 'Lesson 7: Persuasive Speaking',
            'description': 'Techniques to influence and inspire.',
            'icon': Icons.filter_7,
          },
        ];
      default:
        return [];
    }
  }
}

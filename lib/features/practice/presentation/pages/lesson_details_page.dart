import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class LessonDetailsPage extends StatelessWidget {
  final Map<String, dynamic> lesson;
  
  const LessonDetailsPage({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    final lessonName = lesson['Name'] ?? 'Untitled Lesson';
    final category = lesson['Category'] ?? 'General';
    final header = lesson['Header'] ?? '';
    final details = lesson['Details'] ?? '';
    
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
        title: const Text('Lesson Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF850CA3), Color(0xFF4C809A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusPrimary), // PRIMARY - hero card
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lessonName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  if (header.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      header,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Lesson Details
            if (details.isNotEmpty) ...[
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D171B),
                ),
              ),
              const SizedBox(height: 16),
              _buildEngagingContent(details),
            ] else ...[
              // Default content if no details provided
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D171B),
                ),
              ),
              const SizedBox(height: 16),
              _buildEngagingContent('This lesson will help you improve your vocal skills. Follow the instructions carefully and practice regularly for best results.'),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagingContent(String content) {
    // Split content by lines and create engaging bullet points
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmedLine = line.trim();
        
        // Check if line already starts with a bullet point
        if (trimmedLine.startsWith('-') || trimmedLine.startsWith('•')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF850CA3),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    trimmedLine.startsWith('-') 
                        ? trimmedLine.substring(1).trim()
                        : trimmedLine.substring(1).trim(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF0D171B),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Regular paragraph
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              trimmedLine,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF0D171B),
                height: 1.6,
              ),
            ),
          );
        }
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class SessionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> session;
  
  const SessionDetailsPage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Print session data structure
    print('Session data keys: ${session.keys.toList()}');
    print('Whisper analysis: ${session['whisper_analysis']}');
    print('Prosody analysis: ${session['prosody_analysis']}');
    
    // Handle array vs object structure for joined data
    final whisperAnalysis = session['whisper_analysis'];
    Map<String, dynamic> whisperData = {};
    if (whisperAnalysis is List && whisperAnalysis.isNotEmpty) {
      whisperData = whisperAnalysis[0] as Map<String, dynamic>? ?? {};
    } else if (whisperAnalysis is Map) {
      whisperData = whisperAnalysis as Map<String, dynamic>? ?? {};
    }
    
    final prosodyAnalysis = session['prosody_analysis'];
    Map<String, dynamic> prosodyData = {};
    if (prosodyAnalysis is List && prosodyAnalysis.isNotEmpty) {
      prosodyData = prosodyAnalysis[0] as Map<String, dynamic>? ?? {};
    } else if (prosodyAnalysis is Map) {
      prosodyData = prosodyAnalysis as Map<String, dynamic>? ?? {};
    }
    final prosodyScores = {
      'pitch_score': prosodyData['pitch_score'] ?? 0,
      'energy_score': prosodyData['energy_score'] ?? 0,
      'resonance_score': prosodyData['resonance_score'] ?? 0,
      'combined_prosody_score': prosodyData['combined_prosody_score'] ?? 0,
    };
    
    final createdAt = DateTime.parse(session['created_at']);
    final localTime = createdAt.isUtc ? createdAt.toLocal() : createdAt;
    
    // Convert to 12-hour format with AM/PM
    final hour = localTime.hour;
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    final dateStr = '${localTime.month}/${localTime.day}/${localTime.year} at ${hour12}:${localTime.minute.toString().padLeft(2, '0')} $period';
  
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
        title: const Text('Session Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusPrimary), // PRIMARY - main session card
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF850CA3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - icon container
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Color(0xFF850CA3),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Freestyle Practice',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D171B),
                              ),
                            ),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4C809A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Overall Score
            _buildScoreCard(
              context,
              title: 'Overall Score',
              score: (session['overall_score'] as num?)?.round() ?? 0,
              subtitle: 'Average of speech analysis and voice quality scores',
              tooltip: 'Comprehensive score combining speech analysis (pace, filler words, pauses) and voice quality (pitch, energy, resonance). Higher scores indicate more effective communication.',
            ),
            
            const SizedBox(height: 16),
            
            // Speech Analysis Section
            const Text(
              'Speech Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D171B),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Pace',
                    value: '${whisperData['pace_wpm']?.toStringAsFixed(1) ?? '0'} WPM',
                    icon: Icons.speed,
                    color: const Color(0xFF10B981),
                    tooltip: 'Words per minute. Ideal range is 120-160 WPM for clear communication.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Filler Words',
                    value: '${whisperData['filler_count'] ?? 0}',
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFFF59E0B),
                    tooltip: 'Count of filler words like "um", "uh", "like". Lower is better for confident speech.',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Pauses',
                    value: '${whisperData['pause_count'] ?? 0}',
                    icon: Icons.pause_circle_outline,
                    color: const Color(0xFF3B82F6),
                    tooltip: 'Number of pauses longer than 0.5 seconds. Strategic pauses can enhance speech.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Long Pauses',
                    value: '${whisperData['long_pauses'] ?? 0}',
                    icon: Icons.timer_off,
                    color: const Color(0xFFEF4444),
                    tooltip: 'Pauses longer than 1.5 seconds. Too many can indicate uncertainty or lack of preparation.',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Prosody Analysis Section
            const Text(
              'Voice Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D171B),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Pitch Score',
                    value: '${prosodyScores['pitch_score'] ?? 0}',
                    icon: Icons.trending_up,
                    color: const Color(0xFF8B5CF6),
                    tooltip: 'Measures vocal pitch variation. Higher scores indicate more dynamic and engaging speech patterns.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Energy Score',
                    value: '${prosodyScores['energy_score'] ?? 0}',
                    icon: Icons.flash_on,
                    color: const Color(0xFFF59E0B),
                    tooltip: 'Measures vocal energy and volume. Higher scores indicate more confident and engaging delivery.',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Resonance Score',
                    value: '${prosodyScores['resonance_score'] ?? 0}',
                    icon: Icons.volume_up,
                    color: const Color(0xFF10B981),
                    tooltip: 'Measures vocal resonance and clarity. Higher scores indicate clearer, more professional speech quality.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Combined Score',
                    value: '${prosodyScores['combined_prosody_score'] ?? 0}',
                    icon: Icons.star,
                    color: const Color(0xFF850CA3),
                    tooltip: 'Overall vocal quality score combining pitch, energy, and resonance. Higher scores indicate better overall delivery.',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Transcript Section
            const Text(
              'Transcript',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D171B),
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - metrics grid
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Text(
                whisperData['transcript'] ?? 'No transcript available',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0D171B),
                  height: 1.5,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Technical Details
            const Text(
              'Technical Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D171B),
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - analysis cards
              ),
              child: Column(
                children: [
                  _buildDetailRow('Duration', '${session['duration_sec']?.toStringAsFixed(1) ?? '0'} seconds'),
                  _buildDetailRow('Pitch Mean', '${prosodyData['pitch_mean_hz']?.toStringAsFixed(1) ?? '0'} Hz'),
                  _buildDetailRow('Pitch Variation', '${prosodyData['pitch_variation_hz']?.toStringAsFixed(1) ?? '0'} Hz'),
                  _buildDetailRow('Energy Level', '${prosodyData['energy_db']?.toStringAsFixed(1) ?? '0'} dB'),
                  _buildDetailRow('Resonance Variation', '${prosodyData['resonance_variation']?.toStringAsFixed(1) ?? '0'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(
    BuildContext context, {
    required String title,
    required int score,
    required String subtitle,
    String? tooltip,
  }) {
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusPrimary), // PRIMARY - score cards
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30), // Circle - keep as-is
            ),
            child: Icon(
              Icons.star,
              color: scoreColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0D171B),
                          ),
                        ),
                        if (tooltip != null) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.help_outline,
                            size: 20, // Increased from 16px for better visibility
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4C809A),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
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
        borderRadius: BorderRadius.circular(AppTheme.radiusSecondary), // SECONDARY - metric cards
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
                      fontSize: 12,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4C809A),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0D171B),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/config/supabase_config.dart';

class FreestylePracticePage extends StatefulWidget {
  const FreestylePracticePage({super.key});

  @override
  State<FreestylePracticePage> createState() => _FreestylePracticePageState();
}

class _FreestylePracticePageState extends State<FreestylePracticePage> {
  final TextEditingController _textController = TextEditingController();
  final AudioService _audioService = AudioService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  
  bool _isRecording = false;
  bool _isAnalyzing = false;
  String? _currentUserId;
  Map<String, dynamic>? _analysisResults;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  Timer? _displayTimer;
  Duration _recordingDuration = Duration.zero;
  
  // Teleprompter state

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _textController.addListener(() {
      setState(() {}); // Update word count
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _recordingTimer?.cancel();
    _displayTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      print('Loading current user...');
      
      // Use AuthService for user data
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        setState(() {
          _currentUserId = userId;
        });
        print('User ID set to: $_currentUserId');
        print('User: ${_authService.userName} (${_authService.userEmail})');
      } else {
        print('No user found - user needs to sign in');
        setState(() {
          _currentUserId = null;
        });
        print('User ID set to: null - user needs to authenticate');
      }
    } catch (e) {
      print('Error loading current user: $e');
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => context.pop(),
        ),
        title: const Text('Freestyle'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        onVerticalDragDown: (_) => FocusScope.of(context).unfocus(),
        child: Column(
        children: [
          // Recording Section
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Record Button
                  GestureDetector(
                    onTap: _isAnalyzing ? null : _toggleRecording,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: _isAnalyzing 
                            ? Colors.grey 
                            : (_isRecording ? Colors.red : const Color(0xFF850CA3)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isAnalyzing 
                                ? Colors.grey 
                                : (_isRecording ? Colors.red : const Color(0xFF850CA3)))
                                .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: _isAnalyzing
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                          : Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 48,
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Recording Status
                  Text(
                    _isAnalyzing 
                        ? 'Analyzing your speech...' 
                        : (_isRecording ? 'Recording... Tap to stop' : 'Tap to start recording'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4C809A),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Duration warning
                  const Text(
                    'Audio Recordings must be between 1 and 5 minutes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (_isRecording) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D171B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Teleprompter Section
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notepad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D171B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF850CA3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.5),
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          expands: true,
                          maxLength: 1000,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF0D171B),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter your practice text here...',
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                            counterText: '', // Hide character counter
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Word count display
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_getWordCount()} / 1000 words',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check microphone permission first
      final hasPermission = await _audioService.checkMicrophonePermission();
      
      if (!hasPermission) {
        // Show native iOS alert to prompt user to enable permission
        await _audioService.showPermissionAlert();
        return;
      }
      
      final success = await _audioService.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
          _recordingStartTime = DateTime.now();
          _recordingDuration = Duration.zero;
        });
        
        // Start timer to auto-stop at 5 minutes
        _recordingTimer = Timer(const Duration(minutes: 5), () {
          if (_isRecording) {
            _autoStopRecording();
          }
        });
        
        // Start display timer to update every second
        _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_isRecording && _recordingStartTime != null) {
            setState(() {
              _recordingDuration = DateTime.now().difference(_recordingStartTime!);
            });
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording started!')),
        );
      } else {
        // If recording failed, check permission again and show alert
        final stillHasPermission = await _audioService.checkMicrophonePermission();
        if (!stillHasPermission) {
          await _audioService.showPermissionAlert();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start recording. Please try again.')),
          );
        }
      }
    } catch (e) {
      print('Error in _startRecording: $e');
      // Check if error is permission-related
      final hasPermission = await _audioService.checkMicrophonePermission();
      if (!hasPermission) {
        await _audioService.showPermissionAlert();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      // Cancel the timers if user manually stops
      _recordingTimer?.cancel();
      _displayTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _isAnalyzing = true;
      });

      // Check recording duration
      if (_recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        final durationInSeconds = duration.inSeconds;
        
        if (durationInSeconds < 60) {
          setState(() {
            _isAnalyzing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording too short! Please record for at least 1 minute.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      await _processRecording();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing recording: $e')),
      );
    }
  }

  Future<void> _autoStopRecording() async {
    try {
      // Cancel the display timer
      _displayTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _isAnalyzing = true;
      });

      // Show message that recording was capped at 5 minutes
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording capped at 5 minutes. Analyzing...'),
          backgroundColor: Colors.orange,
        ),
      );

      await _processRecording();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing recording: $e')),
      );
    }
  }

  Future<void> _processRecording() async {
    try {
      print('Starting to process recording...');
      
      // Stop recording and save file
      final audioPath = await _audioService.stopRecording();
      print('Audio path received: $audioPath');
      print('Current user ID: $_currentUserId');
      
      if (audioPath == null || _currentUserId == null) {
        print('Failed to process recording - audioPath: $audioPath, userId: $_currentUserId');
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save recording.')),
        );
        return;
      }
      
      // Upload in background
      final filename = 'freestyle_practice_${_formatDateTimeForFilename(DateTime.now())}';
      _uploadRecordingInBackground(audioPath, _currentUserId!, filename);
      
    } catch (e) {
      print('Error in _processRecording: $e');
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing recording: $e')),
      );
    }
  }
  
  /// Upload recording in background - continues even if user navigates away
  void _uploadRecordingInBackground(String audioPath, String userId, String filename) async {
    try {
      print('Starting background audio analysis...');
      
      // Analyze the audio
      final results = await _audioService.analyzeAudio(
        audioPath: audioPath,
        userId: userId,
        userFilename: filename,
      );
      print('Analysis results: $results');
      
      // Show global notification on success
      if (results != null) {
        _notificationService.showSuccess(
          '🎉 Your speech analysis is ready! Tap to view your progress.',
        );
      }

      // Only update UI if still mounted
      if (!mounted) {
        print('Widget disposed, but notification sent globally');
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _analysisResults = results;
      });

      if (results != null) {
        print('Showing analysis results dialog');
        _showAnalysisResults(results);
      } else {
        print('Analysis returned null results');
        _notificationService.showError('Analysis failed. Please try again.');
      }
    } catch (e) {
      print('Error in background upload: $e');
      
      // Show global error notification
      _notificationService.showError('Upload failed. Please try again.');
      
      // Only update UI if still mounted
      if (!mounted) return;
      
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _showAnalysisResults(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Speech Analysis Results'),
        content: const Text(
          'Your scores are ready!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/progress');
            },
            child: const Text('View Progress'),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  String _formatDateTimeForFilename(DateTime dateTime) {
    // Format: MMDDYYHHMM (Month Day Year Hour Minute)
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final month = twoDigits(dateTime.month);
    final day = twoDigits(dateTime.day);
    final year = twoDigits(dateTime.year % 100); // Last 2 digits of year
    final hour = twoDigits(dateTime.hour);
    final minute = twoDigits(dateTime.minute);
    return '$month$day$year$hour$minute';
  }

  int _getWordCount() {
    final text = _textController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }
}

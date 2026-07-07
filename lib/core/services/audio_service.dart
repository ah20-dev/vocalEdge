import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final Record _recorder = Record();
  final Dio _dio = Dio();
  final String _backendUrl = AppConfig.backendUrl;
  static const platform = MethodChannel('com.vocaledge.app/permissions');
  
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  
  /// Check if microphone permission is granted
  Future<bool> checkMicrophonePermission() async {
    if (!Platform.isIOS) return true;
    
    try {
      final bool hasPermission = await platform.invokeMethod('checkMicrophonePermission');
      return hasPermission;
    } catch (e) {
      print('Error checking microphone permission: $e');
      return false;
    }
  }
  
  /// Show native iOS alert to prompt user to enable microphone in Settings
  Future<void> showPermissionAlert() async {
    if (!Platform.isIOS) return;
    
    try {
      await platform.invokeMethod('showMicrophonePermissionAlert');
    } catch (e) {
      print('Error showing permission alert: $e');
    }
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Handle path differently for web vs mobile
      if (kIsWeb) {
        // For web, use a simple filename
        _currentRecordingPath = 'web_recording_${const Uuid().v4()}.m4a';
      } else {
        // For mobile platforms, get temporary directory
        final tempDir = await getTemporaryDirectory();
        final fileName = 'recording_${const Uuid().v4()}.m4a';
        _currentRecordingPath = '${tempDir.path}/$fileName';
      }

      // Start recording
      await _recorder.start(
        path: _currentRecordingPath!,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        return null;
      }

      final recordingPath = await _recorder.stop();
      _isRecording = false;

      // Use the path returned by the recorder, or fall back to our stored path
      final finalPath = recordingPath ?? _currentRecordingPath;
      _currentRecordingPath = null;

      return finalPath;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Analyze audio using the backend API
  Future<Map<String, dynamic>?> analyzeAudio({
    required String audioPath,
    required String userId,
    required String userFilename,
  }) async {
    try {
      print('AudioService: Starting audio analysis');
      print('AudioService: audioPath = $audioPath');
      print('AudioService: userId = $userId');
      print('AudioService: userFilename = $userFilename');
      print('AudioService: kIsWeb = $kIsWeb');
      
      // For web, we need to handle the file differently
      if (kIsWeb) {
        print('AudioService: Processing for web platform');
        
        // On web, we need to convert the blob URL to bytes
        try {
          print('AudioService: Fetching blob data from: $audioPath');
          
          // Convert blob URL to bytes
          final response = await _dio.get(audioPath, options: Options(responseType: ResponseType.bytes));
          final audioBytes = response.data as List<int>;
          
          print('AudioService: Got ${audioBytes.length} bytes from blob');
          
          // Create FormData with bytes instead of file
          final formData = FormData.fromMap({
            'file': MultipartFile.fromBytes(
              audioBytes,
              filename: userFilename,
              contentType: MediaType('audio', 'wav'),
            ),
            'user_id': userId,
            'user_filename': userFilename,
          });

          print('AudioService: Making API request to $_backendUrl/analyze-audio');
          // Make API request
          final apiResponse = await _dio.post(
            '$_backendUrl/analyze-audio',
            data: formData,
            options: Options(
              headers: {
                'Content-Type': 'multipart/form-data',
              },
              sendTimeout: const Duration(minutes: 2), // 2 minutes for analysis
              receiveTimeout: const Duration(minutes: 2),
            ),
          );

          print('AudioService: API response status: ${apiResponse.statusCode}');
          if (apiResponse.statusCode == 200) {
            print('AudioService: Analysis successful');
            return apiResponse.data as Map<String, dynamic>;
          } else {
            print('AudioService: API request failed with status: ${apiResponse.statusCode}');
            print('AudioService: Response body: ${apiResponse.data}');
            throw Exception('API request failed with status: ${apiResponse.statusCode}');
          }
        } catch (e) {
          print('AudioService: Error processing web audio: $e');
          if (e is DioException && e.response != null) {
            print('AudioService: Error response status: ${e.response?.statusCode}');
            print('AudioService: Error response data: ${e.response?.data}');
          }
          throw e;
        }
      } else {
        // Mobile platform handling
        try {
          final file = File(audioPath);
          if (!await file.exists()) {
            throw Exception('Audio file does not exist');
          }

          // Create FormData for multipart upload
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(
              audioPath,
              filename: userFilename,
            ),
            'user_id': userId,
            'user_filename': userFilename,
          });

          // Make API request
          final response = await _dio.post(
            '$_backendUrl/analyze-audio',
            data: formData,
            options: Options(
              headers: {
                'Content-Type': 'multipart/form-data',
              },
              sendTimeout: const Duration(minutes: 2), // 2 minutes for analysis
              receiveTimeout: const Duration(minutes: 2),
            ),
          );

          if (response.statusCode == 200) {
            return response.data as Map<String, dynamic>;
          } else {
            print('AudioService: API request failed with status: ${response.statusCode}');
            print('AudioService: Response body: ${response.data}');
            throw Exception('API request failed with status: ${response.statusCode}');
          }
        } catch (e) {
          print('AudioService: Error processing mobile audio: $e');
          if (e is DioException && e.response != null) {
            print('AudioService: Error response status: ${e.response?.statusCode}');
            print('AudioService: Error response data: ${e.response?.data}');
          }
          throw e;
        }
      }
    } catch (e) {
      print('Error analyzing audio: $e');
      return null;
    }
  }

  /// Get audio file duration
  Future<Duration?> getAudioDuration(String audioPath) async {
    try {
      if (kIsWeb) {
        // On web, we can't easily get file duration without additional packages
        // For now, return null and implement proper duration calculation later
        return null;
      } else {
        final file = File(audioPath);
        if (!await file.exists()) {
          return null;
        }

        // Use record package to get amplitude (not duration)
        final amplitude = await _recorder.getAmplitude();
        // Note: This gives amplitude, not duration. For duration, we'd need to track start/stop times
        // For now, return null and implement proper duration calculation later
        return null;
      }
    } catch (e) {
      print('Error getting audio duration: $e');
      return null;
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      if (_currentRecordingPath != null && !kIsWeb) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      } else if (kIsWeb) {
        // On web, we don't need to clean up files manually
        _currentRecordingPath = null;
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await cleanupTempFiles();
    await _recorder.dispose();
  }
}


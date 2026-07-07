import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // SharedPreferences key
  static const String _userDataKey = 'user_data';

  // User data
  Map<String, dynamic>? _userData;
  String? _currentUserId;
  bool _isAuthenticated = false;

  // Getters
  Map<String, dynamic>? get userData => _userData;
  String? get currentUserId => _currentUserId;
  bool get isAuthenticated => _isAuthenticated;
  String get userName => _userData?['username'] ?? 'User';
  String get userEmail => _userData?['email'] ?? '';
  int get loginStreak => _userData?['login_streak'] ?? 0;
  int get lessonDay => _userData?['lessonday'] ?? 1;

  // Initialize authentication state
  Future<void> initialize() async {
    try {
      // FIRST: Check SharedPreferences (disk storage)
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString(_userDataKey);
      
      if (storedData != null) {
        final userData = jsonDecode(storedData) as Map<String, dynamic>;
        _userData = userData;
        _currentUserId = userData['id'].toString();
        _isAuthenticated = true;
        notifyListeners();
        print('AuthService: ✅ Restored from storage - ${userData['username']} (${userData['email']})');
        
        // Check and advance lesson if it's a new day (also updates last_login)
        await _checkAndAdvanceLessonIfNeeded(userData['email']);
        
        return; // Already authenticated!
      }

      // If no stored data, try Supabase auth
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await _loadUserDataFromSupabase(currentUser.id);
        return;
      }

      // Fallback to Google Sign-In
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signInSilently();
      if (googleUser != null) {
        await _loadUserDataFromGoogle(googleUser.email);
      }
    } catch (e) {
      print('AuthService: Error initializing: $e');
    }
  }

  // Set user data (called after successful login)
  Future<void> setUserData(Map<String, dynamic> userData) async {
    _userData = userData;
    _currentUserId = userData['id'].toString();
    _isAuthenticated = true;
    
    // Save to SharedPreferences (disk storage)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(userData));
      print('AuthService: ✅ User data saved to disk - ${userData['username']} (${userData['email']})');
    } catch (e) {
      print('AuthService: ⚠️ Failed to save to storage: $e');
    }
    
    notifyListeners();
  }

  // Load user data from Supabase auth
  Future<void> _loadUserDataFromSupabase(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      setUserData(response);
    } catch (e) {
      print('AuthService: Error loading from Supabase: $e');
    }
  }

  // Load user data from Google Sign-In
  Future<void> _loadUserDataFromGoogle(String email) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('email', email)
          .single();
      
      await setUserData(response);
      
      // Check and advance lesson if needed (for Google Sign-In flow)
      await _checkAndAdvanceLessonIfNeeded(email);
    } catch (e) {
      print('AuthService: Error loading from Google: $e');
    }
  }

  // Get current user ID (with fallback)
  Future<String?> getCurrentUserId() async {
    if (_currentUserId != null) {
      return _currentUserId;
    }

    // Try to reload from Google Sign-In
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signInSilently();
      if (googleUser != null) {
        await _loadUserDataFromGoogle(googleUser.email);
        return _currentUserId;
      }
    } catch (e) {
      print('AuthService: Error getting user ID: $e');
    }

    return null;
  }

  // Update user data (for lesson progression, etc.)
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    if (_currentUserId == null) return;

    try {
      await Supabase.instance.client
          .from('users')
          .update(updates)
          .eq('id', _currentUserId!);

      // Update local data
      if (_userData != null) {
        _userData!.addAll(updates);
        notifyListeners();
      }
    } catch (e) {
      print('AuthService: Error updating user data: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await GoogleSignIn().signOut();
      
      // Clear SharedPreferences (disk storage)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      
      _userData = null;
      _currentUserId = null;
      _isAuthenticated = false;
      notifyListeners();
      
      print('AuthService: ✅ User signed out and storage cleared');
    } catch (e) {
      print('AuthService: Error signing out: $e');
    }
  }

  // Check if user needs to authenticate
  bool needsAuthentication() {
    return !_isAuthenticated || _currentUserId == null;
  }

  // Check and advance lesson if it's a new day (also updates last_login)
  Future<void> _checkAndAdvanceLessonIfNeeded(String email) async {
    try {
      print('AuthService: 🔍 Checking lesson advancement for: $email');
      
      // Get user's current state from database
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('lessonday, last_login')
          .eq('email', email)
          .maybeSingle();

      if (userResponse == null) {
        print('AuthService: ⚠️ No user found in DB');
        return;
      }

      print('AuthService: 📊 DB state: lessonday=${userResponse['lessonday']}, last_login=${userResponse['last_login']}');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final lastLogin = userResponse['last_login'] != null
          ? DateTime.parse(userResponse['last_login'])
          : null;
      
      if (lastLogin != null) {
        final lastLoginDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
        final daysSinceLastLogin = today.difference(lastLoginDay).inDays;
        
        print('AuthService: 📅 Today: $today, Last Login: $lastLoginDay, Days Diff: $daysSinceLastLogin');
        
        // Only update if it's been at least 1 day
        if (daysSinceLastLogin >= 1) {
          int currentLesson = userResponse['lessonday'] ?? 1;
          int newLesson = currentLesson < 19 ? currentLesson + 1 : currentLesson;
          
          // Update BOTH lessonday AND last_login together
          await Supabase.instance.client
              .from('users')
              .update({
                'lessonday': newLesson,
                'last_login': now.toIso8601String(),
              })
              .eq('email', email);
          
          // Update local userData to reflect new lesson
          if (_userData != null) {
            _userData!['lessonday'] = newLesson;
            _userData!['last_login'] = now.toIso8601String();
            
            // Update SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_userDataKey, jsonEncode(_userData));
          }
          
          print('AuthService: ✅ Advanced to lesson $newLesson and updated last_login');
        } else {
          print('AuthService: ⏸️ Same day, no lesson advancement (daysSince: $daysSinceLastLogin)');
        }
      } else {
        // No last_login recorded, set it now (shouldn't happen with our fixes)
        await Supabase.instance.client
            .from('users')
            .update({'last_login': now.toIso8601String()})
            .eq('email', email);
        
        print('AuthService: ✅ Initialized last_login');
      }
    } catch (e) {
      print('AuthService: ⚠️ Failed to check/advance lesson: $e');
    }
  }
}

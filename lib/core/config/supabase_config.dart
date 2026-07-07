import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Google Sign-In configuration (Web client ID)
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  // Google Sign-In instance (minimal scopes - just email)
  // On iOS, don't specify clientId to use the one from GoogleService-Info.plist
  // On web, use the web client ID
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? googleClientId : null,
    scopes: ['email'], // Only request email, not full profile
  );
  
  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  
  // Google Sign-In with custom users table and streak tracking
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Sign in with Google (minimal scopes - just email)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check if user already exists in custom users table
      final existingUser = await client
          .from('users')
          .select()
          .eq('email', googleUser.email)
          .maybeSingle();
      
      if (existingUser != null) {
        // User exists - calculate and update streak
        final lastLogin = existingUser['last_login'] != null 
            ? DateTime.parse(existingUser['last_login'])
            : null;
        
        int newStreak = existingUser['login_streak'] ?? 0;
        
        if (lastLogin != null) {
          final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
          final daysDifference = today.difference(lastLoginDate).inDays;
          
          if (daysDifference == 1) {
            // Consecutive day - increment streak
            newStreak += 1;
          } else if (daysDifference > 1) {
            // Missed days - reset streak
            newStreak = 1;
          }
          // If daysDifference == 0, same day login, keep current streak
        } else {
          // First login after creation
          newStreak = 1;
        }
        
        // Update ONLY streak here
        // last_login and lessonday will be updated by AuthService
        final updatedUser = await client
            .from('users')
            .update({
              'login_streak': newStreak,
            })
            .eq('email', googleUser.email)
            .select()
            .single();
        
        return {
          'user': updatedUser,
          'isNewUser': false,
        };
      } else {
        // Create new user in custom users table
        final username = googleUser.displayName ?? googleUser.email.split('@')[0];
        
        final newUser = await client
            .from('users')
            .insert({
              'username': username,
              'email': googleUser.email,
              'last_login': now.toIso8601String(),
              'login_streak': 1, // First login = streak of 1
              'lessonday': 1, // Start at lesson 1
            })
            .select()
            .single();
        
        return {
          'user': newUser,
          'isNewUser': true,
        };
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }
  
  // Sign out from both Google and Supabase
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await client.auth.signOut();
  }
  
  // Get current user
  static User? get currentUser => client.auth.currentUser;
  
  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  // Check if user is signed in with Google
  static Future<bool> isSignedInWithGoogle() async {
    return await _googleSignIn.isSignedIn();
  }
}

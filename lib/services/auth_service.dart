// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart'; // Import your AppUser model

class AuthResult {
  final bool success;
  final String? role;
  final String? error;
  final User? user;
  final bool needsEmailConfirmation;

  AuthResult({
    required this.success,
    this.role,
    this.error,
    this.user,
    this.needsEmailConfirmation = false,
  });
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  AppUser? _currentAppUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Get current Supabase user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current AppUser
  AppUser? get currentAppUser => _currentAppUser;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Initialize the service - call this after sign in
  Future<void> initializeUser() async {
    final user = currentUser;
    if (user != null) {
      await _loadUserProfile(user.id);
    } else {
      _currentAppUser = null;
    }
  }

  // Load user profile from database
// Load user profile from database
Future<void> _loadUserProfile(String authId) async {
  try {
    debugPrint('🔍 === LOADING USER PROFILE ===');
    debugPrint('🔍 AuthId: $authId');
    
    final userProfile = await _supabase
        .from('Users')
        .select()
        .eq('AuthId', authId)
        .single();

    debugPrint('✅ Raw user profile data: $userProfile');
    debugPrint('🔍 Keys in response: ${userProfile.keys.toList()}');
    
    // Check if UsersId exists (with different casing variations)
    debugPrint('🔍 UsersId variations:');
    debugPrint('   - usersid: ${userProfile['usersid']}');
    debugPrint('   - UsersId: ${userProfile['UsersId']}');
    debugPrint('   - UsersID: ${userProfile['UsersID']}');
    debugPrint('   - USERSID: ${userProfile['USERSID']}');
    
    _currentAppUser = AppUser.fromJson(userProfile);
    
    debugPrint('✅ AppUser created successfully');
    debugPrint('✅ AppUser.usersId: ${_currentAppUser?.usersId}');
    debugPrint('✅ AppUser.email: ${_currentAppUser?.email}');
    debugPrint('✅ AppUser.fullName: ${_currentAppUser?.fullName}');
    debugPrint('🔍 === USER PROFILE LOADED ===');
  } catch (e, stackTrace) {
    debugPrint('⛔ === ERROR LOADING USER PROFILE ===');
    debugPrint('⛔ Error: $e');
    debugPrint('⛔ Stack trace: $stackTrace');
    _currentAppUser = null;
  }
}

  // Updated signUp method
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? organizationCode,
  }) async {
    try {
      // Step 1: Sign up with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return AuthResult(
          success: false,
          error: 'Failed to create auth account',
        );
      }

      final user = authResponse.user!;

      // Step 2: Check if email confirmation is required
      if (authResponse.session == null) {
        // Email confirmation is enabled
        try {
          await _createUserProfile(
            user: user,
            email: email,
            fullName: fullName,
            role: role,
            phone: phone,
            organizationCode: organizationCode,
          );
        } catch (e) {
          debugPrint('⚠️ User profile will be created after email confirmation');
        }

        return AuthResult(
          success: true,
          needsEmailConfirmation: true,
          user: user,
          error: 'Please check your email to confirm your account',
        );
      }

      // Step 3: Create user profile (email confirmation is disabled)
      await _createUserProfile(
        user: user,
        email: email,
        fullName: fullName,
        role: role,
        phone: phone,
        organizationCode: organizationCode,
      );

      // Load the user profile after signup
      await _loadUserProfile(user.id);

      return AuthResult(
        success: true,
        role: role,
        user: user,
      );
    } on AuthException catch (e) {
      debugPrint('⛔ Auth error during sign-up: ${e.message}');
      return AuthResult(
        success: false,
        error: e.message,
      );
    } on PostgrestException catch (e) {
      debugPrint('⛔ Database error during sign-up: ${e.message}');
      return AuthResult(
        success: false,
        error: 'Database error: ${e.message}',
      );
    } catch (e) {
      debugPrint('⛔ Unexpected error during sign-up: $e');
      return AuthResult(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Helper method to create user profile
  Future<void> _createUserProfile({
    required User user,
    required String email,
    required String fullName,
    required String role,
    String? phone,
    String? organizationCode,
  }) async {
    // Find organization/group by code if provided
    int? organizationId;
    int? userGroupId;

    if (organizationCode != null && organizationCode.isNotEmpty) {
      final groupResponse = await _supabase
          .from('UserGroup')
          .select('UserGroupId, OrganizationId')
          .eq('GroupCode', organizationCode)
          .maybeSingle();

      if (groupResponse != null) {
        userGroupId = groupResponse['UserGroupId'] as int?;
        organizationId = groupResponse['OrganizationId'] as int?;
      }
    }

    // Insert user profile into Users table
    final userProfile = {
      'AuthId': user.id,
      'Email': email,
      'FullName': fullName,
      'Role': _capitalizeRole(role),
      'PhoneNumber': phone,
      'OrganizationId': organizationId,
      'UserGroupId': userGroupId,
      'LastUpdateUser': email,
      'UserCreated': email,
    };

    await _supabase.from('Users').insert(userProfile);
  }

  // Sign In
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return AuthResult(
          success: false,
          error: 'Invalid credentials',
        );
      }

      // Check if user has confirmed their email
      if (authResponse.session == null) {
        return AuthResult(
          success: false,
          needsEmailConfirmation: true,
          error: 'Please confirm your email before signing in. Check your inbox for the confirmation link.',
        );
      }

      // Load user profile
      await _loadUserProfile(authResponse.user!.id);

      // Fetch user role from Users table for verification
      final userProfile = await _supabase
          .from('Users')
          .select('Role')
          .eq('AuthId', authResponse.user!.id)
          .maybeSingle();

      if (userProfile == null) {
        return AuthResult(
          success: false,
          error: 'User profile not found. Please contact support.',
        );
      }

      final role = (userProfile['Role'] as String).toLowerCase();

      return AuthResult(
        success: true,
        role: role,
        user: authResponse.user,
      );
    } on AuthException catch (e) {
      debugPrint('⛔ Auth error during sign-in: ${e.message}');
      
      // Provide user-friendly error messages
      String errorMessage = e.message;
      if (e.message.contains('Email not confirmed')) {
        errorMessage = 'Please confirm your email before signing in. Check your inbox for the confirmation link.';
      } else if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password';
      }
      
      return AuthResult(
        success: false,
        error: errorMessage,
        needsEmailConfirmation: e.message.contains('Email not confirmed'),
      );
    } on PostgrestException catch (e) {
      debugPrint('⛔ Database error during sign-in: ${e.message}');
      return AuthResult(
        success: false,
        error: 'Could not fetch user profile',
      );
    } catch (e) {
      debugPrint('⛔ Unexpected error during sign-in: $e');
      return AuthResult(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Resend confirmation email
  Future<bool> resendConfirmationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return true;
    } catch (e) {
      debugPrint('⛔ Error resending confirmation email: $e');
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentAppUser = null;
    } catch (e) {
      debugPrint('⛔ Error during sign-out: $e');
      rethrow;
    }
  }

  // Get current user (Supabase User)
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Get current user role
  Future<String?> getCurrentUserRole() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final userProfile = await _supabase
          .from('Users')
          .select('Role')
          .eq('AuthId', user.id)
          .single();

      return (userProfile['Role'] as String).toLowerCase();
    } catch (e) {
      debugPrint('⛔ Error fetching user role: $e');
      return null;
    }
  }

  // Get user role (alias for backward compatibility)
  Future<String?> getUserRole() async {
    return getCurrentUserRole();
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  // Helper function to capitalize role
  String _capitalizeRole(String role) {
    if (role.isEmpty) return role;
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  // Get user profile as Map
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final profile = await _supabase
          .from('Users')
          .select()
          .eq('AuthId', user.id)
          .single();

      return profile;
    } catch (e) {
      debugPrint('⛔ Error fetching user profile: $e');
      return null;
    }
  }

  // Get full user profile with organization and group details
  Future<Map<String, dynamic>?> getFullUserProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final profile = await _supabase
          .from('Users')
          .select('''
            *,
            Organization:OrganizationId (
              OrganizationName,
              OrganizationType,
              City,
              Country
            ),
            UserGroup:UserGroupId (
              GroupName,
              GroupCode,
              GroupType
            )
          ''')
          .eq('AuthId', user.id)
          .single();

      return profile;
    } catch (e) {
      debugPrint('⛔ Error fetching full user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final user = getCurrentUser();
      if (user == null) return false;

      // Add LastUpdateUser and LastUpdateDate
      updates['LastUpdateUser'] = user.email ?? 'unknown';
      updates['LastUpdateDate'] = DateTime.now().toIso8601String();

      await _supabase
          .from('Users')
          .update(updates)
          .eq('AuthId', user.id);

      // Reload the user profile
      await _loadUserProfile(user.id);

      return true;
    } catch (e) {
      debugPrint('⛔ Error updating user profile: $e');
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } catch (e) {
      debugPrint('⛔ Error changing password: $e');
      return false;
    }
  }

  // Send password reset email
  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      debugPrint('⛔ Error sending password reset email: $e');
      return false;
    }
  }

  // Verify if organization code exists
  Future<Map<String, dynamic>?> verifyOrganizationCode(String code) async {
    try {
      final groupResponse = await _supabase
          .from('UserGroup')
          .select('''
            UserGroupId,
            GroupName,
            GroupType,
            Organization:OrganizationId (
              OrganizationName,
              OrganizationType
            )
          ''')
          .eq('GroupCode', code)
          .maybeSingle();

      return groupResponse;
    } catch (e) {
      debugPrint('⛔ Error verifying organization code: $e');
      return null;
    }
  }

  // Fetch user profile by auth ID (useful for other services)
  Future<AppUser?> fetchUserProfile(String authId) async {
    try {
      final response = await _supabase
          .from('Users')
          .select()
          .eq('AuthId', authId)
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // Refresh current user data
  Future<void> refreshUser() async {
    final user = currentUser;
    if (user != null) {
      await _loadUserProfile(user.id);
    }
  }

// Get current user's database ID
int? getCurrentUserId() {
  return _currentAppUser?.usersId;
}

}
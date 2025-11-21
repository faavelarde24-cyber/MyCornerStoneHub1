// lib/pages/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_providers.dart';
import '../../utils/role_redirect.dart';
import 'login_page.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _setupAuthListener();
  }

  // Check initial authentication state
  Future<void> _checkAuthState() async {
    try {
      final authService = ref.read(authServiceProvider);
      final session = authService.currentSession;
      
      if (session != null) {
        // User is logged in, get their role
        final role = await authService.getCurrentUserRole();
        
        if (mounted) {
          setState(() {
            _userRole = role;
            _isLoading = false;
          });
        }
      } else {
        // No active session
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Listen to auth state changes
  void _setupAuthListener() {
    final authService = ref.read(authServiceProvider);
    authService.authStateChanges.listen((AuthState data) async {
      final session = data.session;
      
      if (session != null) {
        // User logged in
        final role = await authService.getCurrentUserRole();
        
        if (mounted) {
          setState(() {
            _userRole = role;
          });
        }
      } else {
        // User logged out
        if (mounted) {
          setState(() {
            _userRole = null;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
          ),
        ),
      );
    }

    // If user has a role, redirect to their dashboard
    if (_userRole != null) {
      return RoleRedirect.getDashboardForRole(_userRole);
    }

    // Otherwise, show login page
    return const LoginPage();
  }
}
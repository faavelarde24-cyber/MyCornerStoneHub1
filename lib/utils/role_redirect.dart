// lib/utils/role_redirect.dart
import 'package:flutter/material.dart';
import '../pages/dashboard/teacher_dashboard.dart';
import '../pages/dashboard/student_dashboard.dart';
import '../pages/dashboard/principal_dashboard.dart'; 
import '../pages/auth/login_page.dart';

/// Handles routing users to the correct dashboard based on their role
class RoleRedirect {
  /// Returns the appropriate dashboard widget for the given role
  /// 
  /// Supported roles:
  /// - 'teacher' -> ModernTeacherDashboard
  /// - 'student' -> StudentDashboard
  /// - 'principal' -> PrincipalDashboard
  /// - null or unknown -> LoginPage
  static Widget getDashboardForRole(String? role) {
    if (role == null) {
      return const LoginPage();
    }

    switch (role.toLowerCase().trim()) {
      case 'teacher':
        return const ModernTeacherDashboard();
      
      case 'student':
        return const StudentDashboard();
      
      case 'principal':
        return const PrincipalDashboard();
      
      default:
        // If role is not recognized, return to login
        return const LoginPage();
    }
  }

  /// Returns the title for the dashboard based on role
  static String getDashboardTitle(String? role) {
    if (role == null) {
      return 'CornerStone Hub';
    }

    switch (role.toLowerCase().trim()) {
      case 'teacher':
        return 'BookStudio - Teacher';
      
      case 'student':
        return 'Student Dashboard';
      
      case 'principal':
        return 'Principal Dashboard';
      
      default:
        return 'CornerStone Hub';
    }
  }

  /// Validates if the role is supported
  static bool isValidRole(String? role) {
    if (role == null) return false;
    
    const validRoles = ['teacher', 'student', 'principal'];
    return validRoles.contains(role.toLowerCase().trim());
  }

  /// Gets the list of all valid roles
  static List<String> getValidRoles() {
    return ['teacher', 'student', 'principal'];
  }
}
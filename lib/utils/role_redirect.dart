// lib/utils/role_redirect.dart
import 'package:flutter/material.dart';
import '../pages/dashboard/book_dashboard_page.dart';
import '../pages/dashboard/teacher_dashboard.dart';
import '../pages/dashboard/student_dashboard.dart';
import '../pages/dashboard/principal_dashboard.dart'; 
import '../pages/auth/login_page.dart';

/// Handles routing users to the correct dashboard based on their role
class RoleRedirect {
  /// Returns the Book Dashboard as the default landing page after login
  /// All users (teacher, student, principal) land here first
  static Widget getDashboardForRole(String? role) {
    if (role == null) {
      return const LoginPage();
    }

    // Everyone goes to Book Dashboard first (regardless of role)
    return const BookDashboardPage();
  }

  /// Returns the role-specific dashboard (called from drawer menu)
  /// 
  /// Supported roles:
  /// - 'teacher' -> ModernTeacherDashboard
  /// - 'student' -> StudentDashboard
  /// - 'principal' -> PrincipalDashboard
  /// - null or unknown -> BookDashboardPage (fallback)
  static Widget getRoleSpecificDashboard(String? role) {
    if (role == null) {
      return const BookDashboardPage();
    }

    switch (role.toLowerCase().trim()) {
      case 'teacher':
        return const ModernTeacherDashboard();
      
      case 'student':
        return const StudentDashboard();
      
      case 'principal':
        return const PrincipalDashboard();
      
      default:
        // If role is not recognized, return to Book Dashboard
        return const BookDashboardPage();
    }
  }

  /// Returns the title for the dashboard based on role
  static String getDashboardTitle(String? role) {
    if (role == null) {
      return 'My Books';
    }

    switch (role.toLowerCase().trim()) {
      case 'teacher':
        return 'BookStudio - Teacher';
      
      case 'student':
        return 'Student Dashboard';
      
      case 'principal':
        return 'Principal Dashboard';
      
      default:
        return 'My Books';
    }
  }

  /// Returns the display name for the role-specific dashboard
  static String getRoleDashboardName(String? role) {
    if (role == null) {
      return 'Dashboard';
    }

    switch (role.toLowerCase().trim()) {
      case 'teacher':
        return 'Teacher Dashboard';
      
      case 'student':
        return 'Student Dashboard';
      
      case 'principal':
        return 'Principal Dashboard';
      
      default:
        return 'Dashboard';
    }
  }

  /// Returns the icon for the role-specific dashboard
  static IconData getRoleIcon(String? role) {
    if (role == null) {
      return Icons.dashboard;
    }

    switch (role.toLowerCase().trim()) {
      case 'teacher':
        return Icons.menu_book;
      
      case 'student':
        return Icons.people;
      
      case 'principal':
        return Icons.school;
      
      default:
        return Icons.dashboard;
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
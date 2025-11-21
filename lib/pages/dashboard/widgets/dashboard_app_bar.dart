// lib/pages/dashboard/widgets/dashboard_app_bar.dart
import 'package:flutter/material.dart';
import '../../../app_theme.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRoleDashboardTap;
  final VoidCallback onNewBookTap;
  final VoidCallback? onThemeToggle;
  final VoidCallback onProfileTap;
  final int bookCount;
  final String? userRole;

  const DashboardAppBar({
    super.key,
    required this.onRoleDashboardTap,
    required this.onNewBookTap,
    this.onThemeToggle,
    required this.onProfileTap,
    required this.bookCount,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              /// Hamburger Menu
                IconButton(
                  icon: Icon(_getRoleIcon(), size: 28),
                  color: AppTheme.darkerText,
                  onPressed: onRoleDashboardTap,
                  tooltip: _getRoleTooltip(),
                ),
              
              const SizedBox(width: 16),
              
              // Title and Book Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'My Books',
                          style: AppTheme.headline.copyWith(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppTheme.darkText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$bookCount ${bookCount == 1 ? 'book' : 'books'}',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.lightText,
                      ),
                    ),
                  ],
                ),
              ),
              
              // New Book Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24), // Yellow
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withValues(alpha:0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onNewBookTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            color: AppTheme.darkerText,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'New Book',
                            style: AppTheme.title.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Theme Toggle (if provided)
              if (onThemeToggle != null) ...[
                IconButton(
                  icon: const Icon(Icons.palette_outlined, size: 26),
                  color: AppTheme.darkerText,
                  onPressed: onThemeToggle,
                  tooltip: 'Change Theme',
                ),
                const SizedBox(width: 8),
              ],
              
              const SizedBox(width: 8),
              
        // User Avatar (opens drawer)
        Tooltip(
          message: 'Profile Settings',  // ✅ Add tooltip like the palette icon
          child: MouseRegion(
            cursor: SystemMouseCursors.click,  // ✅ Change cursor on hover
            child: GestureDetector(
              onTap: onProfileTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),  // ✅ Smooth animation
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue[400]!,
                      Colors.purple[400]!,
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: AppTheme.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
            ],
          ),
        ),
      ),
    );
  }





// Helper method to get role-specific icon
  IconData _getRoleIcon() {
    if (userRole == null) return Icons.dashboard;
    
    switch (userRole!.toLowerCase()) {
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

  // Helper method to get role-specific tooltip
  String _getRoleTooltip() {
    if (userRole == null) return 'Dashboard';
    
    switch (userRole!.toLowerCase()) {
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

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
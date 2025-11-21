// lib/pages/dashboard/widgets/dashboard_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_theme.dart';
import '../../../providers/auth_providers.dart';
import '../../../main.dart'; 
import '../../../providers/book_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../models/app_theme_mode.dart';
import '../../about_us_page.dart';
import '../../library/widgets/create_library_dialog.dart';
import '../../library/widgets/libraries_list_dialog.dart';
import '../../book/widgets/books_list_dialog.dart';
import '../../../utils/role_redirect.dart';

class DashboardDrawer extends ConsumerStatefulWidget {
  final AppThemeMode themeMode;
  final Function(AppThemeMode) onThemeChanged;

  const DashboardDrawer({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  ConsumerState<DashboardDrawer> createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends ConsumerState<DashboardDrawer> {
  bool get _isDarkMode => widget.themeMode == AppThemeMode.dark || widget.themeMode == AppThemeMode.gradient;

  Color get _drawerBg {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return AppTheme.white;
      case AppThemeMode.dark:
        return AppTheme.dark_grey;
      case AppThemeMode.gradient:
        return AppTheme.nearlyBlack;
    }
  }

  Color get _textColor {
    return _isDarkMode ? AppTheme.white : AppTheme.darkerText;
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);
    final languageService = ref.watch(languageServiceProvider);

    return Drawer(
      backgroundColor: _drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[400]!,
                    Colors.purple[400]!,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.blue[400],
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      // Theme Toggle
                      IconButton(
                        icon: Icon(
                          widget.themeMode == AppThemeMode.light 
                              ? Icons.light_mode          
                              : widget.themeMode == AppThemeMode.dark 
                                  ? Icons.dark_mode      
                                  : Icons.gradient,
                          color: AppTheme.white,
                        ),
                        onPressed: _toggleTheme,
                        tooltip: 'Toggle Theme',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    languageService.translate('welcome'),
                    style: AppTheme.headline.copyWith(
                      color: AppTheme.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authService.currentUser?.email ?? 'User',
                    style: AppTheme.subtitle.copyWith(
                      color: AppTheme.white.withValues(alpha:0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerSection(
                    title: languageService.translate('books'),
                    textColor: _textColor,
                  ),
                  
                  // ✅ MODIFIED: Current page - My Books Dashboard
                  _DrawerItem(
                    icon: Icons.auto_stories,
                    title: 'My Books Dashboard',
                    textColor: _textColor,
                    iconColor: const Color(0xFF6C5CE7), // Highlight as active
                    onTap: () {
                      Navigator.pop(context);
                      // Already on book dashboard
                    },
                  ),

                  // ✅ NEW: Role-Specific Dashboard
                  FutureBuilder<String?>(
                    future: authService.getCurrentUserRole(),
                    builder: (context, snapshot) {
                      // Show loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          leading: const Icon(Icons.hourglass_empty, color: Colors.grey),
                          title: Text(
                            'Loading Dashboard...',
                            style: AppTheme.body1.copyWith(
                              color: _textColor.withValues(alpha: 0.5),
                            ),
                          ),
                          enabled: false,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        );
                      }

                      // Show role dashboard once loaded
                      final role = snapshot.data;
                      return _DrawerItem(
                        icon: RoleRedirect.getRoleIcon(role),
                        title: RoleRedirect.getRoleDashboardName(role),
                        textColor: _textColor,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToRoleDashboard();
                        },
                      );
                    },
                  ),
                  
                  _DrawerItem(
                    icon: Icons.book_outlined,
                    title: languageService.translate('your_books'),
                    textColor: _textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showBooksList();
                    },
                  ),
                  
                  _DrawerItem(
                    icon: Icons.add_circle_outline,
                    title: languageService.translate('create_new'),
                    textColor: _textColor,
                    iconColor: const Color(0xFF6C5CE7),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to book creator
                    },
                  ),
                  
                  const Divider(height: 24),
                  
                  _DrawerSection(
                    title: 'Libraries & Classes',
                    textColor: _textColor,
                  ),
                  
                  _DrawerItem(
                    icon: Icons.library_books_outlined,
                    title: 'My Libraries',
                    textColor: _textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showLibrariesList();
                    },
                  ),
                  
                  _DrawerItem(
                    icon: Icons.add_box_outlined,
                    title: 'Create Library',
                    textColor: _textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showCreateLibraryDialog();
                    },
                  ),
                  
                  _DrawerItem(
                    icon: Icons.login,
                    title: 'Join Library',
                    textColor: _textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showJoinLibraryDialog();
                    },
                  ),
                  
                  const Divider(height: 24),
                  
                  _DrawerSection(
                    title: 'Tools & Features',
                    textColor: _textColor,
                  ),
                  
                  _DrawerItem(
                    icon: Icons.people_outline,
                    title: 'Collaborators',
                    textColor: _textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Collaborators');
                    },
                  ),
                  
                  _DrawerItem(
                    icon: Icons.folder_outlined,
                    title: 'Templates',
                    textColor: _textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Templates');
                    },
                  ),
                  
                  _DrawerItem(
                    icon: Icons.analytics_outlined,
                    title: 'Analytics',
                    textColor: _textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Analytics');
                    },
                  ),
                  
                  const Divider(height: 24),
                  
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: languageService.translate('settings'),
                    textColor: _textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(languageService.translate('settings'));
                    },
                  ),
                  
                  _DrawerItem(
                    icon: Icons.info_outline,
                    title: languageService.translate('about_us'),
                    textColor: _textColor,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AboutUsPage(isDarkMode: _isDarkMode),
                        ),
                      );
                    },
                  ),
                  
                  _DrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    textColor: _textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Help & Support');
                    },
                  ),
                ],
              ),
            ),
            
            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: _DrawerItem(
                icon: Icons.logout,
                title: languageService.translate('logout'),
                iconColor: Colors.red[400],
                textColor: Colors.red[400]!,
                onTap: () async {
                  Navigator.pop(context);
                  await _handleLogout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTheme() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        widget.onThemeChanged(AppThemeMode.dark);
        break;
      case AppThemeMode.dark:
        widget.onThemeChanged(AppThemeMode.gradient);
        break;
      case AppThemeMode.gradient:
        widget.onThemeChanged(AppThemeMode.light);
        break;
    }
  }

  void _showBooksList() {
    showDialog(
      context: context,
      builder: (context) => BooksListDialog(
        themeMode: widget.themeMode,
        isDarkMode: _isDarkMode,
      ),
    );
  }

  void _showLibrariesList() {
    showDialog(
      context: context,
      builder: (context) => LibrariesListDialog(
        themeMode: widget.themeMode,
        isDarkMode: _isDarkMode,
      ),
    );
  }

  void _showCreateLibraryDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateLibraryDialog(),
    );
  }

  void _showJoinLibraryDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Join Library feature - Coming Soon!'),
        backgroundColor: const Color(0xFF6C5CE7),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // ✅ NEW METHOD: Navigate to role-specific dashboard
  Future<void> _navigateToRoleDashboard() async {
    final authService = ref.read(authServiceProvider);
    final role = await authService.getCurrentUserRole();
    
    if (!mounted) return;

    
    if (role == null || !RoleRedirect.isValidRole(role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to determine your role'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _isDarkMode ? AppTheme.grey : AppTheme.nearlyBlack,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleRedirect.getRoleSpecificDashboard(role),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      final authService = ref.read(authServiceProvider);
      
      // Invalidate ALL providers BEFORE signing out
      ref.invalidate(userBooksProvider);
      ref.invalidate(userLibrariesProvider);
      ref.invalidate(joinedLibrariesProvider);
      ref.invalidate(currentBookIdProvider);
      ref.invalidate(currentPageIndexProvider);
      ref.invalidate(bookPagesProvider);
      
      await authService.signOut();
      if (!mounted) return;
      
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error logging out')),
        );
      }
    }
  }

void _showComingSoon(String feature) {
  final languageService = ref.read(languageServiceProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature - ${languageService.translate('coming_soon')}'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _isDarkMode ? AppTheme.grey : AppTheme.nearlyBlack,
    ),
  );
}
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final Color textColor;

  const _DrawerSection({
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTheme.caption.copyWith(
          color: textColor.withValues(alpha:0.6),
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color textColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? textColor,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.body1.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      hoverColor: textColor.withValues(alpha:0.05),
    );
  }
}
// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'package:cornerstone_hub/models/app_theme_mode.dart';
import 'package:cornerstone_hub/pages/feedback_page.dart';

class AppDrawer extends StatelessWidget {
  final AuthService authService;
  final LanguageService languageService;
  final bool isDarkMode;
  final AppThemeMode themeMode;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final void Function(AppThemeMode) onThemeChanged;
  final VoidCallback onLogout;
  final void Function(String, LanguageService) onShowComingSoon;
  final VoidCallback onCloseDrawer;
  
  // Library-related callbacks
  final VoidCallback? onShowLibraries;
  final VoidCallback? onCreateLibrary;
  final VoidCallback? onJoinLibrary;
  final VoidCallback? onShowBooks;
  final VoidCallback? onCreateBook; 
  final bool isStudent;

  const AppDrawer({
    super.key,
    required this.authService,
    required this.languageService,
    required this.isDarkMode,
    required this.themeMode,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.onThemeChanged,
    required this.onLogout,
    required this.onShowComingSoon,
    required this.onCloseDrawer,
    this.onShowLibraries,
    this.onCreateLibrary,
    this.onJoinLibrary,
    this.onShowBooks,
    this.onCreateBook,
    this.isStudent = false,
  });

  String _getThemeName() {
    switch (themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.gradient:
        return 'Default (Gradient)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: themeMode == AppThemeMode.gradient 
          ? (isDarkMode ? const Color(0xFF1A1A2E) : Colors.white)
          : cardColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            Icons.dashboard_outlined,
                            languageService.translate('dashboard'),
                            () {
                              onCloseDrawer();
                              // Do nothing - already on dashboard
                            },
                            isActive: true, // Highlight as active
                          ),
                          
                          // Library/Class Section
                          const Divider(height: 24),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isStudent ? 'Classes' : 'Libraries',
                                style: AppTheme.caption.copyWith(
                                  color: subtitleColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          
                          // Show Libraries for both Teachers and Students
                          if (onShowLibraries != null)
                            _buildMenuItem(
                              Icons.library_books,
                              isStudent ? 'My Classes' : 'My Libraries',
                              () {
                                onCloseDrawer();
                                onShowLibraries!();
                              },
                            ),
                          
                          // Join Library - NOW AVAILABLE FOR EVERYONE
                          _buildMenuItem(
                            Icons.login,
                            isStudent ? 'Join Class' : 'Join Library',
                            () {
                              onCloseDrawer();
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
                            },
                          ),
                          
                          // Create Library - Only for Teachers
                          if (!isStudent && onCreateLibrary != null)
                            _buildMenuItem(
                              Icons.add_circle_outline,
                              'Create Library',
                              () {
                                onCloseDrawer();
                                onCreateLibrary!();
                              },
                            ),
                          
                          const Divider(height: 24),
                          
                          // Books Section
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Books',
                                style: AppTheme.caption.copyWith(
                                  color: subtitleColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                          if (onShowBooks != null)
                            _buildMenuItem(
                              Icons.menu_book,
                              'My Books',
                              () {
                                onCloseDrawer();
                                onShowBooks!();
                              },
                            ),
                          if (onCreateBook != null)
                            _buildMenuItem(
                              Icons.add_circle_outline,
                              'Create Book',
                              () {
                                onCloseDrawer();
                                onCreateBook!();
                              },
                            ),
                          
                          const Divider(height: 24),
                          
                          _buildMenuItem(
                            Icons.info_outline,
                            languageService.translate('about_us'),
                            () {
                              onCloseDrawer();
                              onShowComingSoon(languageService.translate('about_us'), languageService);
                            },
                          ),
                          _buildMenuItem(
                            Icons.feedback_outlined,
                            languageService.translate('feedback'),
                            () {
                              onCloseDrawer();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FeedbackPage(themeMode: themeMode),
                                ),
                              );
                            },
                          ),
                          
                          const Divider(height: 24),
                          _buildLanguageSelector(),
                        ],
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withValues(alpha:0.1),
        border: Border(
          bottom: BorderSide(
            color: textColor.withValues(alpha:0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF6C5CE7),
            child: Text(
              authService.currentUser?.email?.substring(0, 1).toUpperCase() ?? 
                (isStudent ? 'S' : 'T'),
              style: AppTheme.title.copyWith(
                color: AppTheme.white,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            authService.currentUser?.email ?? (isStudent ? 'Student' : 'Teacher'),
            style: AppTheme.subtitle.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            isStudent ? 'Student Account' : 'Teacher Account',
            style: AppTheme.caption.copyWith(
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isActive = false}) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isActive ? const Color(0xFF6C5CE7) : textColor,
      ),
      title: Text(
        title,
        style: AppTheme.body2.copyWith(
          color: isActive ? const Color(0xFF6C5CE7) : textColor,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isActive 
          ? const Icon(Icons.check_circle, color: Color(0xFF6C5CE7), size: 20)
          : null,
      onTap: onTap,
      tileColor: isActive ? const Color(0xFF6C5CE7).withValues(alpha: 0.1) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildLanguageSelector() {
    return ExpansionTile(
      leading: Icon(Icons.language, color: textColor),
      title: Text(
        languageService.translate('language'),
        style: AppTheme.body2.copyWith(color: textColor),
      ),
      subtitle: Text(
        LanguageService.supportedLanguages
            .firstWhere((lang) => lang['code'] == languageService.currentLanguage)['name']!,
        style: AppTheme.caption.copyWith(color: subtitleColor),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 20),
      childrenPadding: EdgeInsets.zero,
      children: LanguageService.supportedLanguages.map((language) {
        return _buildLanguageOption(
          language['code']!,
          language['name']!,
          _getLanguageIcon(language['code']!),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageOption(String code, String name, IconData icon) {
    final isSelected = code == languageService.currentLanguage;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF6C5CE7) : textColor,
      ),
      title: Text(
        name,
        style: AppTheme.body2.copyWith(
          color: isSelected ? const Color(0xFF6C5CE7) : textColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF6C5CE7))
          : null,
      onTap: () {
        languageService.changeLanguage(code);
        onCloseDrawer();
      },
      contentPadding: const EdgeInsets.only(left: 60, right: 20),
    );
  }

  IconData _getLanguageIcon(String languageCode) {
    switch (languageCode) {
      case 'en':
        return Icons.language; // English - global language icon
      case 'tl':
        return Icons.translate; // Tagalog - translate icon
      case 'es':
        return Icons.g_translate; // Spanish - Google translate icon
      default:
        return Icons.language;
    }
  }

  Widget _buildThemeOption(AppThemeMode mode, String name, IconData icon) {
    final isSelected = themeMode == mode;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF6C5CE7) : textColor,
      ),
      title: Text(
        name,
        style: AppTheme.body2.copyWith(
          color: isSelected ? const Color(0xFF6C5CE7) : textColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF6C5CE7))
          : null,
      onTap: () {
        if (!isSelected) {
          onThemeChanged(mode); // sets specific theme
          onCloseDrawer(); // close drawer after selection
        }
      },
      contentPadding: const EdgeInsets.only(left: 60, right: 20),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: textColor.withValues(alpha:0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          ExpansionTile(
            leading: Icon(Icons.palette, color: textColor),
            title: Text(
              'Theme',
              style: AppTheme.body2.copyWith(color: textColor),
            ),
            subtitle: Text(
              _getThemeName(),
              style: AppTheme.caption.copyWith(color: subtitleColor),
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 20),
            childrenPadding: EdgeInsets.zero,
            children: [
              _buildThemeOption(AppThemeMode.light, 'Light', Icons.light_mode),
              _buildThemeOption(AppThemeMode.dark, 'Dark', Icons.dark_mode),
              _buildThemeOption(AppThemeMode.gradient, 'Default (Gradient)', Icons.gradient),
            ],
          ),  
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              languageService.translate('sign_out'),
              style: AppTheme.body2.copyWith(color: Colors.red),
            ),
            onTap: onLogout,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ],
      ),
    );
  }
}
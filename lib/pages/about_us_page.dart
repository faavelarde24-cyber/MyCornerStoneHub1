// lib/pages/about_us_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class AboutUsPage extends ConsumerWidget {
  final bool isDarkMode;

  const AboutUsPage({super.key, required this.isDarkMode});

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final languageService = ref.watch(languageServiceProvider);
    final backgroundColor = isDarkMode ? AppTheme.nearlyBlack : AppTheme.nearlyWhite;
    final cardColor = isDarkMode ? AppTheme.dark_grey : AppTheme.white;
    final textColor = isDarkMode ? AppTheme.white : AppTheme.darkerText;
    final subtitleColor = isDarkMode ? AppTheme.white.withValues(alpha:0.7) : AppTheme.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          languageService.translate('about_us'),
          style: AppTheme.headline.copyWith(color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo/Brand Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha:0.3)
                        : AppTheme.grey.withValues(alpha:0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha:0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 64,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cornerstone Hub',
                    style: AppTheme.display1.copyWith(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    languageService.translate('by Lisatech'),
                    style: AppTheme.body2.copyWith(
                      color: subtitleColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Company Story Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha:0.3)
                        : AppTheme.grey.withValues(alpha:0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history_edu,
                        color: const Color(0xFF6C5CE7),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        languageService.translate('Our Story'),
                        style: AppTheme.headline.copyWith(
                          color: textColor,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Founded on February 29, 2019, ERL Technology Solutions Inc. was formed to help schools enhance student learning through the use of technology. The founders who are directly connected to the education industry, know and understand the challenges that education institutes face today.',
                    style: AppTheme.body1.copyWith(
                      color: textColor,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Today, ERL Technology Solutions stands as a beacon of hope and progress in the Philippines. With unwavering dedication to its mission, the company continues to empower dreams, one click at a time. The journey has just begun and together, we are rewriting the future of education in the Philippines—a future where every dream is within reach.',
                    style: AppTheme.body1.copyWith(
                      color: textColor,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mission Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha:0.3)
                        : AppTheme.grey.withValues(alpha:0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        color: const Color(0xFF6C5CE7),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        languageService.translate('Mission'),
                        style: AppTheme.headline.copyWith(
                          color: textColor,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withValues(alpha:0.3),
                      ),
                    ),
                    child: Text(
                      'To provide quality solutions to educational institutions, which will enhance the lives of students, teachers, parents, and families.',
                      style: AppTheme.body1.copyWith(
                        color: textColor,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vision Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha:0.3)
                        : AppTheme.grey.withValues(alpha:0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: const Color(0xFF6C5CE7),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        languageService.translate('Vision'),
                        style: AppTheme.headline.copyWith(
                          color: textColor,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withValues(alpha:0.3),
                      ),
                    ),
                    child: Text(
                      'To be the leading education technology solutions partner of choice for educational institutions to attain their goals in molding the future digital generation.',
                      style: AppTheme.body1.copyWith(
                        color: textColor,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Information
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha:0.3)
                        : AppTheme.grey.withValues(alpha:0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.contact_mail_outlined,
                        color: const Color(0xFF6C5CE7),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        languageService.translate('get_in_touch'),
                        style: AppTheme.headline.copyWith(
                          color: textColor,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    label: languageService.translate('email'),
                    value: 'inquiry@lisatech.ph',
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    onTap: () => _launchEmail('inquiry@lisatech.ph'),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.language,
                    label: languageService.translate('company_type'),
                    value: languageService.translate('it_company'),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Social Media Links
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha:0.3)
                        : AppTheme.grey.withValues(alpha:0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        color: const Color(0xFF6C5CE7),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        languageService.translate('follow_us'),
                        style: AppTheme.headline.copyWith(
                          color: textColor,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          icon: Icons.camera_alt,
                          label: 'Instagram',
                          color: const Color(0xFFE4405F),
                          onTap: () => _launchURL('https://instagram.com/mycornerstonehub.ph'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSocialButton(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: const Color(0xFF1877F2),
                          onTap: () => _launchURL('https://facebook.com/mycornerstonehub.ph'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Call to Action
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withValues(alpha:0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Join us in this inspiring mission',
                    style: AppTheme.headline.copyWith(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Together, we will shape the destiny of a nation through education.',
                    style: AppTheme.body1.copyWith(
                      color: subtitleColor,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Version Info
            Center(
              child: Text(
                'Version 1.0.0',
                style: AppTheme.caption.copyWith(
                  color: subtitleColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '© 2025 LisaTech. ${languageService.translate('all_rights_reserved')}',
                style: AppTheme.caption.copyWith(
                  color: subtitleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color subtitleColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: textColor.withValues(alpha:0.7), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.caption.copyWith(
                      color: subtitleColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTheme.body2.copyWith(
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: subtitleColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha:0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: AppTheme.subtitle.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
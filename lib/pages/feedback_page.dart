// lib/pages/feedback_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../models/app_theme_mode.dart';
import '../services/language_service.dart';
import 'package:provider/provider.dart' as provider;

class FeedbackPage extends ConsumerStatefulWidget {
  final AppThemeMode themeMode;
  
  const FeedbackPage({
    super.key,
    required this.themeMode,
  });

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
String _selectedCategory = 'General'; // ✅ Use translation key
final List<String> _categories = [
  'General',
  'Bug Report',
  'Feature Request',
  'UI/UX Issue',
  'Performance',
  'Content Issue',
  'Other',
];
  
  bool _isSubmitting = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return AppTheme.nearlyWhite;
      case AppThemeMode.dark:
        return AppTheme.nearlyBlack;
      case AppThemeMode.gradient:
        return Colors.transparent;
    }
  }

  Color _getCardColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return AppTheme.white;
      case AppThemeMode.dark:
        return AppTheme.dark_grey;
      case AppThemeMode.gradient:
        return Colors.white.withValues(alpha: 0.25);
    }
  }

  Color _getTextColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return AppTheme.darkerText;
      case AppThemeMode.dark:
      case AppThemeMode.gradient:
        return AppTheme.white;
    }
  }

  Color _getSubtitleColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return AppTheme.grey;
      case AppThemeMode.dark:
      case AppThemeMode.gradient:
        return AppTheme.white.withValues(alpha: 0.7);
    }
  }

  Color _getInputBorderColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return AppTheme.grey.withValues(alpha: 0.3);
      case AppThemeMode.dark:
        return AppTheme.white.withValues(alpha: 0.2);
      case AppThemeMode.gradient:
        return Colors.white.withValues(alpha: 0.4);
    }
  }

  Color _getInputFillColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return AppTheme.nearlyWhite;
      case AppThemeMode.dark:
        return AppTheme.nearlyBlack.withValues(alpha: 0.5);
      case AppThemeMode.gradient:
        return Colors.white.withValues(alpha: 0.1);
    }
  }

  bool get _isDarkMode => widget.themeMode == AppThemeMode.dark || 
                          widget.themeMode == AppThemeMode.gradient;

  BoxDecoration _getCardDecoration() {
    if (widget.themeMode == AppThemeMode.gradient) {
      return BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
    
    return BoxDecoration(
      color: _getCardColor(),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get current user ID (optional)
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // Insert feedback into Supabase
      await Supabase.instance.client.from('feedback').insert({
        'user_id': userId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'category': _selectedCategory,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'pending',
      });

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSuccessDialog(),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit feedback: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSuccessDialog() {
    final textColor = _getTextColor();
    final cardColor = _getCardColor();

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Feedback Submitted!',
              style: AppTheme.headline.copyWith(
                color: textColor,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for your feedback. We\'ll review it and get back to you soon!',
              style: AppTheme.body2.copyWith(
                color: _getSubtitleColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = provider.Provider.of<LanguageService>(context);
    final backgroundColor = _getBackgroundColor();
    final textColor = _getTextColor();
    final subtitleColor = _getSubtitleColor();

    return Container(
      decoration: widget.themeMode == AppThemeMode.gradient
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE84C3D), // Red
                  Color(0xFFE67E22), // Orange
                  Color(0xFFF39C12), // Yellow-Orange
                ],
              ),
            )
          : BoxDecoration(color: backgroundColor),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: widget.themeMode == AppThemeMode.gradient 
              ? Colors.black.withValues(alpha: 0.2) 
              : backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            languageService.translate('Feedback & Support'),
            style: AppTheme.headline.copyWith(
              color: textColor,
              fontSize: 20,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _animationController,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(languageService, textColor, subtitleColor),
                  const SizedBox(height: 24),
                  _buildCategorySection(languageService, textColor, subtitleColor),
                  const SizedBox(height: 24),
                  _buildFormFields(textColor, subtitleColor),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageService languageService, Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.feedback_outlined,
              color: widget.themeMode == AppThemeMode.gradient 
                  ? Colors.white 
                  : const Color(0xFF6C5CE7),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageService.translate('We would love to hear your thoughts'),
                  style: AppTheme.subtitle.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  languageService.translate('Share your honest opinions, report bugs, or request features'),
                  style: AppTheme.caption.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildCategorySection(LanguageService languageService, Color textColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTheme.subtitle.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _getCardDecoration(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: _getCardColor(),
              icon: Icon(Icons.arrow_drop_down, color: textColor),
              style: AppTheme.body2.copyWith(color: textColor),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 20,
                        color: const Color(0xFF6C5CE7),
                      ),
                      const SizedBox(width: 12),
                      Text(languageService.translate(category)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Bug Report':
        return Icons.bug_report;
      case 'Feature Request':
        return Icons.lightbulb_outline;
      case 'UI/UX Issue':
        return Icons.palette;
      case 'Performance':
        return Icons.speed;
      case 'Content Issue':
        return Icons.content_paste;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  Widget _buildFormFields(Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline,
          textColor: textColor,
          keyboardType: TextInputType.name,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            if (value.length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'your.email@example.com',
            icon: Icons.email_outlined,
            textColor: textColor,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _subjectController,
            label: 'Subject',
            hint: 'Brief description of your feedback',
            icon: Icons.subject,
            textColor: textColor,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a subject';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _messageController,
            label: 'Message',
            hint: 'Tell us more about your feedback...',
            icon: Icons.message_outlined,
            textColor: textColor,
            maxLines: 6,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your message';
              }
              if (value.length < 10) {
                return 'Message must be at least 10 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color textColor,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.body2.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTheme.body2.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.body2.copyWith(
              color: _getSubtitleColor(),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7)),
            filled: true,
            fillColor: _getInputFillColor(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getInputBorderColor()),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getInputBorderColor()),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6C5CE7),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Submit Feedback',
                    style: AppTheme.subtitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
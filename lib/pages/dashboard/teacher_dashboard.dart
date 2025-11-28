// lib/pages/dashboards/teacher_dashboard.dart
import 'package:cornerstone_hub/providers/book_providers.dart';
import 'package:cornerstone_hub/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/language_service.dart';
import '../../app_theme.dart';
import '../../models/book_models.dart';
import '../auth/login_page.dart';
import 'package:cornerstone_hub/pages/about_us_page.dart';
import 'package:cornerstone_hub/pages/book_creator/book_creator_page.dart';
import 'package:cornerstone_hub/pages/library/widgets/create_library_dialog.dart';
import 'package:cornerstone_hub/pages/library/widgets/libraries_list_dialog.dart';
import 'package:cornerstone_hub/pages/library/widgets/library_details_page.dart';
import 'package:cornerstone_hub/providers/library_providers.dart';
import 'package:cornerstone_hub/models/library_models.dart';
import 'package:cornerstone_hub/models/app_theme_mode.dart';
import 'package:cornerstone_hub/pages/book/widgets/books_list_dialog.dart';
import '../../providers/auth_providers.dart';
import '../../main.dart';
import 'package:cornerstone_hub/pages/dashboard/book_dashboard_page.dart';
import 'package:cornerstone_hub/pages/book_creator/choose_book_size_page.dart';
import 'package:cornerstone_hub/models/book_size_type.dart';
import 'dart:async'; // For Completer
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:cornerstone_hub/services/book_export_service.dart'; 
import 'package:cornerstone_hub/pages/dashboard/widgets/combine_books_page.dart'; 
import 'package:cornerstone_hub/pages/library/widgets/join_library_dialog.dart';
import 'package:flutter/services.dart';

class ModernTeacherDashboard extends ConsumerStatefulWidget {
  const ModernTeacherDashboard({super.key});

  @override
  ConsumerState<ModernTeacherDashboard> createState() => _ModernTeacherDashboardState();
}

class _ModernTeacherDashboardState extends ConsumerState<ModernTeacherDashboard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  AppThemeMode _themeMode = AppThemeMode.gradient; // Default theme
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    super.dispose();
  }

void _toggleTheme() {
  setState(() {
    switch (_themeMode) {
      case AppThemeMode.light:
        _themeMode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        _themeMode = AppThemeMode.gradient;
        break;
      case AppThemeMode.gradient:
        _themeMode = AppThemeMode.light;
        break;
    }
  });
}

void _setThemeMode(AppThemeMode mode) {
  setState(() {
    _themeMode = mode;
  });
}

  void _showCreateLibraryDialog() async {
    final library = await showDialog<Library>(
      context: context,
      builder: (context) => const CreateLibraryDialog(),
    );
    
    if (library != null && mounted) {
      _showSnackBar('Library "${library.name}" created successfully!');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LibraryDetailsPage(library: library),
        ),
      );
    }
  }

void _showJoinLibraryDialog() {
  showDialog(
    context: context,
    builder: (context) => const JoinLibraryDialog(),
  ).then((_) {
    // Refresh libraries after dialog closes
    ref.invalidate(userLibrariesProvider);
    ref.invalidate(joinedLibrariesProvider);
  });
}

void _showLibrariesList() {
  showDialog(
    context: context,
    builder: (context) => LibrariesListDialog(
      themeMode: _themeMode,
      isDarkMode: _isDarkMode,
    ),
  );
}

void _navigateToBookDashboard() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const BookDashboardPage(),
    ),
  );
}

void _showBooksList() {
  showDialog(
    context: context,
    builder: (context) => BooksListDialog(
      themeMode: _themeMode,
      isDarkMode: _isDarkMode,
    ),
  );
}
  Future<void> _handleLogout() async {
  try {
    // Invalidate ALL providers BEFORE signing out
    ref.invalidate(userBooksProvider);
    ref.invalidate(userLibrariesProvider);
    ref.invalidate(joinedLibrariesProvider);
    ref.invalidate(currentBookIdProvider);
    ref.invalidate(currentPageIndexProvider);
    ref.invalidate(bookPagesProvider);
    
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
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

void _createNewBook() async {
  debugPrint('🟢 === _createNewBook START ===');
  
  // Step 1: Show title/description dialog
  final bookDetails = await showDialog<Map<String, String?>>(
    context: context,
    builder: (dialogContext) => _CreateBookDialog(),
  );

  // User cancelled the dialog
  if (bookDetails == null) {
    debugPrint('❌ Book creation cancelled at title dialog');
    return;
  }

  final title = bookDetails['title']!;
  final description = bookDetails['description'];
  
  debugPrint('📝 Book title: $title');
  debugPrint('📝 Description: ${description ?? "none"}');

  // Step 2: Show size selection
  debugPrint('📏 Opening size selection page...');
  final selectedSize = await Navigator.push<BookSizeType>(
    context,
    MaterialPageRoute(
      builder: (context) => ChooseBookSizePage(
        title: title,
        description: description,
      ),
    ),
  );

  debugPrint('🔙 Returned from ChooseBookSizePage');
  debugPrint('Context mounted: $mounted');
  debugPrint('Selected size: ${selectedSize?.label ?? "cancelled"}');

  // User cancelled size selection
  if (selectedSize == null) {
    debugPrint('❌ Size selection cancelled');
    return;
  }

  if (!mounted) return;

  // Step 3: Create the book
  debugPrint('⏳ Showing loading snackbar...');
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          Text('Creating book...'),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 30),
    ),
  );

  debugPrint('📚 Calling bookActions.createBook...');
  final bookActions = ref.read(bookActionsProvider);
  final book = await bookActions.createBook(
    title: title,
    description: description,
    sizeType: selectedSize,
  );

  debugPrint('📚 Book creation result: ${book != null ? book.id : "null"}');

  if (!mounted) {
    debugPrint('⚠️ Widget unmounted after book creation');
    return;
  }

  // Hide loading indicator
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  if (book != null) {
    debugPrint('✅ Book created successfully: ${book.id}');
    debugPrint('📄 Book has ${book.pageCount} pages');
    
    // Wait for provider to sync
    debugPrint('⏳ Waiting for provider sync...');
    await Future.delayed(const Duration(milliseconds: 800));
    
    debugPrint('🔄 Setting current book ID...');
    ref.read(currentBookIdProvider.notifier).setBookId(book.id);
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Refresh book list
    ref.invalidate(userBooksProvider);
    
    // Navigate to book creator
    debugPrint('🚀 Navigating to BookCreatorPage...');
    
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            debugPrint('🏗️ Building BookCreatorPage...');
            return BookCreatorPage(bookId: book.id);
          },
        ),
      );
      debugPrint('✅ Returned from BookCreatorPage');
    } catch (e, stack) {
      debugPrint('❌ Navigation error: $e');
      debugPrint('Stack: $stack');
    }
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book "${book.title}" created successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
    
    debugPrint('🟢 === _createNewBook END (SUCCESS) ===');
  } else {
    debugPrint('❌ Book creation failed');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create book. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
    
    debugPrint('🟢 === _createNewBook END (FAILED) ===');
  }
}

  void _editBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookCreatorPage(bookId: book.id),
      ),
    ).then((_) {
      ref.invalidate(userBooksProvider);
    });
  }

  Future<void> _deleteBook(Book book, LanguageService languageService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageService.translate('delete')),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final bookActions = ref.read(bookActionsProvider);
      final success = await bookActions.deleteBook(book.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Book deleted successfully' 
              : 'Failed to delete book'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _duplicateBook(Book book) async {
    _showSnackBar('Duplicating book...');
    
    final bookActions = ref.read(bookActionsProvider);
    final newBook = await bookActions.duplicateBook(book.id);
    
    if (mounted) {
      _showSnackBar(newBook != null 
        ? 'Book duplicated successfully' 
        : 'Failed to duplicate book');
    }
  }

  // ========== COMBINE BOOKS ==========
void _showCombineBooksFlow(Book initialBook) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CombineBooksPage(initialBook: initialBook),
    ),
  ).then((_) {
    // Refresh books list when returning
    ref.invalidate(userBooksProvider);
  });
}

// ========== EXPORT PDF ==========
Future<void> _handleExportPDF(Book book) async {
  debugPrint('📄 === EXPORT PDF START ===');
  debugPrint('Book: ${book.title}');
  
  // Create a completer to control dialog dismissal
  final dialogCompleter = Completer<void>();
  
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      // Listen for completion signal
      dialogCompleter.future.then((_) {
        if (dialogContext.mounted) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        }
      });
      
      return PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Exporting to PDF...',
                style: AppTheme.body1,
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a moment',
                style: AppTheme.caption,
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    // Get pages
    debugPrint('📄 Fetching pages...');
    final pages = await ref.read(bookPagesProvider(book.id).future);
    debugPrint('📄 Pages loaded: ${pages.length}');

    if (pages.isEmpty) {
      // Close loading dialog
      if (!dialogCompleter.isCompleted) {
        dialogCompleter.complete();
      }
      
      // Wait for dialog to close
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot export: Book has no pages'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Export to PDF
    debugPrint('📄 Starting export...');
    final exportService = BookExportService();
    final pdfFile = await exportService.exportAsPDF(
      book: book,
      pages: pages,
    );

    debugPrint('📄 Export completed, closing dialog...');
    
    // ✅ Close loading dialog using completer
    if (!dialogCompleter.isCompleted) {
      dialogCompleter.complete();
    }

    // Wait for dialog animation to complete
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    if (pdfFile != null) {
      debugPrint('✅ PDF exported successfully: ${pdfFile.path}');
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('PDF Exported!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kIsWeb 
                    ? 'Your book has been downloaded as PDF.'
                    : 'Your book has been exported as PDF.',
                style: AppTheme.body1,
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: 12),
                Text(
                  'Location: ${pdfFile.path}',
                  style: AppTheme.caption,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            // Only show Share button on mobile/desktop
            if (!kIsWeb)
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await exportService.shareFile(pdfFile, book.title);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                ),
              ),
          ],
        ),
      );
    } else {
      debugPrint('❌ PDF export failed');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export PDF'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e, stack) {
    debugPrint('❌ Export error: $e');
    debugPrint('Stack: $stack');
    
    // Ensure loading dialog is closed
    if (!dialogCompleter.isCompleted) {
      dialogCompleter.complete();
    }
    
    // Wait for dialog to close
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ========== EXPORT EPUB ==========
Future<void> _handleExportEPUB(Book book) async {
  debugPrint('📚 === EXPORT EPUB START ===');
  debugPrint('Book: ${book.title}');
  
  // Show coming soon dialog for now
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
          SizedBox(width: 12),
          Text('EPUB Export'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EPUB export is coming soon!',
            style: AppTheme.body1,
          ),
          const SizedBox(height: 12),
          Text(
            'For now, you can export as PDF. We\'re working on full EPUB support with proper formatting and metadata.',
            style: AppTheme.caption,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _handleExportPDF(book);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
          ),
          child: const Text('Export as PDF Instead'),
        ),
      ],
    ),
  );
}

  Color _getBackgroundColor() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.nearlyWhite;
      case AppThemeMode.dark:
        return AppTheme.nearlyBlack;
      case AppThemeMode.gradient:
        return Colors.transparent;
    }
  }

  Color _getCardColor() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.white;
      case AppThemeMode.dark:
        return AppTheme.dark_grey;
      case AppThemeMode.gradient:
        return Colors.white.withValues(alpha:0.25);
    }
  }

  Color _getCardTextColor() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.darkerText;
      case AppThemeMode.dark:
        return AppTheme.white;
      case AppThemeMode.gradient:
        return const Color(0xFF2C3E50);
    }
  }

  Color _getTextColor() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.darkerText;
      case AppThemeMode.dark:
      case AppThemeMode.gradient:
        return AppTheme.white;
    }
  }

  Color _getSubtitleColor() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.grey;
      case AppThemeMode.dark:
      case AppThemeMode.gradient:
        return AppTheme.white.withValues(alpha:0.7);
    }
  }

  bool get _isDarkMode => _themeMode == AppThemeMode.dark || _themeMode == AppThemeMode.gradient;
  

BoxDecoration _getCardDecoration() {
  if (_themeMode == AppThemeMode.gradient) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF24346D).withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
  
  return BoxDecoration(
    color: _getCardColor(),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: _isDarkMode 
          ? Colors.grey.withValues(alpha: 0.2)
          : Color(0xFFA6A6A6).withValues(alpha: 0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: _isDarkMode
            ? Colors.black.withValues(alpha: 0.3)
            : Color(0xFF24346D).withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
@override
Widget build(BuildContext context) {
  final languageService = ref.watch(languageServiceProvider);
  final backgroundColor = _getBackgroundColor();
  final cardColor = _getCardColor();
  final textColor = _getTextColor();
  final subtitleColor = _getSubtitleColor();
  final authService = ref.read(authServiceProvider);

  return Container(
    decoration: _themeMode == AppThemeMode.gradient
        ? const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF24346D), // Passionate blu
                Color(0xFF4A5A9D), // Mid tone blue
                Color(0xFFFF914D), // Rust Orange
              ],
            ),
          )
        : BoxDecoration(color: backgroundColor),
    child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer: AppDrawer(
        authService: authService,
        languageService: languageService,
        isDarkMode: _isDarkMode,
        themeMode: _themeMode,
        cardColor: cardColor,
        textColor: textColor,
        subtitleColor: subtitleColor,
        onThemeChanged: _setThemeMode,  
        onLogout: _handleLogout,
        onShowComingSoon: _showComingSoon,
        onCloseDrawer: () => Navigator.pop(context),
        onShowLibraries: _showLibrariesList,
        onCreateLibrary: _showCreateLibraryDialog,
        onShowBooks: _showBooksList,
        onCreateBook: _createNewBook,
        onBookDashboardTap: _navigateToBookDashboard,
        isStudent: false,
      ),
      body: Column(
        children: [
          _buildAppBar(backgroundColor, textColor, languageService),
          Expanded(
            child: _buildDashboardContent(cardColor, textColor, subtitleColor, languageService),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildAppBar(
  Color backgroundColor,
  Color textColor,
  LanguageService languageService,
) {
  return Container(
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      bottom: 8,
    ),
    decoration: BoxDecoration(
      color: _themeMode == AppThemeMode.gradient
          ? Colors.black.withValues(alpha: 0.2)
          : backgroundColor,
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withValues(alpha: 0.3)
              : AppTheme.grey.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Text(
          'MyCornerStoneHub',
          style: AppTheme.headline.copyWith(
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            _themeMode == AppThemeMode.light
                ? Icons.light_mode
                : _themeMode == AppThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.gradient,
            color: textColor,
          ),
          onPressed: _toggleTheme,
          tooltip: 'Toggle Theme',
        ),
        const SizedBox(width: 8),
        // Add Book Dashboard Icon
        IconButton(
          icon: const Icon(Icons.auto_stories),
          color: textColor,
          onPressed: _navigateToBookDashboard,
          tooltip: 'Book Dashboard',
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          borderRadius: BorderRadius.circular(20),
          child: Builder(
            builder: (context) {
              final authService = ref.read(authServiceProvider);
              final email = authService.currentUser?.email;
              final displayInitial =
                  (email != null && email.isNotEmpty) ? email[0].toUpperCase() : 'T';

              return CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF6C5CE7),
                child: Text(
                  displayInitial,
                  style: AppTheme.title.copyWith(
                    color: const Color.fromARGB(255, 239, 239, 239),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDashboardContent(Color cardColor, Color textColor, Color subtitleColor, LanguageService languageService) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userBooksProvider);
        ref.invalidate(userLibrariesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(textColor, subtitleColor, languageService),
            const SizedBox(height: 24),
            _buildGetStartedSection(cardColor, textColor, subtitleColor, languageService),
            const SizedBox(height: 24),
            _buildBooksSection(cardColor, textColor, subtitleColor, languageService),
            const SizedBox(height: 24),
            _buildLibrariesSection(cardColor, textColor, subtitleColor, languageService),
          ],
        ),
      ),
    );
  }

Widget _buildWelcomeSection(Color textColor, Color subtitleColor, LanguageService languageService) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFDE59).withValues(alpha: 0.3),
                  Color(0xFFFF914D).withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.school,
              color: textColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back, Educator',
                  style: AppTheme.display1.copyWith(
                    fontSize: 26,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Plan. Teach. Share.',
                  style: AppTheme.body1.copyWith(
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFFFDE59),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'For educators who think ahead.',
                  style: AppTheme.body1.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickStat('📚', 'Create', textColor),
                const SizedBox(width: 16),
                _buildQuickStat('🎯', 'Organize', textColor),
                const SizedBox(width: 16),
                _buildQuickStat('🚀', 'Scale', textColor),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildQuickStat(String emoji, String label, Color textColor) {
  return Row(
    children: [
      Text(emoji, style: TextStyle(fontSize: 16)),
      const SizedBox(width: 6),
      Text(
        label,
        style: AppTheme.caption.copyWith(
          color: textColor.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ],
  );
}

  Widget _buildGetStartedSection(Color cardColor, Color textColor, Color subtitleColor, LanguageService languageService) {
  final examples = [
    {'icon': '📊', 'title': 'Lesson Plans', 'color': const Color(0xFF24346D)},      // Passionate Blue
    {'icon': '🎓', 'title': 'Curriculum Design', 'color': const Color(0xFFFF914D)},  // Rust Orange
    {'icon': '📝', 'title': 'Assessments', 'color': const Color(0xFFFFDE59)},        // Mustard
    {'icon': '🔄', 'title': 'Collaborative Teaching', 'color': const Color(0xFFA6A6A6)}, // Quicksilver
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF24346D).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.explore,
              color: textColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Structure meets flexibility.',
            style: AppTheme.headline.copyWith(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: examples.length,
          itemBuilder: (context, index) {
            final example = examples[index];
            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: Container(
                width: 160,
                margin: EdgeInsets.only(right: 12),
                decoration: _getCardDecoration(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (example['color'] as Color).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        example['icon'] as String,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        languageService.translate(example['title'] as String),
                        style: AppTheme.caption.copyWith(
                          color: _getCardTextColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

  Widget _buildBooksSection(Color cardColor, Color textColor, Color subtitleColor, LanguageService languageService) {
    final booksAsync = ref.watch(userBooksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF24346D).withValues(alpha: 0.2),
                Color(0xFFFF914D).withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            color: textColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Your Books',
          style: AppTheme.headline.copyWith(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    ),
    Row(
      children: [
        TextButton.icon(
          onPressed: _showBooksList,
          icon: Icon(Icons.grid_view, size: 18, color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
          label: Text(
            'View All',
            style: TextStyle(
              color: _themeMode == AppThemeMode.gradient ? Colors.white : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _themeMode == AppThemeMode.gradient ? Colors.white : const Color(0xFF24346D),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _createNewBook,
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: Text(
            languageService.translate('create_new'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF914D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
        ),
      ],
    ),
  ],
),
        const SizedBox(height: 12),
        booksAsync.when(
          data: (books) {
            if (books.isEmpty) {
              return _buildEmptyBooksState(cardColor, textColor, subtitleColor, languageService);
            }
            
            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: books.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCreateNewCard(cardColor, textColor, languageService);
                  }
                  return _buildBookCard(
                    books[index - 1],
                    cardColor,
                    textColor,
                    subtitleColor,
                    languageService,
                  );
                },
              ),
            );
          },
          loading: () => Container(
            height: 180,
            decoration: _getCardDecoration(),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text('Error loading books: $error'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(userBooksProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

Widget _buildLibrariesSection(
  Color cardColor,
  Color textColor,
  Color subtitleColor,
  LanguageService languageService,
) {
  final createdLibrariesAsync = ref.watch(userLibrariesProvider);
  final joinedLibrariesAsync = ref.watch(joinedLibrariesProvider);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFDE59).withValues(alpha: 0.3),
                Color(0xFFFF914D).withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.library_books_rounded,
            color: textColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Libraries & Networks',
          style: AppTheme.headline.copyWith(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    ),
    Row(
      children: [
        TextButton.icon(
          onPressed: _showLibrariesList,
          icon: Icon(Icons.library_books, size: 18, color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
          label: Text(
            'View All',
            style: TextStyle(color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _themeMode == AppThemeMode.gradient ? Colors.white : const Color(0xFF24346D),
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _showCreateLibraryDialog,
          icon: Icon(Icons.add_circle_outline, size: 18, color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
          label: Text(
            'Create Library',
            style: TextStyle(color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _themeMode == AppThemeMode.gradient ? Colors.white : const Color(0xFF24346D),
          ),
        ),
      ],
    ),
  ],
),
      const SizedBox(height: 12),
      
      createdLibrariesAsync.when(
        data: (createdLibraries) {
          return joinedLibrariesAsync.when(
            data: (joinedLibraries) {
              // ✅ FIXED: Deduplicate by library ID
              final libraryMap = <String, Library>{};
              
              // Add created libraries first (prioritize creator view)
              for (var library in createdLibraries) {
                libraryMap[library.id] = library;
              }
              
              // Add joined libraries (only if not already present)
              for (var library in joinedLibraries) {
                libraryMap.putIfAbsent(library.id, () => library);
              }
              
              final allLibraries = libraryMap.values.toList();
              
              if (allLibraries.isEmpty) {
                return _buildEmptyLibrariesState(cardColor, textColor, subtitleColor);
              }
              
              return SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allLibraries.length.clamp(0, 5),
                  itemBuilder: (context, index) {
                    return _buildLibraryCard(
                      allLibraries[index],
                      cardColor,
                      textColor,
                      subtitleColor,
                    );
                  },
                ),
              );
            },
            loading: () => Container(
              height: 140,
              decoration: _getCardDecoration(),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              ),
            ),
            error: (error, _) => Center(
              child: Text('Error loading joined libraries: $error'),
            ),
          );
        },
        loading: () => Container(
          height: 140,
          decoration: _getCardDecoration(),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
          ),
        ),
        error: (error, _) => Center(
          child: Text('Error loading libraries: $error'),
        ),
      ),
    ],
  );
}

  Widget _buildEmptyLibrariesState(
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      height: 140,
      decoration: _getCardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 48, color: _getCardTextColor()),
            const SizedBox(height: 8),
            Text('No libraries yet', style: TextStyle(color: _getCardTextColor(), fontSize: 14)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showCreateLibraryDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create First Library'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildLibraryCard(
  Library library,
  Color cardColor,
  Color textColor,
  Color subtitleColor,
) {
  final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink];
  final colorIndex = int.parse(library.id) % colors.length;
  final color = colors[colorIndex];

  return Container(
    width: 160,
    margin: const EdgeInsets.only(right: 12),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LibraryDetailsPage(library: library),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: _getCardDecoration(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with icon and name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.library_books, size: 20, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    library.name,
                    style: TextStyle(
                      color: _getCardTextColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            
            // Subject (if available)
            if (library.subject != null) ...[
              Text(
                library.subject!,
                style: TextStyle(
                  fontSize: 11,
                  color: _getCardTextColor().withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            
            // Bottom section with stats and menu button
            Row(
              children: [
                // Stats
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.book, size: 12, color: _getCardTextColor().withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text('${library.bookCount}', style: TextStyle(fontSize: 11, color: _getCardTextColor().withValues(alpha: 0.7))),
                      const SizedBox(width: 12),
                      Icon(Icons.people, size: 12, color: _getCardTextColor().withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text('${library.memberCount}', style: TextStyle(fontSize: 11, color: _getCardTextColor().withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                
                // ✅ Menu button (bottom-right, matching book cards)
                IconButton(
                  onPressed: () => _showLibraryCardOptions(library),
                  icon: Icon(Icons.more_vert, color: _getCardTextColor()),
                  iconSize: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void _showLibraryCardOptions(Library library) {
  final sheetBg = _isDarkMode ? AppTheme.dark_grey : AppTheme.white;
  final sheetText = _isDarkMode ? AppTheme.white : AppTheme.darkerText;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: sheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with library info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.library_books, color: Color(0xFF6C5CE7)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Library Options',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        library.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // View Details
          ListTile(
            leading: Icon(Icons.visibility, color: sheetText),
            title: Text(
              'View Details',
              style: AppTheme.body2.copyWith(color: sheetText),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LibraryDetailsPage(library: library),
                ),
              );
            },
          ),
          
          // Share Invite Code
          ListTile(
            leading: const Icon(Icons.share, color: Color(0xFF3B82F6)),
            title: Text(
              'Share Invite Code',
              style: AppTheme.body2.copyWith(color: sheetText),
            ),
            subtitle: Text(
              'Share code with students',
              style: AppTheme.caption.copyWith(
                color: sheetText.withValues(alpha: 0.7),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showShareLibraryDialog(library);
            },
          ),
          
          Divider(color: _isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          
          // Delete Library
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              'Delete Library',
              style: AppTheme.body2.copyWith(color: Colors.red),
            ),
            subtitle: Text(
              'Remove library and all members',
              style: AppTheme.caption.copyWith(
                color: sheetText.withValues(alpha: 0.7),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeleteLibraryConfirmation(library);
            },
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void _showShareLibraryDialog(Library library) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.share, color: Color(0xFF3B82F6)),
          SizedBox(width: 12),
          Text('Share Invite Code'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share this code with students to join "${library.name}":',
            style: AppTheme.body1,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  library.inviteCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: library.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Invite code copied!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> _showDeleteLibraryConfirmation(Library library) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 12),
          Text('Delete Library'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${library.name}"?',
            style: AppTheme.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• All members will be removed\n'
                  '• All books will be unlinked\n'
                  '• The invite code will be deleted',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  // Show loading
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          Text('Deleting library...'),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 30),
    ),
  );

  final actions = ref.read(libraryActionsProvider);
  final success = await actions.deleteLibrary(library.id);

  if (mounted) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(success
                  ? 'Library "${library.name}" deleted successfully'
                  : 'Failed to delete library'),
            ),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

  Widget _buildEmptyBooksState(Color cardColor, Color textColor, Color subtitleColor, LanguageService languageService) {
    return Container(
      height: 180,
      decoration: _getCardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: _getCardTextColor(),
            ),
            const SizedBox(height: 12),
            Text(
              'No books yet',
              style: AppTheme.subtitle.copyWith(
                color: _getCardTextColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first book to get started',
              style: AppTheme.caption.copyWith(color: _getCardTextColor().withValues(alpha:0.7)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _createNewBook,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Book'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateNewCard(Color cardColor, Color textColor, LanguageService languageService) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12, left: 0),
      child: InkWell(
        onTap: _createNewBook,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: _themeMode == AppThemeMode.gradient
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha:0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha:0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6C5CE7).withValues(alpha:0.4),
                    width: 2,
                  ),
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _themeMode == AppThemeMode.gradient
                      ? Colors.white.withValues(alpha:0.3)
                      : const Color(0xFF6C5CE7).withValues(alpha:0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: 32,
                  color: _themeMode == AppThemeMode.gradient
                      ? Colors.white
                      : const Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${languageService.translate('create_new')}\n${languageService.translate('books')}',
                style: AppTheme.subtitle.copyWith(
                  color: _getCardTextColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(Book book, Color cardColor, Color textColor, Color subtitleColor, LanguageService languageService) {
    final colors = [
  const Color(0xFF24346D),  // Passionate Blue
  const Color(0xFFFF914D),  // Rust Orange
  const Color(0xFFFFDE59),  // Mustard
  const Color(0xFFA6A6A6),  // Quicksilver
];
    final colorIndex = int.parse(book.id) % colors.length;
    final bookColor = colors[colorIndex];

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: FadeTransition(
        opacity: _animationController,
        child: Container(
          decoration: _getCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 75,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      bookColor.withValues(alpha:0.7),
                      bookColor.withValues(alpha:0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: book.coverImageUrl != null
                      ? Image.network(
                          book.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.book,
                            size: 36,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.book,
                          size: 36,
                          color: Colors.white,
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: AppTheme.subtitle.copyWith(
                              color: _getCardTextColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(book.updatedAt),
                            style: AppTheme.caption.copyWith(
                              color: _getCardTextColor().withValues(alpha:0.7),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _editBook(book),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                minimumSize: const Size(0, 24),
                                side: BorderSide(
                                  color: _getCardTextColor().withValues(alpha:0.3),
                                ),
                                foregroundColor: _getCardTextColor(),
                              ),
                              child: Text(languageService.translate('edit'), style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            onPressed: () => _showBookOptions(book, languageService),
                            icon: Icon(Icons.more_vert, color: _getCardTextColor()),
                            iconSize: 14,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

void _showBookOptions(Book book, LanguageService languageService) {
  final sheetBg = _isDarkMode ? AppTheme.dark_grey : AppTheme.white;
  final sheetText = _isDarkMode ? AppTheme.white : AppTheme.darkerText;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: sheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with book title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, color: Color(0xFF6C5CE7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Book Options',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Edit
            ListTile(
              leading: Icon(Icons.edit, color: sheetText),
              title: Text(
                languageService.translate('edit'),
                style: AppTheme.body2.copyWith(color: sheetText),
              ),
              onTap: () {
                Navigator.pop(context);
                _editBook(book);
              },
            ),
            
            // Duplicate
            ListTile(
              leading: Icon(Icons.copy, color: sheetText),
              title: Text(
                languageService.translate('duplicate'),
                style: AppTheme.body2.copyWith(color: sheetText),
              ),
              onTap: () {
                Navigator.pop(context);
                _duplicateBook(book);
              },
            ),
            
            Divider(color: _isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            
            // ✅ NEW: Combine Books
            ListTile(
              leading: const Icon(Icons.merge_type, color: Color(0xFFF59E0B)),
              title: Text(
                'Combine Books',
                style: AppTheme.body2.copyWith(color: sheetText),
              ),
              subtitle: Text(
                'Merge multiple books into one',
                style: AppTheme.caption.copyWith(
                  color: sheetText.withValues(alpha: 0.7),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCombineBooksFlow(book);
              },
            ),
            
            Divider(color: _isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            
            // ✅ NEW: Export as PDF
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
              title: Text(
                'Export as PDF',
                style: AppTheme.body2.copyWith(color: sheetText),
              ),
              subtitle: Text(
                'Download book as PDF file',
                style: AppTheme.caption.copyWith(
                  color: sheetText.withValues(alpha: 0.7),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleExportPDF(book);
              },
            ),
            
            // ✅ NEW: Export as EPUB
            ListTile(
              leading: const Icon(Icons.book_outlined, color: Color(0xFF10B981)),
              title: Text(
                'Export as EPUB',
                style: AppTheme.body2.copyWith(color: sheetText),
              ),
              subtitle: Text(
                'Download book as EPUB file',
                style: AppTheme.caption.copyWith(
                  color: sheetText.withValues(alpha: 0.7),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleExportEPUB(book);
              },
            ),
            
            Divider(color: _isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            
            // Share
            ListTile(
              leading: Icon(Icons.share, color: sheetText),
              title: Text(
                languageService.translate('share'),
                style: AppTheme.body2.copyWith(color: sheetText),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('${languageService.translate('share')} ${book.title}', languageService);
              },
            ),
            
            // Delete
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                languageService.translate('delete'),
                style: AppTheme.body2.copyWith(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteBook(book, languageService);
              },
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

  void _showComingSoon(String feature, LanguageService languageService) {
    if (feature == languageService.translate('about_us')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AboutUsPage(isDarkMode: _isDarkMode),
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - ${languageService.translate('coming_soon')}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isDarkMode ? AppTheme.grey : AppTheme.nearlyBlack,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ========== CREATE BOOK DIALOG ==========
class _CreateBookDialog extends StatefulWidget {
  const _CreateBookDialog();

  @override
  State<_CreateBookDialog> createState() => _CreateBookDialogState();
}

class _CreateBookDialogState extends State<_CreateBookDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Create New Book',
        style: AppTheme.headline,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Book Title',
              labelStyle: AppTheme.body2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.chipBackground,
            ),
            style: AppTheme.body1,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: AppTheme.body2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.chipBackground,
            ),
            style: AppTheme.body1,
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            debugPrint('❌ Create book dialog cancelled');
            Navigator.pop(context); // Returns null
          },
          child: Text(
            'Cancel',
            style: AppTheme.body1.copyWith(
              color: AppTheme.lightText,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a book title'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            final title = _titleController.text.trim();
            final description = _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null;

            debugPrint('✅ Book details submitted: $title');
            
            // Return the data to the parent
            Navigator.pop(context, {
              'title': title,
              'description': description,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFBBF24),
            foregroundColor: AppTheme.darkerText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Next'),
        ),
      ],
    );
  }
}
// lib/pages/dashboards/teacher_dashboard.dart
import 'package:cornerstone_hub/providers/book_providers.dart';
import 'package:cornerstone_hub/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import '../../app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../providers/book_providers.dart' as book_providers;
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


class ModernTeacherDashboard extends ConsumerStatefulWidget {
  const ModernTeacherDashboard({super.key});

  @override
  ConsumerState<ModernTeacherDashboard> createState() => _ModernTeacherDashboardState();
}

class _ModernTeacherDashboardState extends ConsumerState<ModernTeacherDashboard> 
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
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

void _showLibrariesList() {
  showDialog(
    context: context,
    builder: (context) => LibrariesListDialog(
      themeMode: _themeMode,
      isDarkMode: _isDarkMode,
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
    
    await _authService.signOut();
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

  void _createNewBook() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookCreatorPage(),
      ),
    ).then((_) {
      ref.invalidate(book_providers.userBooksProvider);
    });
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
        color: Colors.white.withValues(alpha:0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha:0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
    
    return BoxDecoration(
      color: _getCardColor(),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: _isDarkMode
              ? Colors.black.withValues(alpha:.3)
              : Colors.grey.withValues(alpha:0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = provider.Provider.of<LanguageService>(context);
    final backgroundColor = _getBackgroundColor();
    final cardColor = _getCardColor();
    final textColor = _getTextColor();
    final subtitleColor = _getSubtitleColor();

    return Container(
      decoration: _themeMode == AppThemeMode.gradient
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
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        endDrawer: AppDrawer(
          authService: _authService,
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
          onShowBooks: _showBooksList,        // ✅ ADD THIS
          onCreateBook: _createNewBook, 
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

  Widget _buildAppBar(Color backgroundColor, Color textColor, LanguageService languageService) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: _themeMode == AppThemeMode.gradient 
            ? Colors.black.withValues(alpha:0.2) 
            : backgroundColor,
        boxShadow: [
          BoxShadow(
            color: _isDarkMode 
                ? Colors.black.withValues(alpha:0.3)
                : AppTheme.grey.withValues(alpha:0.1),
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
          InkWell(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF6C5CE7),
              child: Text(
                _authService.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'T',
                style: AppTheme.title.copyWith(
                  color: const Color.fromARGB(255, 239, 239, 239),
                ),
              ),
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
        Text(
          languageService.translate('welcome'),
          style: AppTheme.display1.copyWith(
            fontSize: 28,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          languageService.translate('create_books'),
          style: AppTheme.body1.copyWith(
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGetStartedSection(Color cardColor, Color textColor, Color subtitleColor, LanguageService languageService) {
    final examples = [
      {'icon': '📖', 'title': 'digital_portfolios', 'color': Colors.blue},
      {'icon': '🎨', 'title': 'interactive_lessons', 'color': Colors.orange},
      {'icon': '📚', 'title': 'storybooks', 'color': Colors.teal},
      {'icon': '🎤', 'title': 'audio_narrations', 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageService.translate('what_you_can_create'),
          style: AppTheme.headline.copyWith(
            color: textColor,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
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
                  width: 140,
                  margin: EdgeInsets.only(
                    right: 12,
                    left: index == 0 ? 0 : 0,
                  ),
                  decoration: _getCardDecoration(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        example['icon'] as String,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          languageService.translate(example['title'] as String),
                          style: AppTheme.caption.copyWith(
                            color: _getCardTextColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
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
    Text(
      languageService.translate('your_books'),
      style: AppTheme.headline.copyWith(
        color: textColor,
        fontSize: 18,
      ),
    ),
    Row(
      children: [
        TextButton.icon(
          onPressed: _showBooksList,
          icon: Icon(Icons.menu_book, size: 18, color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
          label: Text(
            'View All',
            style: TextStyle(color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _themeMode == AppThemeMode.gradient ? Colors.white : const Color(0xFF6C5CE7),
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _createNewBook,
          icon: Icon(Icons.add_circle_outline, size: 18, color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
          label: Text(
            languageService.translate('create_new'),
            style: TextStyle(color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _themeMode == AppThemeMode.gradient ? Colors.white : const Color(0xFF6C5CE7),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    final librariesAsync = ref.watch(userLibrariesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Libraries & Classes',
              style: AppTheme.headline.copyWith(
                color: textColor,
                fontSize: 18,
              ),
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
          foregroundColor: _themeMode == AppThemeMode.gradient ? Colors.white : const Color(0xFF6C5CE7),
        ),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: _showJoinLibraryDialog,
        icon: Icon(Icons.login, size: 18, color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
        label: Text(
          'Join Library',
          style: TextStyle(color: _themeMode == AppThemeMode.gradient ? Colors.white : null),
        ),
        style: TextButton.styleFrom(
          foregroundColor: _themeMode == AppThemeMode.gradient ? Colors.white : const Color(0xFF6C5CE7),
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
          foregroundColor: _themeMode == AppThemeMode.gradient ? Colors.white : const Color(0xFF6C5CE7),
        ),
      ),
    ],
  ),
          ],
        ),
        const SizedBox(height: 12),
        librariesAsync.when(
          data: (libraries) {
            if (libraries.isEmpty) {
              return _buildEmptyLibrariesState(cardColor, textColor, subtitleColor);
            }
            
            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: libraries.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  return _buildLibraryCard(
                    libraries[index],
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.15),
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
              if (library.subject != null) ...[
                Text(
                  library.subject!,
                  style: TextStyle(
                    fontSize: 11,
                    color: _getCardTextColor().withValues(alpha:0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(Icons.book, size: 12, color: _getCardTextColor().withValues(alpha:0.7)),
                  const SizedBox(width: 4),
                  Text('${library.bookCount}', style: TextStyle(fontSize: 11, color: _getCardTextColor().withValues(alpha:0.7))),
                  const SizedBox(width: 12),
                  Icon(Icons.people, size: 12, color: _getCardTextColor().withValues(alpha:0.7)),
                  const SizedBox(width: 4),
                  Text('${library.memberCount}', style: TextStyle(fontSize: 11, color: _getCardTextColor().withValues(alpha:0.7))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    final colors = [Colors.blue, Colors.orange, Colors.teal, Colors.purple, Colors.pink, Colors.green];
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: sheetText),
              title: Text(languageService.translate('edit'), style: AppTheme.body2.copyWith(color: sheetText)),
              onTap: () {
                Navigator.pop(context);
                _editBook(book);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: sheetText),
              title: Text(languageService.translate('duplicate'), style: AppTheme.body2.copyWith(color: sheetText)),
              onTap: () {
                Navigator.pop(context);
                _duplicateBook(book);
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: sheetText),
              title: Text(languageService.translate('share'), style: AppTheme.body2.copyWith(color: sheetText)),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('${languageService.translate('share')} ${book.title}', languageService);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(languageService.translate('delete'), style: AppTheme.body2.copyWith(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteBook(book, languageService);
              },
            ),
          ],
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
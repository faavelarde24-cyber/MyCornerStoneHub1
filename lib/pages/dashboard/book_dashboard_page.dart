// lib/pages/dashboard/book_dashboard_page.dart
import 'package:cornerstone_hub/models/app_theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_theme.dart';
import '../../models/book_models.dart';
import '../../models/book_size_type.dart';
import '../../providers/book_providers.dart';
import '../book_creator/book_creator_page.dart';
import '../book_creator/choose_book_size_page.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/book_3d_widget.dart';
import 'widgets/book_info_panel.dart';
import 'widgets/dashboard_drawer.dart';
import '../../utils/role_redirect.dart';
import '../../providers/auth_providers.dart';



class BookDashboardPage extends ConsumerStatefulWidget {
  const BookDashboardPage({super.key});

  @override
  ConsumerState<BookDashboardPage> createState() => _BookDashboardPageState();
}

class _BookDashboardPageState extends ConsumerState<BookDashboardPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AppThemeMode _themeMode = AppThemeMode.gradient; // Default theme

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.6,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleThemeChange(AppThemeMode newMode) {
    setState(() {
      _themeMode = newMode;
    });
  }

  Color _getBackgroundColor() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return const Color(0xFFF5F5F5);
      case AppThemeMode.dark:
        return const Color(0xFF1A1A2E);
      case AppThemeMode.gradient:
        return const Color(0xFFD4E4F7); // Original soft blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(userBooksProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _getBackgroundColor(),
      endDrawer: DashboardDrawer(
        themeMode: _themeMode,
        onThemeChanged: _handleThemeChange,
      ),
      body: Column(
        children: [
          // Top Navigation Bar
          Builder(
            builder: (context) {
              final authService = ref.read(authServiceProvider);
              
              return FutureBuilder<String?>(
                future: authService.getCurrentUserRole(),
                builder: (context, snapshot) {
                  return DashboardAppBar(
                    onRoleDashboardTap: () async {
                      final role = snapshot.data;
                      if (role != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RoleRedirect.getRoleSpecificDashboard(role),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to load dashboard'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    onNewBookTap: _handleNewBook,
                    onThemeToggle: () {
                      final nextTheme = _themeMode == AppThemeMode.gradient
                          ? AppThemeMode.light
                          : _themeMode == AppThemeMode.light
                              ? AppThemeMode.dark
                              : AppThemeMode.gradient;
                      _handleThemeChange(nextTheme);
                    },
                    onProfileTap: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                    bookCount: booksAsync.maybeWhen(
                      data: (books) => books.length,
                      orElse: () => 0,
                    ),
                    userRole: snapshot.data,
                  );
                },
              );
            },
          ),

          // Book Carousel
          Expanded(
            child: booksAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return _buildEmptyState();
                }

                // Update current book in provider when page changes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_currentIndex < books.length) {
                    ref.read(currentBookIdProvider.notifier).setBookId(
                          books[_currentIndex].id,
                        );
                  }
                });

                return PageView.builder(
                  controller: _pageController,
                  itemCount: books.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    ref.read(currentBookIdProvider.notifier).setBookId(
                          books[index].id,
                        );
                  },
                  itemBuilder: (context, index) {
                    final book = books[index];
                    final isSelected = index == _currentIndex;

  debugPrint('📖 [PageView] Building book at index $index');
  debugPrint('📖 [PageView] Book ID: ${book.id}');
  debugPrint('📖 [PageView] Book ID length: ${book.id.length}');
  debugPrint('📖 [PageView] Book title: ${book.title}');
  debugPrint('📖 [PageView] Page size: ${book.pageSize.width}x${book.pageSize.height}');
  debugPrint('📖 [PageView] Is selected: $isSelected');
                    return Book3DWidget(
                      book: book,
                      isSelected: isSelected,
                      onTap: () {
                        if (!isSelected) {
                          debugPrint('📖 [PageView] Tapped non-selected book, animating to index $index');
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        } else {
                          debugPrint('📖 [PageView] Tapped selected book, opening editor');
                          _handleOpenBook(book);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.darkerText,
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading books',
                      style: AppTheme.headline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: AppTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Info Panel
          booksAsync.maybeWhen(
            data: (books) {
              if (books.isEmpty) return const SizedBox.shrink();
              
              final selectedBook = _currentIndex < books.length
                  ? books[_currentIndex]
                  : null;

              return BookInfoPanel(
                selectedBook: selectedBook,
                onPrevious: _currentIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    : null,
                onNext: _currentIndex < books.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    : null,
                onGridView: _handleGridView,
                onShare: () => _handleShare(selectedBook),
                onPlay: () => _handleOpenBook(selectedBook),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      
      // Floating Search Button (bottom right)
      floatingActionButton: FloatingActionButton(
        onPressed: _handleSearch,
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              size: 60,
              color: AppTheme.darkText.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No books yet',
            style: AppTheme.headline.copyWith(
              color: AppTheme.darkerText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first book to get started',
            style: AppTheme.body2.copyWith(
              color: AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _handleNewBook,
            icon: const Icon(Icons.add),
            label: const Text('Create Book'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBBF24),
              foregroundColor: AppTheme.darkerText,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== ACTION HANDLERS ==========

  void _handleNewBook() async {
    debugPrint('🟢 === _handleNewBook START ===');
    
    // Step 1: Show title/description dialog
    final bookDetails = await showDialog<Map<String, String?>>(
      context: context,
      builder: (dialogContext) => const _CreateBookDialog(),
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

    // Step 2: Show size selection (using THIS context, not dialog context)
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
      
      debugPrint('🟢 === _handleNewBook END (SUCCESS) ===');
    } else {
      debugPrint('❌ Book creation failed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create book. Please check console.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      
      debugPrint('🟢 === _handleNewBook END (FAILED) ===');
    }
  }

  void _handleOpenBook(Book? book) {
    if (book == null) return;
    
    // Navigate to Book Creator/Editor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookCreatorPage(bookId: book.id),
      ),
    );
  }

  void _handleShare(Book? book) {
    if (book == null) return;
    
    // Show share options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.share, color: Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            Text('Share "${book.title}"', style: AppTheme.headline),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share link - Coming Soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Invite Collaborators'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invite collaborators - Coming Soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Generate QR Code'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR Code - Coming Soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
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

  void _handleGridView() {
    // Navigate to grid view of all books
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BooksGridView(themeMode: _themeMode),
      ),
    );
  }

  void _handleSearch() {
    // Show search placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search, color: Color(0xFF3B82F6)),
            SizedBox(width: 12),
            Text('Search Books'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by title, author, or tag...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              enabled: false, // Placeholder - disabled for now
            ),
            const SizedBox(height: 16),
            const Text(
              'Search functionality coming soon!',
              style: TextStyle(color: Colors.grey),
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

// ========== BOOKS GRID VIEW ==========

class _BooksGridView extends ConsumerWidget {
  final AppThemeMode themeMode;

  const _BooksGridView({required this.themeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(userBooksProvider);

    final backgroundColor = themeMode == AppThemeMode.dark
        ? const Color(0xFF1A1A2E)
        : themeMode == AppThemeMode.light
            ? const Color(0xFFF5F5F5)
            : const Color(0xFFD4E4F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('All Books'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.darkerText,
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return const Center(
              child: Text('No books available'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return _GridBookCard(
                book: book,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookCreatorPage(bookId: book.id),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _GridBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _GridBookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: book.theme?.primaryColor ?? Colors.blue[400],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    book.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            // Book Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: AppTheme.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${book.pageCount} pages',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
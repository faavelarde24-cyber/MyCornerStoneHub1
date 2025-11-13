// lib/pages/book/widgets/books_list_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';
import '../../book_creator/book_creator_page.dart';
import '../../../models/app_theme_mode.dart';
import '../../../app_theme.dart';

class BooksListDialog extends ConsumerStatefulWidget {
  final AppThemeMode themeMode;
  final bool isDarkMode;
  
  const BooksListDialog({
    super.key,
    required this.themeMode,
    required this.isDarkMode,
  });

  @override
  ConsumerState<BooksListDialog> createState() => _BooksListDialogState();
}

class _BooksListDialogState extends ConsumerState<BooksListDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> _filterBooks(List<Book> books) {
    if (_searchQuery.isEmpty) return books;
    
    return books.where((book) {
      return book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (book.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  Color _getDialogColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.dark:
        return AppTheme.dark_grey;
      case AppThemeMode.gradient:
        return Colors.white.withValues(alpha: 0.95);
    }
  }

  Color _getTextColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return AppTheme.darkerText;
      case AppThemeMode.dark:
      case AppThemeMode.gradient:
        return widget.themeMode == AppThemeMode.dark ? AppTheme.white : AppTheme.darkerText;
    }
  }

  Color _getSubtitleColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return Colors.grey.shade600;
      case AppThemeMode.dark:
        return AppTheme.white.withValues(alpha: 0.7);
      case AppThemeMode.gradient:
        return Colors.grey.shade700;
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return Colors.orange.shade50;
      case AppThemeMode.dark:
        return Colors.orange.withValues(alpha: 0.2);
      case AppThemeMode.gradient:
        return Colors.orange.shade50;
    }
  }

  Color _getSearchFieldColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return Colors.grey.shade100;
      case AppThemeMode.dark:
        return AppTheme.nearlyBlack;
      case AppThemeMode.gradient:
        return Colors.grey.shade50;
    }
  }

  Color _getCardColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.dark:
        return AppTheme.nearlyBlack;
      case AppThemeMode.gradient:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(userBooksProvider);

    return Dialog(
      backgroundColor: _getDialogColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'My Books',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: _getTextColor()),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: _getSubtitleColor().withValues(alpha: 0.3)),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              style: TextStyle(color: _getTextColor()),
              decoration: InputDecoration(
                hintText: 'Search books...',
                hintStyle: TextStyle(color: _getSubtitleColor()),
                prefixIcon: Icon(Icons.search, color: _getTextColor()),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: _getTextColor()),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: _getSearchFieldColor(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 16),

            // Books List
            Expanded(
              child: booksAsync.when(
                data: (books) {
                  final filteredBooks = _filterBooks(books);
                  
                  if (books.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  if (filteredBooks.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return ListView.builder(
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      return _buildBookCard(filteredBooks[index]);
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: widget.themeMode == AppThemeMode.dark 
                        ? Colors.orange 
                        : const Color(0xFF6C5CE7),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading books: $error',
                        style: TextStyle(color: _getTextColor()),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(userBooksProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 64,
            color: _getSubtitleColor(),
          ),
          const SizedBox(height: 16),
          Text(
            'No books created yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first book to get started',
            style: TextStyle(
              fontSize: 14,
              color: _getSubtitleColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: _getSubtitleColor(),
          ),
          const SizedBox(height: 16),
          Text(
            'No books found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: _getSubtitleColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.pink,
      Colors.green,
    ];
    final colorIndex = int.parse(book.id) % colors.length;
    final color = colors[colorIndex];

    return Card(
      color: _getCardColor(),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookCreatorPage(bookId: book.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Book Cover/Icon
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.7),
                      color.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: book.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          book.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.book, color: Colors.white, size: 24),
                        ),
                      )
                    : const Icon(Icons.book, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              
              // Book Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (book.description != null && book.description!.isNotEmpty) ...[
                      Text(
                        book.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getSubtitleColor(),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      _formatDate(book.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getSubtitleColor(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: _getTextColor()),
                color: _getCardColor(),
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookCreatorPage(bookId: book.id),
                      ),
                    );
                  } else if (value == 'duplicate') {
                    _duplicateBook(book);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(book);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: _getTextColor()),
                        const SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: _getTextColor())),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 18, color: _getTextColor()),
                        const SizedBox(width: 8),
                        Text('Duplicate', style: TextStyle(color: _getTextColor())),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
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

  Future<void> _duplicateBook(Book book) async {
    final bookActions = ref.read(bookActionsProvider);
    final newBook = await bookActions.duplicateBook(book.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newBook != null 
              ? 'Book duplicated successfully' 
              : 'Failed to duplicate book'),
        ),
      );
    }
  }

  void _showDeleteConfirmation(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getDialogColor(),
        title: Text('Delete Book', style: TextStyle(color: _getTextColor())),
        content: Text(
          'Are you sure you want to delete "${book.title}"? This action cannot be undone.',
          style: TextStyle(color: _getTextColor()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _getTextColor())),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final bookActions = ref.read(bookActionsProvider);
              final success = await bookActions.deleteBook(book.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? 'Book deleted successfully' 
                        : 'Failed to delete book'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
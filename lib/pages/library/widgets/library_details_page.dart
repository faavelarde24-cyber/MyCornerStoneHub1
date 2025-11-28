// lib/pages/library/widgets/library_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/library_models.dart';
import '../../../models/book_models.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/book_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../book_view/book_view_page.dart';
import '../../../app_theme.dart';

class LibraryDetailsPage extends ConsumerStatefulWidget {
  final Library library;

  const LibraryDetailsPage({super.key, required this.library});

  @override
  ConsumerState<LibraryDetailsPage> createState() => _LibraryDetailsPageState();
}

class _LibraryDetailsPageState extends ConsumerState<LibraryDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCreator = false;

@override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final authService = ref.read(authServiceProvider);
    
    // ✅ FIXED: Get the database user ID from AppUser
    final currentUserId = authService.currentAppUser?.usersId;
    final libraryCreatorId = int.tryParse(widget.library.creatorId.toString());
    
    debugPrint('🔍 Current User Database ID: $currentUserId');
    debugPrint('🔍 Library Creator ID: $libraryCreatorId');
    debugPrint('🔍 Are they equal? ${currentUserId == libraryCreatorId}');
    
    if (mounted) {
      setState(() {
        _isCreator = currentUserId != null && 
                     libraryCreatorId != null && 
                     currentUserId == libraryCreatorId;
      });
      
      debugPrint('✅ _isCreator set to: $_isCreator');
    }
    
    // Refresh data
    ref.invalidate(libraryMembersProvider(widget.library.id));
    ref.invalidate(libraryBooksProvider(widget.library.id));
  });
}
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddBooksDialog() async {
    final userBooksAsync = ref.read(userBooksProvider);
    
    userBooksAsync.whenData((userBooks) async {
      // Get current library books
      final libraryBooksAsync = ref.read(libraryBooksProvider(widget.library.id));
      
      libraryBooksAsync.whenData((libraryBooks) async {
        final libraryBookIds = libraryBooks.map((lb) => lb.bookId).toSet();
        
        final availableBooks = userBooks.where((book) => 
          !libraryBookIds.contains(book.id)
        ).toList();

        if (!mounted) return;

        if (availableBooks.isEmpty) {
          _showSnackBar('All your books are already in this library', Colors.orange);
          return;
        }

        final selectedBooks = await showDialog<List<Book>>(
          context: context,
          builder: (context) => _AddBooksDialog(books: availableBooks),
        );

        if (selectedBooks != null && selectedBooks.isNotEmpty && mounted) {
          // Show loading
          _showLoadingDialog('Adding books...');
          
          final actions = ref.read(libraryActionsProvider);
          for (var book in selectedBooks) {
            await actions.addBookToLibrary(widget.library.id, book.id);
          }
          
          // Close loading
          if (mounted) Navigator.pop(context);
          
          if (mounted) {
            _showSnackBar(
              'Added ${selectedBooks.length} book(s) to library',
              Colors.green,
            );
          }
        }
      });
    });
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.share, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Share Invite Code')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this code with students to join "${widget.library.name}":',
              style: AppTheme.body1,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.library.inviteCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      fontFamily: 'monospace',
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.library.inviteCode));
                      _showSnackBar('Invite code copied!', Colors.green);
                    },
                    tooltip: 'Copy code',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Students can use this code to join your library',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
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

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message, style: AppTheme.body1),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.library.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (widget.library.subject != null)
            Text(
              widget.library.subject!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
        ],
      ),
      backgroundColor: isDark ? Colors.black.withValues(alpha: 0.3) : null,
      elevation: 0,
      actions: [
        if (_isCreator) ...[
          // Share invite code button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showInviteDialog,
            tooltip: 'Share invite code',
          ),
          // ✅ Add books button in AppBar
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddBooksDialog,
            tooltip: 'Add books',
          ),
        ] else ...[
          // Students just see info
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.library_books, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Text('Library Info'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.library_books, 'Library', widget.library.name),
                      if (widget.library.subject != null)
                        _buildInfoRow(Icons.subject, 'Subject', widget.library.subject!),
                      if (widget.library.description != null)
                        _buildInfoRow(Icons.description, 'Description', widget.library.description!),
                      _buildInfoRow(Icons.book, 'Books', '${widget.library.bookCount}'),
                      _buildInfoRow(Icons.people, 'Members', '${widget.library.memberCount}'),
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
            },
            tooltip: 'Library info',
          ),
        ],
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.book), text: 'Books'),
          Tab(icon: Icon(Icons.people), text: 'Members'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: [
        _buildBooksTab(),
        _buildMembersTab(),
      ],
    ),
    // ✅ ADD THIS: Floating Action Button (only shows on Books tab)
    floatingActionButton: _isCreator && _tabController.index == 0
        ? FloatingActionButton.extended(
            onPressed: _showAddBooksDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Books'),
            backgroundColor: const Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
            elevation: 4,
          )
        : null,
  );
}

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksTab() {
    final booksAsync = ref.watch(libraryBooksProvider(widget.library.id));

    return booksAsync.when(
      data: (books) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(libraryBooksProvider(widget.library.id));
            ref.invalidate(libraryProvider(widget.library.id));
            await ref.read(libraryBooksProvider(widget.library.id).future);
          },
          child: books.isEmpty
              ? _buildEmptyBooksState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    return _buildBookCard(books[index]);
                  },
                ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading books',
              style: AppTheme.subtitle.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTheme.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(libraryBooksProvider(widget.library.id));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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

Widget _buildEmptyBooksState() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.grey.shade800 
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 64,
                    color: isDark 
                        ? Colors.grey.shade600 
                        : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No books yet',
                  style: AppTheme.subtitle.copyWith(
                    color: isDark ? Colors.white : AppTheme.darkerText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isCreator 
                      ? 'Add books to share with your students'
                      : 'Your teacher will add books soon',
                  style: AppTheme.body2.copyWith(
                    color: isDark 
                        ? Colors.grey.shade400 
                        : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                // ✅ IMPORTANT: Show button for creators
                if (_isCreator) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddBooksDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Books'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildBookCard(LibraryBook book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppTheme.dark_grey : Colors.white,
      child: InkWell(
        onTap: () {
          // Anyone can tap to view
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookViewPage(bookId: book.bookId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Book Cover
              Hero(
                tag: 'book_${book.bookId}',
                child: Container(
                  width: 60,
                  height: 85,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: book.bookCoverUrl != null
                          ? [Colors.grey.shade300, Colors.grey.shade200]
                          : [
                              const Color(0xFF6C5CE7).withValues(alpha: 0.7),
                              const Color(0xFF6C5CE7).withValues(alpha: 0.5),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: book.bookCoverUrl != null
                        ? DecorationImage(
                            image: NetworkImage(book.bookCoverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: book.bookCoverUrl == null
                      ? const Icon(
                          Icons.book,
                          size: 32,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              
              // Book Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.bookTitle,
                      style: AppTheme.subtitle.copyWith(
                        color: isDark ? Colors.white : AppTheme.darkerText,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: isDark 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Added ${_formatDate(book.addedAt)}',
                          style: AppTheme.caption.copyWith(
                            color: isDark 
                                ? Colors.grey.shade400 
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              if (_isCreator)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.white : AppTheme.darkerText,
                  ),
                  color: isDark ? AppTheme.dark_grey : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    if (value == 'view') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookViewPage(bookId: book.bookId),
                        ),
                      );
                    } else if (value == 'remove') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange),
                              SizedBox(width: 12),
                              Text('Remove Book'),
                            ],
                          ),
                          content: const Text(
                            'Remove this book from the library? This won\'t delete the book itself.',
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
                              ),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        _showLoadingDialog('Removing book...');
                        
                        final actions = ref.read(libraryActionsProvider);
                        await actions.removeBookFromLibrary(
                          widget.library.id,
                          book.bookId,
                        );
                        
                        if (mounted) {
                          Navigator.pop(context); // Close loading
                          _showSnackBar('Book removed from library', Colors.green);
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 18,
                            color: isDark ? Colors.white : AppTheme.darkerText,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'View Book',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.darkerText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Remove', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    final membersAsync = ref.watch(libraryMembersProvider(widget.library.id));

    return membersAsync.when(
      data: (members) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(libraryMembersProvider(widget.library.id));
            ref.invalidate(libraryProvider(widget.library.id));
            await ref.read(libraryMembersProvider(widget.library.id).future);
          },
          child: members.isEmpty
              ? _buildEmptyMembersState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return _buildMemberCard(members[index]);
                  },
                ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading members',
              style: AppTheme.subtitle.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTheme.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(libraryMembersProvider(widget.library.id));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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

  Widget _buildEmptyMembersState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.grey.shade800 
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 64,
                      color: isDark 
                          ? Colors.grey.shade600 
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No members yet',
                    style: AppTheme.subtitle.copyWith(
                      color: isDark ? Colors.white : AppTheme.darkerText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: AppTheme.caption.copyWith(
                      color: isDark 
                          ? Colors.grey.shade400 
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberCard(LibraryMember member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrentUser = ref.read(authServiceProvider).currentUser?.id == member.userId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppTheme.dark_grey : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF6C5CE7),
              child: Text(
                member.userEmail.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.userName ?? member.userEmail,
                          style: AppTheme.subtitle.copyWith(
                            color: isDark ? Colors.white : AppTheme.darkerText,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'You',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        member.accessLevel == AccessLevel.viewOnly
                            ? Icons.visibility
                            : Icons.edit,
                        size: 14,
                        color: isDark 
                            ? Colors.grey.shade400 
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.accessLevel == AccessLevel.viewOnly 
                            ? 'View Only' 
                            : 'Can Interact',
                        style: AppTheme.caption.copyWith(
                          color: isDark 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            if (member.userId == widget.library.creatorId)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Creator',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else if (_isCreator)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 12),
Text('Remove Member'),
],
),
content: Text(
'Remove ${member.userName ?? member.userEmail} from this library?',
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
),
child: const Text('Remove'),
),
],
),
);
              if (confirmed == true) {
                _showLoadingDialog('Removing member...');
                
                final actions = ref.read(libraryActionsProvider);
                await actions.removeMember(widget.library.id, member.userId);
                
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  _showSnackBar('Member removed', Colors.green);
                }
              }
            },
          ),
      ],
    ),
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
class _AddBooksDialog extends StatefulWidget {
final List<Book> books;
const _AddBooksDialog({required this.books});
@override
State<_AddBooksDialog> createState() => _AddBooksDialogState();
}
class _AddBooksDialogState extends State<_AddBooksDialog> {
final Set<String> _selectedBookIds = {};
String _searchQuery = '';
List<Book> get _filteredBooks {
if (_searchQuery.isEmpty) return widget.books;
return widget.books.where((book) {
return book.title.toLowerCase().contains(_searchQuery.toLowerCase());
}).toList();
}
@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;
return Dialog(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: Container(
    width: 500,
    height: 600,
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
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.library_add,
                color: Color(0xFF6C5CE7),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Add Books to Library',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 16),
        
        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search books...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark 
                ? Colors.grey.shade800 
                : Colors.grey.shade100,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        const SizedBox(height: 16),
        
        // Selected Count
        if (_selectedBookIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_selectedBookIds.length} book(s) selected',
              style: const TextStyle(
                color: Color(0xFF6C5CE7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 12),
        
        // Books List
        Expanded(
          child: _filteredBooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty 
                            ? 'No books available'
                            : 'No books found',
                        style: AppTheme.subtitle.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = _filteredBooks[index];
                    final isSelected = _selectedBookIds.contains(book.id);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected 
                              ? const Color(0xFF6C5CE7)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedBookIds.add(book.id);
                            } else {
                              _selectedBookIds.remove(book.id);
                            }
                          });
                        },
                        title: Text(
                          book.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        secondary: Container(
                          width: 40,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6C5CE7).withValues(alpha: 0.7),
                                const Color(0xFF6C5CE7).withValues(alpha: 0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.book,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        activeColor: const Color(0xFF6C5CE7),
                      ),
                    );
                  },
                ),
        ),
        
        const SizedBox(height: 16),
        
        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _selectedBookIds.isEmpty
                  ? null
                  : () {
                      final selectedBooks = widget.books
                          .where((book) => _selectedBookIds.contains(book.id))
                          .toList();
                      Navigator.pop(context, selectedBooks);
                    },
              icon: const Icon(Icons.add),
              label: Text('Add ${_selectedBookIds.length} book(s)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);
}
}
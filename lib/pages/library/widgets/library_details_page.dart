// lib/pages/library/widgets/library_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/library_models.dart';
import '../../../models/book_models.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/book_providers.dart';
import '../../book_creator/book_creator_page.dart';

class LibraryDetailsPage extends ConsumerStatefulWidget {
  final Library library;

  const LibraryDetailsPage({super.key, required this.library});

  @override
  ConsumerState<LibraryDetailsPage> createState() => _LibraryDetailsPageState();
}

class _LibraryDetailsPageState extends ConsumerState<LibraryDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All your books are already in this library')),
          );
          return;
        }

        final selectedBooks = await showDialog<List<Book>>(
          context: context,
          builder: (context) => _AddBooksDialog(books: availableBooks),
        );

        if (selectedBooks != null && selectedBooks.isNotEmpty && mounted) {
          final actions = ref.read(libraryActionsProvider);
          for (var book in selectedBooks) {
            await actions.addBookToLibrary(widget.library.id, book.id);
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added ${selectedBooks.length} book(s) to library')),
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
        title: const Text('Share Invite Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share this code with students to join "${widget.library.name}":'),
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
                    widget.library.inviteCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.library.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied!')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showInviteDialog,
            tooltip: 'Share invite code',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBooksDialog,
            tooltip: 'Add books',
          ),
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
    );
  }

  Widget _buildBooksTab() {
    final booksAsync = ref.watch(libraryBooksProvider(widget.library.id));

    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No books in this library yet'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showAddBooksDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Books'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (context, index) {
            return _buildBookCard(books[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildBookCard(LibraryBook book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            image: book.bookCoverUrl != null
                ? DecorationImage(
                    image: NetworkImage(book.bookCoverUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: book.bookCoverUrl == null
              ? const Icon(Icons.book, size: 24)
              : null,
        ),
        title: Text(book.bookTitle),
        subtitle: Text('Added ${_formatDate(book.addedAt)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'open') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookCreatorPage(bookId: book.bookId),
                ),
              );
            } else if (value == 'remove') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove Book'),
                  content: const Text('Remove this book from the library?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final actions = ref.read(libraryActionsProvider);
                await actions.removeBookFromLibrary(widget.library.id, book.bookId);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'open', child: Text('Open')),
            const PopupMenuItem(value: 'remove', child: Text('Remove')),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    final membersAsync = ref.watch(libraryMembersProvider(widget.library.id));

    return membersAsync.when(
      data: (members) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            return _buildMemberCard(members[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildMemberCard(LibraryMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(member.userEmail.substring(0, 1).toUpperCase()),
        ),
        title: Text(member.userName ?? member.userEmail),
        subtitle: Text(member.accessLevel == AccessLevel.viewOnly 
            ? 'View Only' 
            : 'Can Interact'),
        trailing: member.userId != widget.library.creatorId
            ? IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove Member'),
                      content: const Text('Remove this member from the library?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    final actions = ref.read(libraryActionsProvider);
                    await actions.removeMember(widget.library.id, member.userId);
                  }
                },
              )
            : const Chip(label: Text('Creator')),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Books to Library'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: ListView.builder(
          itemCount: widget.books.length,
          itemBuilder: (context, index) {
            final book = widget.books[index];
            return CheckboxListTile(
              value: _selectedBookIds.contains(book.id),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedBookIds.add(book.id);
                  } else {
                    _selectedBookIds.remove(book.id);
                  }
                });
              },
              title: Text(book.title),
              secondary: Container(
                width: 40,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.book, size: 20),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedBookIds.isEmpty
              ? null
              : () {
                  final selectedBooks = widget.books
                      .where((book) => _selectedBookIds.contains(book.id))
                      .toList();
                  Navigator.pop(context, selectedBooks);
                },
          child: Text('Add ${_selectedBookIds.length} book(s)'),
        ),
      ],
    );
  }
}
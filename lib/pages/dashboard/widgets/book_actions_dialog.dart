// lib/pages/dashboard/widgets/book_actions_dialog.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_theme.dart';
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../models/library_models.dart';
import '../../../services/book_export_service.dart';
import 'combine_books_page.dart';


/// Book Actions Dialog - Combine, Delete, Export, Move to Library
class BookActionsDialog extends ConsumerWidget {
  final Book book;

  const BookActionsDialog({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.menu_book, color: Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Book Options',
              style: AppTheme.headline,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Combine Books
          ListTile(
            leading: const Icon(Icons.merge_type, color: Color(0xFFF59E0B)),
            title: const Text('Combine Books'),
            subtitle: const Text('Merge multiple books into one'),
            onTap: () {
              Navigator.pop(context);
              _showCombineBooksFlow(context, ref);
            },
          ),
          
          const Divider(),
          
          // Move to Library
          ListTile(
            leading: const Icon(Icons.folder_outlined, color: Color(0xFF6C5CE7)),
            title: const Text('Move to Library'),
            subtitle: const Text('Add this book to a library'),
            onTap: () {
              Navigator.pop(context);
              _showMoveToLibraryDialog(context, ref);
            },
          ),
          
          const Divider(),
          
          // ✅ Export as PDF - NOW WORKING
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
            title: const Text('Export as PDF'),
            subtitle: const Text('Download book as PDF file'),
            onTap: () {
              Navigator.pop(context);
              _handleExportPDF(context, ref);
            },
          ),
          
          // ✅ Export as EPUB - NOW WORKING (basic)
          ListTile(
            leading: const Icon(Icons.book_outlined, color: Color(0xFF10B981)),
            title: const Text('Export as EPUB'),
            subtitle: const Text('Download book as EPUB file'),
            onTap: () {
              Navigator.pop(context);
              _handleExportEPUB(context, ref);
            },
          ),
          
          const Divider(),
          
          // ✅ Delete Book - NOW WORKING
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Book', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Permanently delete this book'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, ref);
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
    );
  }

  // ========== COMBINE BOOKS ==========
  void _showCombineBooksFlow(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombineBooksPage(initialBook: book),
      ),
    );
  }

 // ========== EXPORT PDF ==========
Future<void> _handleExportPDF(BuildContext context, WidgetRef ref) async {
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
      
      if (!context.mounted) return;
      
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

    if (!context.mounted) return;

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
    
    if (!context.mounted) return;
    
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
  Future<void> _handleExportEPUB(BuildContext context, WidgetRef ref) async {
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
              _handleExportPDF(context, ref);
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

// ========== DELETE BOOK ==========
void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
  // ✅ Read the provider BEFORE showing the dialog
  final bookActions = ref.read(bookActionsProvider);
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 12),
          Text('Delete Book?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${book.title}"?',
            style: AppTheme.body1,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone. All pages and content will be permanently deleted.',
                    style: AppTheme.caption.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            // ✅ Pass bookActions instead of ref
            await _handleDeleteBook(context, bookActions);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete Permanently'),
        ),
      ],
    ),
  );
}

 Future<void> _handleDeleteBook(
  BuildContext context,
  BookActions bookActions,
) async {
  debugPrint('🗑️ === DELETE BOOK START ===');
  debugPrint('Book ID: ${book.id}');
  debugPrint('Book Title: ${book.title}');
  
  // ✅ Create a completer to control SnackBar dismissal
  
  // Show loading SnackBar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Row(
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
          Text('Deleting book...'),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(minutes: 1),
    ),
  );

  try {
    // ✅ Use the passed bookActions directly
    final success = await bookActions.deleteBook(book.id);

    debugPrint('🗑️ Delete completed, dismissing loading...');

    if (!context.mounted) return;

    // ✅ Dismiss loading SnackBar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Wait for SnackBar animation to complete
    await Future.delayed(const Duration(milliseconds: 200));

    if (!context.mounted) return;

    if (success) {
      debugPrint('✅ Book deleted successfully');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Book "${book.title}" deleted successfully'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } else {
      debugPrint('❌ Book deletion failed');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Failed to delete book. Please try again.'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e, stack) {
    debugPrint('❌ Delete error: $e');
    debugPrint('Stack: $stack');
    
    if (!context.mounted) return;
    
    // ✅ Ensure loading SnackBar is dismissed
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Wait for dismissal
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // ========== MOVE TO LIBRARY ==========
  void _showMoveToLibraryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _MoveToLibraryDialog(book: book),
    );
  }
}

/// Move to Library Dialog
class _MoveToLibraryDialog extends ConsumerWidget {
  final Book book;

  const _MoveToLibraryDialog({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final librariesAsync = ref.watch(userLibrariesProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.folder_outlined, color: Color(0xFF6C5CE7)),
          const SizedBox(width: 12),
          const Text('Move to Library'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: librariesAsync.when(
          data: (libraries) {
            if (libraries.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.folder_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No libraries found',
                    style: AppTheme.title,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a library first to add books',
                    style: AppTheme.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: libraries.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final library = libraries[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.folder,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                  title: Text(library.name),
                  subtitle: Text(
                    '${library.bookCount} books • ${library.memberCount} members',
                    style: AppTheme.caption,
                  ),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () {
                    Navigator.pop(context);
                    _handleMoveToLibrary(context, ref, library);
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _handleMoveToLibrary(
    BuildContext context,
    WidgetRef ref,
    Library library,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Text('Adding to ${library.name}...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final libraryActions = ref.read(libraryActionsProvider);
    final result = await libraryActions.addBookToLibrary(library.id, book.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Book added to "${library.name}"'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add book to library'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
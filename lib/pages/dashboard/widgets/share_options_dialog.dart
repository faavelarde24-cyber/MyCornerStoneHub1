// lib/pages/dashboard/widgets/share_options_dialog.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';

/// Share Options Dialog - Download & Publish
class ShareOptionsDialog extends ConsumerWidget {
  final Book book;

  const ShareOptionsDialog({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDraft = book.status == BookStatus.draft;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.share_outlined, color: Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          const Text('Share Book'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Download as JSON
          ListTile(
            leading: const Icon(Icons.download, color: Color(0xFF10B981)),
            title: const Text('Download'),
            subtitle: const Text('Download book data as JSON'),
            onTap: () {
              Navigator.pop(context);
              _handleDownload(context, ref);
            },
          ),
          
          const Divider(),
          
          // Publish/Unpublish
          ListTile(
            leading: Icon(
              isDraft ? Icons.publish : Icons.unpublished,
              color: isDraft ? const Color(0xFF6C5CE7) : Colors.orange,
            ),
            title: Text(isDraft ? 'Publish Book' : 'Unpublish Book'),
            subtitle: Text(
              isDraft
                  ? 'Make this book publicly available'
                  : 'Change book back to draft',
            ),
            onTap: () {
              Navigator.pop(context);
              _handlePublishToggle(context, ref, isDraft);
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

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    try {
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
              Text('Preparing download...'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Get book pages
      final pages = await ref.read(bookPagesProvider(book.id).future);

      // Create export data
      final exportData = {
        'book': book.toJson(),
        'pages': pages.map((p) => p.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Book data copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePublishToggle(
    BuildContext context,
    WidgetRef ref,
    bool isCurrentlyDraft,
  ) async {
    final newStatus = isCurrentlyDraft ? BookStatus.published : BookStatus.draft;
    final actionText = isCurrentlyDraft ? 'Publishing' : 'Unpublishing';

    // Show loading
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
            Text('$actionText book...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final bookActions = ref.read(bookActionsProvider);
    final success = await bookActions.updateBook(
      bookId: book.id,
      status: newStatus,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyDraft
                ? 'Book published successfully!'
                : 'Book moved back to draft',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${isCurrentlyDraft ? "publish" : "unpublish"} book'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
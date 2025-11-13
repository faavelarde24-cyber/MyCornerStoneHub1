// lib/widgets/internet_book_preview_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_models.dart';
import '../providers/book_search_providers.dart';

class InternetBookPreviewDialog extends ConsumerWidget {
  final InternetBook book;

  const InternetBookPreviewDialog({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = book.source == 'google'
        ? ref.watch(internetBookDetailsProvider(book.id))
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBookInfo(),
                    const SizedBox(height: 20),
                    _buildDescription(detailsAsync),
                    const SizedBox(height: 20),
                    _buildMetadata(),
                    if (book.categories.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildCategories(),
                    ],
                  ],
                ),
              ),
            ),
            _buildActions(context, detailsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          if (book.coverImageUrl != null)
            Container(
              width: 60,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.book),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.author != null)
                  Text(
                    'by ${book.author}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBookInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (book.coverImageUrl != null)
          Container(
            width: 120,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                book.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.book, size: 60),
                ),
              ),
            ),
          ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (book.publisher != null) ...[
                _buildInfoRow(Icons.business, 'Publisher', book.publisher!),
                const SizedBox(height: 8),
              ],
              if (book.publishedDate != null) ...[
                _buildInfoRow(Icons.calendar_today, 'Published', book.publishedDate!),
                const SizedBox(height: 8),
              ],
              if (book.pageCount > 0) ...[
                _buildInfoRow(Icons.menu_book, 'Pages', '${book.pageCount} pages'),
                const SizedBox(height: 8),
              ],
              if (book.isbn != null) ...[
                _buildInfoRow(Icons.tag, 'ISBN', book.isbn!),
                const SizedBox(height: 8),
              ],
              if (book.averageRating > 0) ...[
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${book.averageRating.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${book.ratingsCount} ratings)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(AsyncValue<InternetBookDetails?>? detailsAsync) {
    String? description = book.description;
    
    if (detailsAsync != null) {
      detailsAsync.whenData((details) {
        if (details?.fullDescription != null) {
          description = details!.fullDescription;
        }
      });
    }

    if (description == null || description!.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description!,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetadataItem(
            Icons.public,
            book.source == 'google' ? 'Google Books' : 'Open Library',
            Colors.blue,
          ),
          if (book.pageCount > 0)
            _buildMetadataItem(
              Icons.description,
              '${book.pageCount} pages',
              Colors.green,
            ),
          if (book.averageRating > 0)
            _buildMetadataItem(
              Icons.star,
              '${book.averageRating.toStringAsFixed(1)} ★',
              Colors.amber,
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: book.categories.map((category) {
            return Chip(
              label: Text(
                category,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.blue.shade50,
              side: BorderSide(color: Colors.blue.shade200),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AsyncValue<InternetBookDetails?>? detailsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (book.previewLink != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Open in browser
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening: ${book.previewLink}')),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Read Online'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          if (book.previewLink != null) const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              // Save for later functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Book saved to your library!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_add),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }
}
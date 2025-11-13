// lib/widgets/book_preview_dialog.dart
import 'package:cornerstone_hub/models/search_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_models.dart';
import '../providers/book_providers.dart';
import '../providers/book_search_providers.dart';

class BookPreviewDialog extends ConsumerStatefulWidget {
  final String bookId;

  const BookPreviewDialog({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<BookPreviewDialog> createState() => _BookPreviewDialogState();
}

class _BookPreviewDialogState extends ConsumerState<BookPreviewDialog> {
  int _currentPageIndex = 0;
  double _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _showRatingForm = false;

  @override
  void initState() {
    super.initState();
    // Record view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchActionsProvider).recordView(widget.bookId);
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookProvider(widget.bookId));
    final pagesAsync = ref.watch(bookPagesProvider);
    final statsAsync = ref.watch(bookStatisticsProvider(widget.bookId));
    final userRatingAsync = ref.watch(bookRatingProvider(widget.bookId));

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
            // Header
            _buildHeader(bookAsync),

            // Book Info & Stats
            _buildBookInfo(bookAsync, statsAsync),

            // Page Preview
            Expanded(
              child: _buildPagePreview(pagesAsync),
            ),

            // Rating Section
            _buildRatingSection(userRatingAsync, statsAsync),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<Book?> bookAsync) {
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
          const Icon(Icons.book, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: bookAsync.when(
              data: (book) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book?.title ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${book?.pageCount ?? 0} pages',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              loading: () => const Text(
                'Loading...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              error: (_, _) => const Text(
                'Error',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
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

  Widget _buildBookInfo(
    AsyncValue<Book?> bookAsync,
    AsyncValue<Map<String, dynamic>?> statsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: bookAsync.when(
        data: (book) {
          if (book == null) return const SizedBox();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (book.description != null) ...[
                Text(
                  book.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Stats
              statsAsync.when(
                data: (stats) {
                  if (stats == null) return const SizedBox();
                  
                  return Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildStatChip(
                        Icons.star,
                        '${(stats['AverageRating'] ?? 0.0).toStringAsFixed(1)} Rating',
                        Colors.amber,
                      ),
                      _buildStatChip(
                        Icons.people,
                        '${stats['TotalRatings'] ?? 0} Ratings',
                        Colors.blue,
                      ),
                      _buildStatChip(
                        Icons.visibility,
                        '${stats['TotalViews'] ?? 0} Views',
                        Colors.green,
                      ),
                      _buildStatChip(
                        Icons.bookmark,
                        '${stats['TotalSaves'] ?? 0} Saves',
                        Colors.orange,
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
              ),
            ],
          );
        },
        loading: () => const SizedBox(),
        error: (_, _) => const SizedBox(),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagePreview(AsyncValue<List<BookPage>> pagesAsync) {
    return Container(
      color: Colors.grey.shade100,
      child: pagesAsync.when(
        data: (pages) {
          if (pages.isEmpty) {
            return const Center(
              child: Text('No pages available'),
            );
          }

          // Limit to first 3 pages for preview
          final previewPages = pages.take(3).toList();
          final currentPage = _currentPageIndex < previewPages.length
              ? previewPages[_currentPageIndex]
              : previewPages.first;

          return Column(
            children: [
              // Page navigation
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPageIndex > 0
                          ? () => setState(() => _currentPageIndex--)
                          : null,
                    ),
                    Text(
                      'Page ${_currentPageIndex + 1} of ${previewPages.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPageIndex < previewPages.length - 1
                          ? () => setState(() => _currentPageIndex++)
                          : null,
                    ),
                  ],
                ),
              ),
              
              // Page content
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                        currentPage.background.color.toARGB32().toRadixString(16),
                        radix: 16,
                      )),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildPageContent(currentPage),
                      ),
                    ),
                  ),
                ),
              ),
              
              if (pages.length > 3)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '+ ${pages.length - 3} more pages',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error loading pages: $error')),
      ),
    );
  }

  Widget _buildPageContent(BookPage page) {
    // Simplified page rendering for preview
    return Stack(
      children: [
        if (page.background.imageUrl != null)
          Positioned.fill(
            child: Image.network(
              page.background.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          ),
        
        ...page.elements.map((element) {
          return Positioned(
            left: element.position.dx * 0.5, // Scale down for preview
            top: element.position.dy * 0.5,
            width: element.size.width * 0.5,
            height: element.size.height * 0.5,
            child: Transform.rotate(
              angle: element.rotation,
              child: _buildElementPreview(element),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildElementPreview(PageElement element) {
    switch (element.type) {
      case ElementType.text:
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            element.properties['text'] ?? '',
            style: element.textStyle?.copyWith(fontSize: 12),
          ),
        );
      case ElementType.image:
        return Image.network(
          element.properties['imageUrl'] ?? '',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildRatingSection(
    AsyncValue<BookRating?> userRatingAsync,
    AsyncValue<Map<String, dynamic>?> statsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Rate this book:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _showRatingForm = !_showRatingForm),
                child: Text(_showRatingForm ? 'Cancel' : 'Write Review'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _userRating ? Icons.star : Icons.star_border,
                  size: 36,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => _userRating = index + 1.0),
              );
            }),
          ),
          
          // Review Form
          if (_showRatingForm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your review (optional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _userRating > 0 ? _submitRating : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Submit Rating'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to full book view or open in creator
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening book...')),
                );
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('Open Full Book'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _saveBook,
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

  Future<void> _submitRating() async {
    if (_userRating == 0) return;

    final actions = ref.read(searchActionsProvider);
    final success = await actions.rateBook(
      bookId: widget.bookId,
      rating: _userRating,
      review: _reviewController.text.trim().isEmpty 
          ? null 
          : _reviewController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your rating!')),
      );
      setState(() {
        _showRatingForm = false;
        _reviewController.clear();
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit rating')),
      );
    }
  }

  Future<void> _saveBook() async {
    final actions = ref.read(searchActionsProvider);
    final success = await actions.saveBook(widget.bookId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book saved successfully!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save book')),
      );
    }
  }
}
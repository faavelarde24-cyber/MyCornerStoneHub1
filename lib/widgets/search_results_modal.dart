// lib/widgets/search_results_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_models.dart';
import '../providers/book_search_providers.dart';
import 'book_preview_dialog.dart';

class SearchResultsModal extends ConsumerStatefulWidget {
  final String query;

  const SearchResultsModal({
    super.key,
    required this.query,
  });

  @override
  ConsumerState<SearchResultsModal> createState() => _SearchResultsModalState();
}

class _SearchResultsModalState extends ConsumerState<SearchResultsModal> {
  String? _authorFilter;
  double? _minRatingFilter;

  @override
  void initState() {
    super.initState();
    // Set initial query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).setQuery(widget.query);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use filteredSearchResultsProvider instead of searchResultsProvider
    final resultsAsync = ref.watch(
      filteredSearchResultsProvider(
        SearchFilter(
          query: widget.query,
          author: _authorFilter,
          minRating: _minRatingFilter,
        ),
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Search Results',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Searching for: "${widget.query}"',
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
            ),

            // Filters
            _buildFilters(),

            // Results
            Expanded(
              child: resultsAsync.when(
                data: (results) {
                  if (results.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return _buildResultsList(results);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
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

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Author Filter
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Filter by author...',
                prefixIcon: const Icon(Icons.person, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _authorFilter = value.isEmpty ? null : value);
              },
            ),
          ),
          const SizedBox(width: 12),
          
          // Rating Filter
          DropdownButton<double?>(
            value: _minRatingFilter,
            hint: const Text('Min Rating'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any Rating')),
              for (var i = 5; i >= 1; i--)
                DropdownMenuItem(
                  value: i.toDouble(),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('$i+'),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              setState(() => _minRatingFilter = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<BookSearchResult> results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildBookCard(results[index]);
      },
    );
  }

  Widget _buildBookCard(BookSearchResult book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookPreview(book),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  image: book.coverImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(book.coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: book.coverImageUrl == null
                    ? const Icon(Icons.book, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Book Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.author != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            book.author!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    
                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < book.averageRating
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${book.averageRating.toStringAsFixed(1)} (${book.totalRatings})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    if (book.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        book.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Actions
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showBookPreview(book),
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('Preview'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            book.isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: book.isSaved ? Colors.orange : Colors.grey,
                          ),
                          onPressed: () => _toggleSaveBook(book),
                          tooltip: book.isSaved ? 'Unsave' : 'Save',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No books found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term or adjust filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookPreview(BookSearchResult book) {
    showDialog(
      context: context,
      builder: (context) => BookPreviewDialog(bookId: book.id),
    );
  }

  Future<void> _toggleSaveBook(BookSearchResult book) async {
    final actions = ref.read(searchActionsProvider);
    
    if (book.isSaved) {
      await actions.unsaveBook(book.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book removed from saved books')),
        );
      }
    } else {
      await actions.saveBook(book.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book saved successfully')),
        );
      }
    }
    
    // Refresh results - use invalidate with the filter
    ref.invalidate(filteredSearchResultsProvider);
  }
}
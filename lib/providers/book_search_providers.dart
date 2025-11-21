// lib/providers/book_search_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../services/book_search_service.dart'; // NEW
import '../models/book_search_models.dart';

final _logger = Logger();

// NEW: Internet Book Search Service Provider


// Service Provider (existing database search)
final bookSearchServiceProvider = Provider<BookSearchService>((ref) {
  return BookSearchService();
});

// Search Query Provider
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  () => SearchQueryNotifier(),
);



// Keep existing providers for database search...
final searchResultsProvider = FutureProvider.autoDispose<List<BookSearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  final searchService = ref.read(bookSearchServiceProvider);
  return await searchService.searchBooks(query: query);
});

// ... rest of existing providers remain the same


final searchSuggestionsProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, query) async {
  if (query.isEmpty || query.length < 2) return [];
  
  final searchService = ref.read(bookSearchServiceProvider);
  return await searchService.getSearchSuggestions(query);
});

final savedBooksProvider = FutureProvider<List<BookSearchResult>>((ref) async {
  final searchService = ref.read(bookSearchServiceProvider);
  return await searchService.getSavedBooks();
});

final bookRatingProvider = FutureProvider.autoDispose
    .family<BookRating?, String>((ref, bookId) async {
  final searchService = ref.read(bookSearchServiceProvider);
  return await searchService.getUserBookRating(bookId);
});

final bookStatisticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, bookId) async {
  final searchService = ref.read(bookSearchServiceProvider);
  return await searchService.getBookStatistics(bookId);
});

final searchActionsProvider = Provider<SearchActions>((ref) {
  return SearchActions(ref);
});

class SearchActions {
  final Ref ref;

  SearchActions(this.ref);

  Future<bool> rateBook({
    required String bookId,
    required double rating,
    String? review,
  }) async {
    try {
      _logger.i('SearchActions: Rating book $bookId with $rating stars');
      final searchService = ref.read(bookSearchServiceProvider);
      
      final result = await searchService.rateBook(
        bookId: bookId,
        rating: rating,
        review: review,
      );
      
      if (result != null) {
        _logger.i('SearchActions: Book rated successfully');
        ref.invalidate(bookRatingProvider(bookId));
        ref.invalidate(bookStatisticsProvider(bookId));
        return true;
      }
      
      _logger.w('SearchActions: Failed to rate book');
      return false;
    } catch (e, stack) {
      _logger.e('SearchActions: Error rating book', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> saveBook(String bookId, {String? note}) async {
    try {
      _logger.i('SearchActions: Saving book $bookId');
      final searchService = ref.read(bookSearchServiceProvider);
      
      final result = await searchService.saveBook(bookId, note: note);
      
      if (result != null) {
        _logger.i('SearchActions: Book saved successfully');
        ref.invalidate(savedBooksProvider);
        return true;
      }
      
      _logger.w('SearchActions: Failed to save book');
      return false;
    } catch (e, stack) {
      _logger.e('SearchActions: Error saving book', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> unsaveBook(String bookId) async {
    try {
      _logger.i('SearchActions: Unsaving book $bookId');
      final searchService = ref.read(bookSearchServiceProvider);
      
      final success = await searchService.unsaveBook(bookId);
      
      if (success) {
        _logger.i('SearchActions: Book unsaved successfully');
        ref.invalidate(savedBooksProvider);
      }
      
      return success;
    } catch (e, stack) {
      _logger.e('SearchActions: Error unsaving book', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> recordView(String bookId) async {
    try {
      final searchService = ref.read(bookSearchServiceProvider);
      await searchService.recordBookView(bookId);
    } catch (e) {
      _logger.e('SearchActions: Error recording view', error: e);
    }
  }

  Future<List<BookSearchResult>> search({
    String? query,
    String? author,
    double? minRating,
  }) async {
    try {
      _logger.i('SearchActions: Searching books - query: $query, author: $author');
      final searchService = ref.read(bookSearchServiceProvider);
      
      return await searchService.searchBooks(
        query: query,
        author: author,
        minRating: minRating,
      );
    } catch (e, stack) {
      _logger.e('SearchActions: Error searching books', error: e, stackTrace: stack);
      return [];
    }
  }
}
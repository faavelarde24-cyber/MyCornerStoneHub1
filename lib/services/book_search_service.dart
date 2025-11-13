// lib/services/book_search_service.dart
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/search_models.dart';
import 'supabase_service.dart';

class BookSearchService {
  final SupabaseClient _client = SupabaseService.client;
  final Logger _logger = Logger();

  /// Search books by title and/or author
  Future<List<BookSearchResult>> searchBooks({
    String? query,
    String? author,
    double? minRating,
    int limit = 50,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      
      // Get user's UsersId if authenticated
      int? usersId;
      if (userId != null) {
        final userResponse = await _client
            .from('Users')
            .select('UsersId')
            .eq('AuthId', userId)
            .maybeSingle();
        
        usersId = userResponse?['UsersId'] as int?;
      }

      // Call the search function
      final response = await _client.rpc(
        'search_books',
        params: {
          'search_query': query,
          'author_filter': author,
          'min_rating': minRating,
          'limit_count': limit,
        },
      );

      final results = <BookSearchResult>[];
      
      for (var json in response as List) {
        final bookId = json['BookId']?.toString() ?? '';
        
        // Check if user has saved this book
        bool isSaved = false;
        if (usersId != null) {
          final savedCheck = await _client
              .from('SavedBooks')
              .select('SavedBookId')
              .eq('BookId', int.parse(bookId))
              .eq('UserId', usersId)
              .maybeSingle();
          
          isSaved = savedCheck != null;
        }

        results.add(BookSearchResult.fromJson(
          json,
          avgRating: (json['AverageRating'] as num?)?.toDouble(),
          ratingsCount: (json['TotalRatings'] as num?)?.toInt(),
          saved: isSaved,
        ));
      }

      _logger.i('Search found ${results.length} books');
      return results;
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error searching books: ${e.message}', 
                error: e, stackTrace: stack);
      return [];
    } catch (e, stack) {
      _logger.e('Error searching books: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get autocomplete suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await _client
          .from('Books')
          .select('Title')
          .eq('Status', 'Published')
          .ilike('Title', '%$query%')
          .limit(5);

      return (response as List)
          .map((json) => json['Title'] as String)
          .toList();
    } catch (e) {
      _logger.e('Error getting suggestions: $e');
      return [];
    }
  }

  /// Get book rating by user
  Future<BookRating?> getUserBookRating(String bookId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final userResponse = await _client
          .from('Users')
          .select('UsersId')
          .eq('AuthId', userId)
          .single();

      final usersId = userResponse['UsersId'] as int;

      final response = await _client
          .from('BookRatings')
          .select()
          .eq('BookId', int.parse(bookId))
          .eq('UserId', usersId)
          .maybeSingle();

      if (response == null) return null;
      return BookRating.fromJson(response);
    } catch (e) {
      _logger.e('Error getting user rating: $e');
      return null;
    }
  }

  /// Rate a book
  Future<BookRating?> rateBook({
    required String bookId,
    required double rating,
    String? review,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _logger.e('No authenticated user');
        return null;
      }

      final userResponse = await _client
          .from('Users')
          .select('UsersId')
          .eq('AuthId', userId)
          .single();

      final usersId = userResponse['UsersId'] as int;

      final ratingData = {
        'BookId': int.parse(bookId),
        'UserId': usersId,
        'Rating': rating,
        'Review': review,
        'LastUpdateUser': userId.toString(),
        'UserCreated': userId.toString(),
      };

      // Upsert (insert or update)
      final response = await _client
          .from('BookRatings')
          .upsert(ratingData)
          .select()
          .single();

      _logger.i('Rating saved successfully');
      return BookRating.fromJson(response);
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error rating book: ${e.message}', 
                error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      _logger.e('Error rating book: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Save a book
  Future<SavedBook?> saveBook(String bookId, {String? note}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final userResponse = await _client
          .from('Users')
          .select('UsersId')
          .eq('AuthId', userId)
          .single();

      final usersId = userResponse['UsersId'] as int;

      final savedData = {
        'BookId': int.parse(bookId),
        'UserId': usersId,
        'Note': note,
      };

      final response = await _client
          .from('SavedBooks')
          .insert(savedData)
          .select()
          .single();

      _logger.i('Book saved successfully');
      return SavedBook.fromJson(response);
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error saving book: ${e.message}', 
                error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      _logger.e('Error saving book: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Unsave a book
  Future<bool> unsaveBook(String bookId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final userResponse = await _client
          .from('Users')
          .select('UsersId')
          .eq('AuthId', userId)
          .single();

      final usersId = userResponse['UsersId'] as int;

      await _client
          .from('SavedBooks')
          .delete()
          .eq('BookId', int.parse(bookId))
          .eq('UserId', usersId);

      _logger.i('Book unsaved successfully');
      return true;
    } catch (e) {
      _logger.e('Error unsaving book: $e');
      return false;
    }
  }

  /// Get user's saved books
  Future<List<BookSearchResult>> getSavedBooks() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client.rpc(
        'get_saved_books',
        params: {'user_auth_id': userId},
      );

      return (response as List).map((json) {
        return BookSearchResult(
          id: json['BookId']?.toString() ?? '',
          title: json['Title'] as String,
          author: json['AuthorName'] as String?,
          coverImageUrl: json['CoverImageUrl'] as String?,
          creatorId: '',
          publishedAt: DateTime.parse(json['SavedAt'] as String),
          isSaved: true,
        );
      }).toList();
    } catch (e) {
      _logger.e('Error getting saved books: $e');
      return [];
    }
  }

  /// Record a book view
  Future<void> recordBookView(String bookId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      int? usersId;

      if (userId != null) {
        final userResponse = await _client
            .from('Users')
            .select('UsersId')
            .eq('AuthId', userId)
            .maybeSingle();
        
        usersId = userResponse?['UsersId'] as int?;
      }

      await _client.from('BookViews').insert({
        'BookId': int.parse(bookId),
        'UserId': usersId,
        'SessionId': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      _logger.i('Book view recorded');
    } catch (e) {
      _logger.e('Error recording view: $e');
    }
  }

  /// Get book statistics
  Future<Map<String, dynamic>?> getBookStatistics(String bookId) async {
    try {
      final response = await _client
          .from('BookStatistics')
          .select()
          .eq('BookId', int.parse(bookId))
          .maybeSingle();

      return response;
    } catch (e) {
      _logger.e('Error getting book statistics: $e');
      return null;
    }
  }
}
// lib/services/internet_book_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/search_models.dart';

class InternetBookSearchService {
  final Logger _logger = Logger();
  
  // Google Books API - Free, 1000 requests per day
  static const String _googleBooksBaseUrl = 'https://www.googleapis.com/books/v1/volumes';
  
  // Open Library API - Free, unlimited
  static const String _openLibraryBaseUrl = 'https://openlibrary.org/search.json';

  /// Search books from Google Books API
  Future<List<InternetBook>> searchGoogleBooks(String query, {int maxResults = 20}) async {
    try {
      _logger.i('Searching Google Books for: $query');
      
      final uri = Uri.parse('$_googleBooksBaseUrl?q=$query&maxResults=$maxResults&printType=books');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        
        final books = items.map((item) {
          return InternetBook.fromGoogleBooks(item);
        }).toList();
        
        _logger.i('Found ${books.length} books from Google Books');
        return books;
      } else {
        _logger.e('Google Books API error: ${response.statusCode}');
        return [];
      }
    } catch (e, stack) {
      _logger.e('Error searching Google Books', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Search books from Open Library API
  Future<List<InternetBook>> searchOpenLibrary(String query, {int limit = 20}) async {
    try {
      _logger.i('Searching Open Library for: $query');
      
      final uri = Uri.parse('$_openLibraryBaseUrl?q=$query&limit=$limit');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final docs = data['docs'] as List? ?? [];
        
        final books = docs.map((doc) {
          return InternetBook.fromOpenLibrary(doc);
        }).toList();
        
        _logger.i('Found ${books.length} books from Open Library');
        return books;
      } else {
        _logger.e('Open Library API error: ${response.statusCode}');
        return [];
      }
    } catch (e, stack) {
      _logger.e('Error searching Open Library', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Combined search from both sources
  Future<List<InternetBook>> searchAll(String query) async {
    try {
      // Search both APIs in parallel
      final results = await Future.wait([
        searchGoogleBooks(query, maxResults: 15),
        searchOpenLibrary(query, limit: 15),
      ]);

      // Combine results
      final allBooks = <InternetBook>[...results[0], ...results[1]];
      
      // Remove duplicates based on ISBN or title
      final uniqueBooks = <String, InternetBook>{};
      for (var book in allBooks) {
        final key = book.isbn ?? book.title.toLowerCase();
        if (!uniqueBooks.containsKey(key)) {
          uniqueBooks[key] = book;
        }
      }
      
      final finalList = uniqueBooks.values.toList();
      
      // Sort by relevance (books with more info first)
      finalList.sort((a, b) {
        final aScore = _calculateRelevanceScore(a);
        final bScore = _calculateRelevanceScore(b);
        return bScore.compareTo(aScore);
      });
      
      _logger.i('Combined search found ${finalList.length} unique books');
      return finalList.take(30).toList();
    } catch (e, stack) {
      _logger.e('Error in combined search', error: e, stackTrace: stack);
      return [];
    }
  }

  int _calculateRelevanceScore(InternetBook book) {
    int score = 0;
    if (book.coverImageUrl != null) score += 3;
    if (book.author != null) score += 2;
    if (book.description != null && book.description!.length > 50) score += 2;
    if (book.pageCount > 0) score += 1;
    if (book.averageRating > 0) score += 2;
    if (book.isbn != null) score += 1;
    return score;
  }

  /// Get book details from Google Books
  Future<InternetBookDetails?> getGoogleBookDetails(String bookId) async {
    try {
      final uri = Uri.parse('$_googleBooksBaseUrl/$bookId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return InternetBookDetails.fromGoogleBooks(data);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting book details', error: e);
      return null;
    }
  }

  /// Get autocomplete suggestions
  Future<List<String>> getAutocompleteSuggestions(String query) async {
    if (query.length < 2) return [];
    
    try {
      // Use Google Books for suggestions
      final uri = Uri.parse('$_googleBooksBaseUrl?q=$query&maxResults=5&printType=books');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        
        return items.map((item) {
          final volumeInfo = item['volumeInfo'] as Map<String, dynamic>;
          return volumeInfo['title'] as String? ?? '';
        }).where((title) => title.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      _logger.e('Error getting suggestions', error: e);
      return [];
    }
  }
}
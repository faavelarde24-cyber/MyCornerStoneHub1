// lib/services/book_service.dart
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_models.dart';
import 'supabase_service.dart';
import '../models/book_size_type.dart';

class BookService {
  final SupabaseClient _client = SupabaseService.client;
  final Logger _logger = Logger();

  /// Create a new book
Future<Book?> createBook({
  required String title,
  String? description,
  String? coverImageUrl,
  PageSize? pageSize,
  BookTheme? theme,
  BookSizeType? sizeType,
}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _logger.e('No authenticated user found');
        throw Exception('No authenticated user found');
      }

      _logger.i('Creating book for user: $userId');

      // Get the UsersId from the Users table using AuthId
      final userResponse = await _client
          .from('Users')
          .select('UsersId')
          .eq('AuthId', userId)
          .single();

      _logger.i('User response: $userResponse');

      final usersId = userResponse['UsersId'] as int;
      _logger.i('Found UsersId: $usersId');

      final bookData = {
        'Title': title,
        'Description': description,
        'CoverImageUrl': coverImageUrl,
        'CreatorId': usersId,
        'Status': 'Draft', // CHANGED: Capitalized to match DB constraint
        'PageSize': (pageSize ?? (sizeType != null 
        ? PageSize(width: sizeType.width, height: sizeType.height, orientation: sizeType.name)
        : PageSize(width: 800, height: 600))).toJson(),
        'Theme': theme?.toJson(),
        'Settings': BookSettings().toJson(),
        'PageCount': 0,
        'ViewCount': 0,
        'LastUpdateUser': userId.toString(),
        'UserCreated': userId.toString(),
      };

      final response = await _client
          .from('Books')
          .insert(bookData)
          .select()
          .single();

      _logger.i('Book created successfully: ${response['BookId']}');
      return Book.fromJson(response);
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error creating book: ${e.message}', error: e, stackTrace: stack);
      _logger.e('Error details: ${e.details}');
      _logger.e('Error hint: ${e.hint}');
      throw Exception('Database error: ${e.message}');
    } catch (e, stack) {
      _logger.e('Error creating book: $e', error: e, stackTrace: stack);
      throw Exception('Failed to create book: $e');
    }
  }

  /// Get all books for current user
  Future<List<Book>> getUserBooks() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _logger.e('No authenticated user found');
        return [];
      }

      // Get the UsersId from the Users table
      final userResponse = await _client
          .from('Users')
          .select('UsersId')
          .eq('AuthId', userId)
          .single();

      final usersId = userResponse['UsersId'] as int;

      final response = await _client
          .from('Books')
          .select()
          .eq('CreatorId', usersId)
          .order('LastUpdateDate', ascending: false);

      final books = (response as List)
          .map((json) => Book.fromJson(json))
          .toList();

      _logger.i('Fetched ${books.length} books for user');
      return books;
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error fetching books: ${e.message}', error: e, stackTrace: stack);
      return [];
    } catch (e, stack) {
      _logger.e('Error fetching books: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get a single book by ID
  Future<Book?> getBook(String bookId) async {
    try {
      final response = await _client
          .from('Books')
          .select()
          .eq('BookId', int.parse(bookId))
          .single();

      return Book.fromJson(response);
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error fetching book: ${e.message}', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      _logger.e('Error fetching book: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update book metadata
  Future<Book?> updateBook({
    required String bookId,
    String? title,
    String? description,
    String? coverImageUrl,
    BookStatus? status,
    PageSize? pageSize,
    BookTheme? theme,
    int? pageCount,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _logger.e('No authenticated user found');
        return null;
      }

      final updateData = <String, dynamic>{
        'LastUpdateUser': userId.toString(),
      };

      if (title != null) updateData['Title'] = title;
      if (description != null) updateData['Description'] = description;
      if (coverImageUrl != null) updateData['CoverImageUrl'] = coverImageUrl;
      if (status != null) {
        // Convert enum to capitalized string matching DB constraint
        final statusStr = status.name[0].toUpperCase() + status.name.substring(1);
        updateData['Status'] = statusStr;
      }
      if (pageSize != null) updateData['PageSize'] = pageSize.toJson();
      if (theme != null) updateData['Theme'] = theme.toJson();
      if (pageCount != null) updateData['PageCount'] = pageCount;

      final response = await _client
          .from('Books')
          .update(updateData)
          .eq('BookId', int.parse(bookId))
          .select()
          .single();

      _logger.i('Book updated successfully: $bookId');
      return Book.fromJson(response);
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error updating book: ${e.message}', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      _logger.e('Error updating book: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Delete a book
  Future<bool> deleteBook(String bookId) async {
    try {
      await _client
          .from('Books')
          .delete()
          .eq('BookId', int.parse(bookId));

      _logger.i('Book deleted successfully: $bookId');
      return true;
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error deleting book: ${e.message}', error: e, stackTrace: stack);
      return false;
    } catch (e, stack) {
      _logger.e('Error deleting book: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Duplicate a book
  Future<Book?> duplicateBook(String bookId) async {
    try {
      // Get original book
      final originalBook = await getBook(bookId);
      if (originalBook == null) return null;

      // Create new book with copied data
      final newBook = await createBook(
        title: '${originalBook.title} (Copy)',
        description: originalBook.description,
        pageSize: originalBook.pageSize,
        theme: originalBook.theme,
      );

      if (newBook == null) return null;

      // Copy all pages (we'll implement this in BookPageService)
      _logger.i('Book duplicated: $bookId -> ${newBook.id}');
      return newBook;
    } catch (e, stack) {
      _logger.e('Error duplicating book: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update page count after adding/removing pages
  Future<void> updatePageCount(String bookId, int pageCount) async {
    try {
      await _client
          .from('Books')
          .update({'PageCount': pageCount})
          .eq('BookId', int.parse(bookId));

      _logger.i('Page count updated for book $bookId: $pageCount');
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error updating page count: ${e.message}', error: e, stackTrace: stack);
    } catch (e, stack) {
      _logger.e('Error updating page count: $e', error: e, stackTrace: stack);
    }
  }

  /// Search books by title
  Future<List<Book>> searchBooks(String query) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final userResponse = await _client
          .from('Users')
          .select('UsersId')
          .eq('AuthId', userId)
          .single();

      final usersId = userResponse['UsersId'] as int;

      final response = await _client
          .from('Books')
          .select()
          .eq('CreatorId', usersId)
          .ilike('Title', '%$query%')
          .order('LastUpdateDate', ascending: false);

      return (response as List)
          .map((json) => Book.fromJson(json))
          .toList();
    } catch (e, stack) {
      _logger.e('Error searching books: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get published books (for sharing)
  Future<List<Book>> getPublishedBooks() async {
    try {
      final response = await _client
          .from('Books')
          .select()
          .eq('Status', 'published')
          .order('LastUpdateDate', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => Book.fromJson(json))
          .toList();
    } catch (e, stack) {
      _logger.e('Error fetching published books: $e', error: e, stackTrace: stack);
      return [];
    }
  }
}
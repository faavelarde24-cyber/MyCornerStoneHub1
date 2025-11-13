// lib/services/book_page_service.dart
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_models.dart';
import 'supabase_service.dart';
import 'package:flutter/material.dart';

class BookPageService {
  final SupabaseClient _client = SupabaseService.client;
  final Logger _logger = Logger();

  /// Create a new page
  Future<BookPage?> createPage({
    required String bookId,
    required int pageNumber,
    List<PageElement>? elements,
    PageBackground? background,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _logger.e('No authenticated user found');
        return null;
      }

      final pageData = {
        'BookId': int.parse(bookId),
        'PageNumber': pageNumber,
        'Elements': elements?.map((e) => e.toJson()).toList() ?? [],
        'Background': (background ?? PageBackground(color: const Color(0xFFFFFFFF))).toJson(),
        'LastUpdateUser': userId.toString(),
        'UserCreated': userId.toString(),
      };

      final response = await _client
          .from('BookPages')
          .insert(pageData)
          .select()
          .single();

      _logger.i('Page created successfully: ${response['PageId']}');
      return BookPage.fromJson(response);
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error creating page: ${e.message}', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      _logger.e('Error creating page: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get all pages for a book
  Future<List<BookPage>> getBookPages(String bookId) async {
    try {
      final response = await _client
          .from('BookPages')
          .select()
          .eq('BookId', int.parse(bookId))
          .order('PageNumber', ascending: true);

      final pages = (response as List)
          .map((json) => BookPage.fromJson(json))
          .toList();

      _logger.i('Fetched ${pages.length} pages for book $bookId');
      return pages;
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error fetching pages: ${e.message}', error: e, stackTrace: stack);
      return [];
    } catch (e, stack) {
      _logger.e('Error fetching pages: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get a single page by ID
  Future<BookPage?> getPage(String pageId) async {
    try {
      final response = await _client
          .from('BookPages')
          .select()
          .eq('PageId', int.parse(pageId))
          .single();

      return BookPage.fromJson(response);
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error fetching page: ${e.message}', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      _logger.e('Error fetching page: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update page content
  Future<BookPage?> updatePage({
    required String pageId,
    List<PageElement>? elements,
    PageBackground? background,
    int? pageNumber,
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

      if (elements != null) {
        updateData['Elements'] = elements.map((e) => e.toJson()).toList();
      }
      if (background != null) {
        updateData['Background'] = background.toJson();
      }
      if (pageNumber != null) {
        updateData['PageNumber'] = pageNumber;
      }

      final response = await _client
          .from('BookPages')
          .update(updateData)
          .eq('PageId', int.parse(pageId))
          .select()
          .single();

      _logger.i('Page updated successfully: $pageId');
      return BookPage.fromJson(response);
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error updating page: ${e.message}', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      _logger.e('Error updating page: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Delete a page
  Future<bool> deletePage(String pageId, String bookId) async {
    try {
      // Delete the page
      await _client
          .from('BookPages')
          .delete()
          .eq('PageId', int.parse(pageId));

      // Reorder remaining pages
      await _reorderPages(bookId);

      _logger.i('Page deleted successfully: $pageId');
      return true;
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error deleting page: ${e.message}', error: e, stackTrace: stack);
      return false;
    } catch (e, stack) {
      _logger.e('Error deleting page: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Duplicate a page
  Future<BookPage?> duplicatePage(String pageId, String bookId) async {
    try {
      // Get original page
      final originalPage = await getPage(pageId);
      if (originalPage == null) return null;

      // Get all pages to determine new page number
      final allPages = await getBookPages(bookId);
      final newPageNumber = originalPage.pageNumber + 1;

      // Shift page numbers after the original page
      for (var page in allPages) {
        if (page.pageNumber >= newPageNumber) {
          await updatePage(
            pageId: page.id,
            pageNumber: page.pageNumber + 1,
          );
        }
      }

      // Create new page with copied content
      final newPage = await createPage(
        bookId: bookId,
        pageNumber: newPageNumber,
        elements: originalPage.elements,
        background: originalPage.background,
      );

      _logger.i('Page duplicated: $pageId -> ${newPage?.id}');
      return newPage;
    } catch (e, stack) {
      _logger.e('Error duplicating page: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Reorder pages after deletion
  Future<void> _reorderPages(String bookId) async {
    try {
      final pages = await getBookPages(bookId);
      
      for (int i = 0; i < pages.length; i++) {
        if (pages[i].pageNumber != i + 1) {
          await _client
              .from('BookPages')
              .update({'PageNumber': i + 1})
              .eq('PageId', int.parse(pages[i].id));
        }
      }

      _logger.i('Pages reordered for book $bookId');
    } catch (e, stack) {
      _logger.e('Error reordering pages: $e', error: e, stackTrace: stack);
    }
  }

  /// Move page to new position
  Future<bool> movePage(String pageId, String bookId, int newPosition) async {
    try {
      final pages = await getBookPages(bookId);
      final currentPage = pages.firstWhere((p) => p.id == pageId);
      final oldPosition = currentPage.pageNumber;

      if (oldPosition == newPosition) return true;

      // Update page numbers
      if (newPosition < oldPosition) {
        // Moving up - shift pages down
        for (var page in pages) {
          if (page.pageNumber >= newPosition && page.pageNumber < oldPosition) {
            await updatePage(
              pageId: page.id,
              pageNumber: page.pageNumber + 1,
            );
          }
        }
      } else {
        // Moving down - shift pages up
        for (var page in pages) {
          if (page.pageNumber > oldPosition && page.pageNumber <= newPosition) {
            await updatePage(
              pageId: page.id,
              pageNumber: page.pageNumber - 1,
            );
          }
        }
      }

      // Update the moved page
      await updatePage(
        pageId: pageId,
        pageNumber: newPosition,
      );

      _logger.i('Page moved from $oldPosition to $newPosition');
      return true;
    } catch (e, stack) {
      _logger.e('Error moving page: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Add element to page
  Future<BookPage?> addElement(String pageId, PageElement element) async {
    try {
      final page = await getPage(pageId);
      if (page == null) return null;

      final updatedElements = [...page.elements, element];
      return await updatePage(pageId: pageId, elements: updatedElements);
    } catch (e, stack) {
      _logger.e('Error adding element: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update element on page
/// Update element on page
Future<BookPage?> updateElement(String pageId, PageElement updatedElement) async {
  try {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    // First, get the current page with ALL elements
    final pageResponse = await _client
        .from('BookPages')
        .select()
        .eq('PageId', int.parse(pageId))
        .single();

    final currentPage = BookPage.fromJson(pageResponse);
    
    // Update the specific element in the elements list
    final updatedElements = currentPage.elements.map((element) {
      return element.id == updatedElement.id ? updatedElement : element;
    }).toList();

    // Update the page with the modified elements
    final updateResponse = await _client
        .from('BookPages')
        .update({
          'Elements': updatedElements.map((e) => e.toJson()).toList(),
          'LastUpdateUser': userId.toString(),
        })
        .eq('PageId', int.parse(pageId))
        .select()
        .single();

    _logger.i('Element updated successfully: ${updatedElement.id}');
    _logger.i('New position: ${updatedElement.position}');
    return BookPage.fromJson(updateResponse);
  } catch (e, stack) {
    _logger.e('Error updating element: $e', error: e, stackTrace: stack);
    return null;
  }
}

  /// Remove element from page
  Future<BookPage?> removeElement(String pageId, String elementId) async {
    try {
      final page = await getPage(pageId);
      if (page == null) return null;

      final updatedElements = page.elements
          .where((e) => e.id != elementId)
          .toList();

      return await updatePage(pageId: pageId, elements: updatedElements);
    } catch (e, stack) {
      _logger.e('Error removing element: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update page background
/// Update page background
Future<BookPage?> updatePageBackground(String pageId, PageBackground background) async {
  debugPrint('🟢 === BookPageService.updatePageBackground START ===');
  debugPrint('Page ID: $pageId');
  debugPrint('Background Color: ${background.color}');
  debugPrint('Background Image: ${background.imageUrl}');
  
  try {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('❌ No authenticated user found');
      _logger.e('No authenticated user found');
      return null;
    }
    
    debugPrint('✅ User ID: $userId');

    final backgroundJson = background.toJson();
    debugPrint('📦 Background JSON: $backgroundJson');

    final response = await _client
        .from('BookPages')
        .update({
          'Background': backgroundJson,
          'LastUpdateUser': userId.toString(),
        })
        .eq('PageId', int.parse(pageId))
        .select()
        .single();

    debugPrint('✅ Database response received');
    debugPrint('Response: $response');
    
    _logger.i('Page background updated successfully: $pageId');
    
    final updatedPage = BookPage.fromJson(response);
    debugPrint('✅ Updated page parsed successfully');
    debugPrint('Updated Background Color: ${updatedPage.background.color}');
    debugPrint('Updated Background Image: ${updatedPage.background.imageUrl}');
    debugPrint('🟢 === BookPageService.updatePageBackground END ===');
    
    return updatedPage;
  } on PostgrestException catch (e, stack) {
    debugPrint('❌ Supabase error: ${e.message}');
    debugPrint('Error details: ${e.details}');
    debugPrint('Error hint: ${e.hint}');
    _logger.e('Supabase error updating background: ${e.message}', error: e, stackTrace: stack);
    return null;
  } catch (e, stack) {
    debugPrint('❌ General error: $e');
    _logger.e('Error updating background: $e', error: e, stackTrace: stack);
    return null;
  }
}

}
// lib/providers/book_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/book_models.dart';
import '../services/book_service.dart';
import '../services/book_page_service.dart';
import '../models/book_size_type.dart';

final _logger = Logger();

// Service Providers
final bookServiceProvider = Provider<BookService>((ref) {
  return BookService();
});

final bookPageServiceProvider = Provider<BookPageService>((ref) {
  return BookPageService();
});

// Book List Provider
final userBooksProvider = FutureProvider<List<Book>>((ref) async {
  final bookService = ref.read(bookServiceProvider);
  return await bookService.getUserBooks();
});

// Single Book Provider
final bookProvider = FutureProvider.family<Book?, String>((ref, bookId) async {
  final bookService = ref.read(bookServiceProvider);
  final book = await bookService.getBook(bookId);
  _logger.i('bookProvider loaded book: ${book?.title}');
  return book;
});

// ✅ ENHANCED: Use FutureProvider.family for pages with detailed logging
final bookPagesProvider = FutureProvider.family<List<BookPage>, String>((ref, bookId) async {
  if (bookId.isEmpty) {
    _logger.w('bookPagesProvider: Empty bookId provided');
    return [];
  }
  
try {
    // ✅ Safe book ID for logging
    final bookIdShort = bookId.length <= 8 ? bookId : bookId.substring(0, 8);
    
    final startTime = DateTime.now();
    
    final pageService = ref.read(bookPageServiceProvider);
    
    final queryStartTime = DateTime.now();
    final pages = await pageService.getBookPages(bookId);
    final queryEndTime = DateTime.now();
    final queryDuration = queryEndTime.difference(queryStartTime).inMilliseconds;
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;
    
    debugPrint('📚 [PagesProvider] ✅ Pages fetched: ${pages.length} pages in ${duration}ms (query: ${queryDuration}ms)');
    _logger.i('bookPagesProvider loaded ${pages.length} pages for book $bookId in ${duration}ms');
    
    if (pages.isNotEmpty) {
      debugPrint('📊 === FIRST PAGE DETAILS ===');
      debugPrint('  - Page ID: ${pages.first.id}');
      debugPrint('  - Page Number: ${pages.first.pageNumber}');
      debugPrint('  - Background Color: ${pages.first.background.color}');
      debugPrint('  - Background Color Hex: ${pages.first.background.color.toARGB32().toRadixString(16)}');
      debugPrint('  - Background Image URL: ${pages.first.background.imageUrl ?? "NONE"}');
      debugPrint('  - Image URL Length: ${pages.first.background.imageUrl?.length ?? 0}');
      debugPrint('  - Elements Count: ${pages.first.elements.length}');
      
      // Check if image URL is valid
      if (pages.first.background.imageUrl != null && pages.first.background.imageUrl!.isNotEmpty) {
        final url = pages.first.background.imageUrl!;
        final urlPreview = url.length > 100 ? '${url.substring(0, 100)}...' : url;
        debugPrint('  - Image URL: $urlPreview');
        debugPrint('  - Is valid URL: ${url.startsWith('http://') || url.startsWith('https://')}');
      }
      
      debugPrint('═════════════════════════════════════');
    } else {
      debugPrint('📚 [PagesProvider] ⚠️ No pages found for this book');
    }
    
    debugPrint('📚 [PagesProvider-$bookIdShort] === END FETCHING PAGES ===\n');
    return pages;
} catch (e, stack) {
    final bookIdShort = bookId.length <= 8 ? bookId : bookId.substring(0, 8);
    debugPrint('📚 [PagesProvider-$bookIdShort] ❌ ERROR: $e');
    debugPrint('📚 [PagesProvider] Stack: $stack');
    _logger.e('bookPagesProvider error loading pages: $e', error: e, stackTrace: stack);
    rethrow;
  }
});

// Current Book ID Notifier
class CurrentBookIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void setBookId(String? id) => state = id;
}

final currentBookIdProvider = NotifierProvider<CurrentBookIdNotifier, String?>(
  () => CurrentBookIdNotifier(),
);

final currentBookProvider = Provider<AsyncValue<Book?>>((ref) {
  final bookId = ref.watch(currentBookIdProvider);
  if (bookId == null) return const AsyncValue.data(null);
  return ref.watch(bookProvider(bookId));
});

// Current Page Index Notifier
class CurrentPageIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void setPageIndex(int index) => state = index;
}

final currentPageIndexProvider = NotifierProvider<CurrentPageIndexNotifier, int>(
  () => CurrentPageIndexNotifier(),
);

final currentPageProvider = Provider<BookPage?>((ref) {
  final bookId = ref.watch(currentBookIdProvider);
  if (bookId == null) return null;

  final pagesAsync = ref.watch(bookPagesProvider(bookId));
  final pageIndex = ref.watch(currentPageIndexProvider);

  return pagesAsync.when(
    data: (pages) => pages.isNotEmpty && pageIndex < pages.length 
        ? pages[pageIndex] 
        : null,
    loading: () => null,
    error: (_, _) => null,
  );
});

// Book Actions Provider
final bookActionsProvider = Provider<BookActions>((ref) {
  return BookActions(ref);
});

class BookActions {
  final Ref ref;

  BookActions(this.ref);

  Future<Book?> createBook({
    required String title,
    String? description,
    BookSizeType? sizeType,
  }) async {
    try {
      debugPrint('🟢 === BookActions.createBook START ===');
      debugPrint('Title: $title');
      debugPrint('Size Type: ${sizeType?.label ?? "default"}');
      
      _logger.i('BookActions: Creating book "$title" with size: ${sizeType?.label ?? "default"}');
      final service = ref.read(bookServiceProvider);
      final pageService = ref.read(bookPageServiceProvider);
      
      debugPrint('📚 Calling BookService.createBook...');
      final book = await service.createBook(
        title: title,
        description: description,
        sizeType: sizeType,
      );
      
      if (book == null) {
        debugPrint('❌ Book creation failed - service returned null');
        _logger.e('BookActions: Failed to create book');
        return null;
      }
      
      debugPrint('✅ Book created: ${book.id}');
      debugPrint('📏 Book page size: ${book.pageSize.width}x${book.pageSize.height}');
      
      debugPrint('📄 Creating first page...');
      final firstPage = await pageService.createPage(
        bookId: book.id,
        pageNumber: 1,
        pageSize: book.pageSize,
      );
      
      if (firstPage != null) {
        debugPrint('✅ First page created: ${firstPage.id}');
        await service.updatePageCount(book.id, 1);
        
        final updatedBook = Book(
          id: book.id,
          title: book.title,
          description: book.description,
          coverImageUrl: book.coverImageUrl,
          creatorId: book.creatorId,
          status: book.status,
          pageSize: book.pageSize,
          theme: book.theme,
          settings: book.settings,
          collaborators: book.collaborators,
          pageCount: 1,
          viewCount: book.viewCount,
          createdAt: book.createdAt,
          updatedAt: DateTime.now(),
        );
        
        ref.invalidate(userBooksProvider);
        ref.invalidate(bookPagesProvider(book.id));
        
        debugPrint('🟢 === BookActions.createBook END (SUCCESS) ===');
        return updatedBook;
      } else {
        debugPrint('❌ First page creation failed');
        return book;
      }
    } catch (e, stack) {
      debugPrint('❌ BookActions.createBook ERROR: $e');
      _logger.e('BookActions: Error creating book', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<bool> updateBook({
    required String bookId,
    String? title,
    String? description,
    BookStatus? status,
  }) async {
    try {
      _logger.i('BookActions: Updating book $bookId');
      final service = ref.read(bookServiceProvider);
      final updated = await service.updateBook(
        bookId: bookId,
        title: title,
        description: description,
        status: status,
      );
      
      if (updated != null) {
        _logger.i('BookActions: Book updated successfully');
        ref.invalidate(bookProvider(bookId));
        ref.invalidate(userBooksProvider);
        return true;
      }
      
      _logger.w('BookActions: Failed to update book');
      return false;
    } catch (e, stack) {
      _logger.e('BookActions: Error updating book', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      _logger.i('BookActions: Deleting book $bookId');
      final service = ref.read(bookServiceProvider);
      final success = await service.deleteBook(bookId);
      
      if (success) {
        _logger.i('BookActions: Book deleted successfully');
        ref.invalidate(userBooksProvider);
        ref.invalidate(bookPagesProvider(bookId));
        final currentId = ref.read(currentBookIdProvider);
        if (currentId == bookId) {
          ref.read(currentBookIdProvider.notifier).setBookId(null);
        }
      }
      
      return success;
    } catch (e, stack) {
      _logger.e('BookActions: Error deleting book', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<Book?> duplicateBook(String bookId) async {
    try {
      _logger.i('BookActions: Duplicating book $bookId');
      final service = ref.read(bookServiceProvider);
      final pageService = ref.read(bookPageServiceProvider);
      
      final newBook = await service.duplicateBook(bookId);
      if (newBook == null) {
        _logger.e('BookActions: Failed to duplicate book');
        return null;
      }
      
      _logger.i('BookActions: New book created ${newBook.id}, copying pages...');
      
      final originalPages = await pageService.getBookPages(bookId);
      for (var page in originalPages) {
        await pageService.createPage(
          bookId: newBook.id,
          pageNumber: page.pageNumber,
          elements: page.elements,
          background: page.background,
          pageSize: page.pageSize,
        );
      }
      
      await service.updatePageCount(newBook.id, originalPages.length);
      
      _logger.i('BookActions: Book duplicated successfully with ${originalPages.length} pages');
      ref.invalidate(userBooksProvider);
      ref.invalidate(bookPagesProvider(newBook.id));
      return newBook;
    } catch (e, stack) {
      _logger.e('BookActions: Error duplicating book', error: e, stackTrace: stack);
      return null;
    }
  }
}

// Page Actions Provider
final pageActionsProvider = Provider<PageActions>((ref) {
  return PageActions(ref);
});

class PageActions {
  final Ref ref;

  PageActions(this.ref);

  Future<BookPage?> addPage(String bookId) async {
    try {
      _logger.i('PageActions: Adding page to book $bookId');
      final pageService = ref.read(bookPageServiceProvider);
      final bookService = ref.read(bookServiceProvider);
      
      final book = await bookService.getBook(bookId);
      if (book == null) {
        _logger.e('PageActions: Book not found');
        return null;
      }
      
      final pages = await pageService.getBookPages(bookId);
      final newPageNumber = pages.length + 1;
      
      _logger.i('PageActions: Creating page $newPageNumber');
      
      final newPage = await pageService.createPage(
        bookId: bookId,
        pageNumber: newPageNumber,
        pageSize: book.pageSize,
      );
      
      if (newPage != null) {
        _logger.i('PageActions: Page created successfully - ${newPage.id}');
        await bookService.updatePageCount(bookId, newPageNumber);
        
        // Invalidate to force refresh
        ref.invalidate(bookPagesProvider(bookId));
        ref.invalidate(bookProvider(bookId));
        
        ref.read(currentPageIndexProvider.notifier).setPageIndex(newPageNumber - 1);
      } else {
        _logger.e('PageActions: Failed to create page');
      }
      
      return newPage;
    } catch (e, stack) {
      _logger.e('PageActions: Error adding page', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<bool> deletePage(String pageId, String bookId) async {
    try {
      _logger.i('PageActions: Deleting page $pageId from book $bookId');
      final pageService = ref.read(bookPageServiceProvider);
      final bookService = ref.read(bookServiceProvider);
      
      final success = await pageService.deletePage(pageId, bookId);
      
      if (success) {
        _logger.i('PageActions: Page deleted successfully');
        
        final pages = await pageService.getBookPages(bookId);
        await bookService.updatePageCount(bookId, pages.length);
        
        ref.invalidate(bookPagesProvider(bookId));
        ref.invalidate(bookProvider(bookId));
        
        final currentIndex = ref.read(currentPageIndexProvider);
        if (currentIndex >= pages.length && pages.isNotEmpty) {
          ref.read(currentPageIndexProvider.notifier).setPageIndex(pages.length - 1);
        }
      }
      
      return success;
    } catch (e, stack) {
      _logger.e('PageActions: Error deleting page', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<BookPage?> duplicatePage(String pageId, String bookId) async {
    try {
      _logger.i('PageActions: Duplicating page $pageId');
      final pageService = ref.read(bookPageServiceProvider);
      final bookService = ref.read(bookServiceProvider);
      
      final newPage = await pageService.duplicatePage(pageId, bookId);
      
      if (newPage != null) {
        _logger.i('PageActions: Page duplicated successfully - ${newPage.id}');
        
        final pages = await pageService.getBookPages(bookId);
        await bookService.updatePageCount(bookId, pages.length);
        
        ref.invalidate(bookPagesProvider(bookId));
        ref.invalidate(bookProvider(bookId));
      }
      
      return newPage;
    } catch (e, stack) {
      _logger.e('PageActions: Error duplicating page', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<bool> addElement(String pageId, PageElement element) async {
    try {
      _logger.i('PageActions: Adding element ${element.type} to page $pageId');
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return false;

      final pageService = ref.read(bookPageServiceProvider);
      final result = await pageService.addElement(pageId, element);
      
      if (result != null) {
        ref.invalidate(bookPagesProvider(bookId));
        _logger.i('PageActions: Element added successfully');
        return true;
      }
      return false;
    } catch (e, stack) {
      _logger.e('PageActions: Error adding element', error: e, stackTrace: stack);
      return false;
    }
  }

Future<bool> updateElement(String pageId, PageElement element) async {
  try {
    debugPrint('🔵 === PageActions.updateElement CALLED ===');
    debugPrint('Page ID: $pageId');
    debugPrint('Element ID: ${element.id}');
    debugPrint('Element Type: ${element.type}');
    
    if (element.type == ElementType.text) {
      debugPrint('📝 TEXT Element Update:');
      debugPrint('   Text: ${element.properties['text']}');
      debugPrint('   FontSize: ${element.textStyle?.fontSize}');
      debugPrint('   FontFamily: ${element.textStyle?.fontFamily}');
    }
    
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) {
      debugPrint('❌ No bookId found!');
      return false;
    }
    debugPrint('✅ Book ID: $bookId');

    final pageService = ref.read(bookPageServiceProvider);
    debugPrint('💾 Calling pageService.updateElement...');
    
    final result = await pageService.updateElement(pageId, element);
    
    if (result != null) {
      debugPrint('✅ Database update successful');
      
      // 🚀 OPTIMIZATION: Don't invalidate immediately
      // Let the calling code handle invalidation timing
      
      _logger.i('PageActions: Element updated successfully');
      debugPrint('🔵 === PageActions.updateElement END (SUCCESS) ===');
      return true;
    }
    
    debugPrint('❌ pageService.updateElement returned null');
    return false;
  } catch (e, stack) {
    debugPrint('❌ ERROR in PageActions.updateElement: $e');
    _logger.e('PageActions: Error updating element', error: e, stackTrace: stack);
    return false;
  }
}
  Future<bool> removeElement(String pageId, String elementId) async {
    try {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return false;

      final pageService = ref.read(bookPageServiceProvider);
      final result = await pageService.removeElement(pageId, elementId);
      
      if (result != null) {
        ref.invalidate(bookPagesProvider(bookId));
        _logger.i('PageActions: Element removed successfully');
        return true;
      }
      return false;
    } catch (e, stack) {
      _logger.e('PageActions: Error removing element', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> updatePageBackground(String pageId, PageBackground background) async {
    try {
      _logger.i('PageActions: Updating background for page $pageId');
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return false;

      final pageService = ref.read(bookPageServiceProvider);
      final result = await pageService.updatePageBackground(pageId, background);
      
      if (result != null) {
        ref.invalidate(bookPagesProvider(bookId));
        _logger.i('PageActions: Background updated successfully');
        return true;
      }
      return false;
    } catch (e, stack) {
      _logger.e('PageActions: Error updating background', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> reorderElements(String pageId, List<PageElement> newOrder) async {
    try {
      _logger.i('PageActions: Reordering ${newOrder.length} elements on page $pageId');
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return false;

      final pageService = ref.read(bookPageServiceProvider);
      final success = await pageService.updatePageElements(pageId, newOrder);
      
      if (success) {
        ref.invalidate(bookPagesProvider(bookId));
        _logger.i('PageActions: Elements reordered successfully');
        return true;
      }
      return false;
    } catch (e, stack) {
      _logger.e('PageActions: Error reordering elements', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> toggleElementLock(String pageId, String elementId) async {
    try {
      _logger.i('PageActions: Toggling lock for element $elementId');
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return false;

      final pageService = ref.read(bookPageServiceProvider);
      
      // Get current page
      final pagesAsync = ref.read(bookPagesProvider(bookId));
      await pagesAsync.when(
        data: (pages) async {
          final page = pages.firstWhere((p) => p.id == pageId);
          final element = page.elements.firstWhere((e) => e.id == elementId);
          
          final updatedElement = PageElement(
            id: element.id,
            type: element.type,
            position: element.position,
            size: element.size,
            rotation: element.rotation,
            properties: element.properties,
            textStyle: element.textStyle,
            textAlign: element.textAlign,
            lineHeight: element.lineHeight,
            shadows: element.shadows,
            locked: !element.locked,
          );
          
          await pageService.updateElement(pageId, updatedElement);
          ref.invalidate(bookPagesProvider(bookId));
          _logger.i('PageActions: Element lock toggled successfully');
        },
        loading: () {},
        error: (_, _) {},
      );
      
      return true;
    } catch (e, stack) {
      _logger.e('PageActions: Error toggling element lock', error: e, stackTrace: stack);
      return false;
    }
  }

// Add this method to the PageActions class in book_providers.dart
Future<bool> reorderPages(String bookId, List<BookPage> updatedPages) async {
  try {
    _logger.i('PageActions: Reordering ${updatedPages.length} pages for book $bookId');
    final pageService = ref.read(bookPageServiceProvider);
    final bookService = ref.read(bookServiceProvider);
    
    bool allUpdatesSuccessful = true;
    
    // Update each page with new page numbers
    for (int i = 0; i < updatedPages.length; i++) {
      final page = updatedPages[i];
      final newPageNumber = i + 1;
      
      // Only update if the page number has changed
      if (page.pageNumber != newPageNumber) {
        final updatedPage = await pageService.updatePage(
          pageId: page.id,
          pageNumber: newPageNumber,
          // Keep existing elements and background
          elements: page.elements,
          background: page.background,
        );
        
        if (updatedPage == null) {
          _logger.e('PageActions: Failed to update page ${page.id} to page number $newPageNumber');
          allUpdatesSuccessful = false;
        } else {
          _logger.i('PageActions: Updated page ${page.id} to page number $newPageNumber');
        }
      }
    }
    
    // Update page count (in case it changed during reordering)
    await bookService.updatePageCount(bookId, updatedPages.length);
    
    // Invalidate to force refresh
    ref.invalidate(bookPagesProvider(bookId));
    ref.invalidate(bookProvider(bookId));
    
    if (allUpdatesSuccessful) {
      _logger.i('PageActions: Pages reordered successfully');
    } else {
      _logger.w('PageActions: Some pages failed to update during reorder');
    }
    
    return allUpdatesSuccessful;
  } catch (e, stack) {
    _logger.e('PageActions: Error reordering pages', error: e, stackTrace: stack);
    return false;
  }
}
}
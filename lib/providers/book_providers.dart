// lib/providers/book_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/book_models.dart';
import '../services/book_service.dart';
import '../services/book_page_service.dart';

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

// Book Pages StateNotifier (REPLACED FutureProvider)
class BookPagesNotifier extends Notifier<AsyncValue<List<BookPage>>> {
  String get bookId => ref.read(currentBookIdProvider) ?? '';

  @override
  AsyncValue<List<BookPage>> build() {
    _loadPages();
    return const AsyncValue.loading();
  }

  Future<void> _loadPages() async {
    state = const AsyncValue.loading();
    try {
      final pageService = ref.read(bookPageServiceProvider);
      final pages = await pageService.getBookPages(bookId);
      state = AsyncValue.data(pages);
      _logger.i('BookPagesNotifier loaded ${pages.length} pages for book $bookId');
    } catch (e, stack) {
      _logger.e('BookPagesNotifier error loading pages: $e', error: e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadPages();
  }

  Future<void> updateElementInPage(String pageId, PageElement updatedElement) async {
    final currentState = state;
    if (currentState is! AsyncData) return;

    final pages = currentState.value;
    final updatedPages = pages?.map((page) {
      if (page.id == pageId) {
        final updatedElements = page.elements.map((element) {
          return element.id == updatedElement.id ? updatedElement : element;
        }).toList();
        
        return BookPage(
          id: page.id,
          bookId: page.bookId,
          pageNumber: page.pageNumber,
          elements: updatedElements,
          background: page.background,
          layout: page.layout,
          pageSize: page.pageSize,
          template: page.template,
          createdAt: page.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return page;
    }).toList();

    // Update local state immediately for instant UI response
    state = AsyncValue.data(updatedPages!);
    _logger.i('BookPagesNotifier: Element ${updatedElement.id} updated locally to position ${updatedElement.position}');

    // Update database in background (fire and forget)
    _updateDatabase(pageId, updatedElement);
  }

  Future<void> _updateDatabase(String pageId, PageElement updatedElement) async {
    try {
      final pageService = ref.read(bookPageServiceProvider);
      final result = await pageService.updateElement(pageId, updatedElement);
      
      if (result != null) {
        _logger.i('BookPagesNotifier: Element ${updatedElement.id} successfully saved to database');
      } else {
        _logger.e('BookPagesNotifier: Failed to save element ${updatedElement.id} to database');
      }
    } catch (e, stack) {
      _logger.e('BookPagesNotifier: Database update error for element ${updatedElement.id}: $e', error: e, stackTrace: stack);
    }
  }

  Future<void> addElementToPage(String pageId, PageElement newElement) async {
    final currentState = state;
    if (currentState is! AsyncData) return;

    final pages = currentState.value;
    final updatedPages = pages?.map((page) {
      if (page.id == pageId) {
        final updatedElements = [...page.elements, newElement];
        return BookPage(
          id: page.id,
          bookId: page.bookId,
          pageNumber: page.pageNumber,
          elements: updatedElements,
          background: page.background,
          layout: page.layout,
          pageSize: page.pageSize,
          template: page.template,
          createdAt: page.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return page;
    }).toList();

    state = AsyncValue.data(updatedPages!);

    // Update database
    final pageService = ref.read(bookPageServiceProvider);
    await pageService.addElement(pageId, newElement);
  }

  Future<void> removeElementFromPage(String pageId, String elementId) async {
    final currentState = state;
    if (currentState is! AsyncData) return;

    final pages = currentState.value;
    final updatedPages = pages?.map((page) {
      if (page.id == pageId) {
        final updatedElements = page.elements.where((e) => e.id != elementId).toList();
        return BookPage(
          id: page.id,
          bookId: page.bookId,
          pageNumber: page.pageNumber,
          elements: updatedElements,
          background: page.background,
          layout: page.layout,
          pageSize: page.pageSize,
          template: page.template,
          createdAt: page.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return page;
    }).toList();

    state = AsyncValue.data(updatedPages!);

    // Update database
    final pageService = ref.read(bookPageServiceProvider);
    await pageService.removeElement(pageId, elementId);
  }

  Future<void> updatePageBackground(String pageId, PageBackground newBackground) async {
    final currentState = state;
    if (currentState is! AsyncData) return;

    final pages = currentState.value;
    final updatedPages = pages?.map((page) {
      if (page.id == pageId) {
        return BookPage(
          id: page.id,
          bookId: page.bookId,
          pageNumber: page.pageNumber,
          elements: page.elements,
          background: newBackground,
          layout: page.layout,
          pageSize: page.pageSize,
          template: page.template,
          createdAt: page.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return page;
    }).toList();

    state = AsyncValue.data(updatedPages!);
    _logger.i('BookPagesNotifier: Background updated for page $pageId');

    // Update database
    final pageService = ref.read(bookPageServiceProvider);
    await pageService.updatePageBackground(pageId, newBackground);
  }
}

final bookPagesProvider = NotifierProvider<BookPagesNotifier, AsyncValue<List<BookPage>>>(() {
  return BookPagesNotifier();
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

  final pagesAsync = ref.watch(bookPagesProvider);
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
  }) async {
    try {
      _logger.i('BookActions: Creating book "$title"');
      final service = ref.read(bookServiceProvider);
      final book = await service.createBook(
        title: title,
        description: description,
      );
      
      if (book != null) {
        _logger.i('BookActions: Book created successfully - ${book.id}');
        ref.invalidate(userBooksProvider);
      } else {
        _logger.e('BookActions: Failed to create book');
      }
      
      return book;
    } catch (e, stack) {
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
        );
      }
      
      await service.updatePageCount(newBook.id, originalPages.length);
      
      _logger.i('BookActions: Book duplicated successfully with ${originalPages.length} pages');
      ref.invalidate(userBooksProvider);
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
      
      final pages = await pageService.getBookPages(bookId);
      final newPageNumber = pages.length + 1;
      
      _logger.i('PageActions: Creating page $newPageNumber');
      
      final newPage = await pageService.createPage(
        bookId: bookId,
        pageNumber: newPageNumber,
      );
      
      if (newPage != null) {
        _logger.i('PageActions: Page created successfully - ${newPage.id}');
        
        await bookService.updatePageCount(bookId, newPageNumber);
        
        // Refresh the book pages state
        ref.read(bookPagesProvider.notifier).refresh();
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
        
        // Refresh the book pages state
        ref.read(bookPagesProvider.notifier).refresh();
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
        
        // Refresh the book pages state
        ref.read(bookPagesProvider.notifier).refresh();
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

      // Use the StateNotifier for immediate UI update
      await ref.read(bookPagesProvider.notifier).addElementToPage(pageId, element);
      _logger.i('PageActions: Element added successfully');
      return true;
    } catch (e, stack) {
      _logger.e('PageActions: Error adding element', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> updateElement(String pageId, PageElement element) async {
    try {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return false;

      // Use the StateNotifier for immediate UI update
      await ref.read(bookPagesProvider.notifier).updateElementInPage(pageId, element);
      _logger.i('PageActions: Element updated successfully');
      return true;
    } catch (e, stack) {
      _logger.e('PageActions: Error updating element', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> removeElement(String pageId, String elementId) async {
    try {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return false;

      // Use the StateNotifier for immediate UI update
      await ref.read(bookPagesProvider.notifier).removeElementFromPage(pageId, elementId);
      _logger.i('PageActions: Element removed successfully');
      return true;
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

      // Use the StateNotifier for immediate UI update
      await ref.read(bookPagesProvider.notifier).updatePageBackground(pageId, background);
      _logger.i('PageActions: Background updated successfully');
      return true;
    } catch (e, stack) {
      _logger.e('PageActions: Error updating background', error: e, stackTrace: stack);
      return false;
    }
  }
}
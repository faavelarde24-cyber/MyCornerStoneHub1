// lib/providers/library_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/library_models.dart';
import '../services/library_service.dart';

final libraryServiceProvider = Provider<LibraryService>((ref) {
  return LibraryService();
});

// Get user's created libraries
final userLibrariesProvider = FutureProvider<List<Library>>((ref) async {
  final service = ref.watch(libraryServiceProvider);
  return await service.getUserLibraries();
});

// Get libraries user has joined (for students)
final joinedLibrariesProvider = FutureProvider<List<Library>>((ref) async {
  final service = ref.watch(libraryServiceProvider);
  return await service.getJoinedLibraries();
});

// Get single library
final libraryProvider = FutureProvider.family<Library?, String>((ref, libraryId) async {
  final service = ref.watch(libraryServiceProvider);
  return await service.getLibrary(libraryId);
});

// Get library members
final libraryMembersProvider = FutureProvider.family<List<LibraryMember>, String>((ref, libraryId) async {
  final service = ref.watch(libraryServiceProvider);
  return await service.getLibraryMembers(libraryId);
});

// Get library books
final libraryBooksProvider = FutureProvider.family<List<LibraryBook>, String>((ref, libraryId) async {
  final service = ref.watch(libraryServiceProvider);
  return await service.getLibraryBooks(libraryId);
});

// Get user's access level for a library
final userAccessLevelProvider = FutureProvider.family<AccessLevel?, String>((ref, libraryId) async {
  final service = ref.watch(libraryServiceProvider);
  return await service.getUserAccessLevel(libraryId);
});

// Library actions provider
final libraryActionsProvider = Provider<LibraryActions>((ref) {
  final service = ref.watch(libraryServiceProvider);
  return LibraryActions(service, ref);
});

class LibraryActions {
  final LibraryService _service;
  final Ref _ref;

  LibraryActions(this._service, this._ref);

  Future<Library?> createLibrary({
    required String name,
    String? description,
    String? subject,
    AccessLevel defaultAccessLevel = AccessLevel.viewOnly,
  }) async {
    final library = await _service.createLibrary(
      name: name,
      description: description,
      subject: subject,
      defaultAccessLevel: defaultAccessLevel,
    );
    
    if (library != null) {
      _ref.invalidate(userLibrariesProvider);
    }
    
    return library;
  }

  Future<Library?> updateLibrary({
    required String libraryId,
    String? name,
    String? description,
    String? subject,
    AccessLevel? defaultAccessLevel,
  }) async {
    final library = await _service.updateLibrary(
      libraryId: libraryId,
      name: name,
      description: description,
      subject: subject,
      defaultAccessLevel: defaultAccessLevel,
    );
    
    if (library != null) {
      _ref.invalidate(userLibrariesProvider);
      _ref.invalidate(libraryProvider(libraryId));
    }
    
    return library;
  }

  Future<bool> deleteLibrary(String libraryId) async {
    final success = await _service.deleteLibrary(libraryId);
    
    if (success) {
      _ref.invalidate(userLibrariesProvider);
    }
    
    return success;
  }

  Future<Library?> joinLibrary(String inviteCode) async {
    final library = await _service.joinLibrary(inviteCode);
    
    if (library != null) {
      _ref.invalidate(joinedLibrariesProvider);
    }
    
    return library;
  }

  Future<LibraryMember?> addMember({
    required String libraryId,
    required String userId,
    required AccessLevel accessLevel,
  }) async {
    final member = await _service.addMember(
      libraryId: libraryId,
      userId: userId,
      accessLevel: accessLevel,
    );
    
    if (member != null) {
      _ref.invalidate(libraryMembersProvider(libraryId));
      _ref.invalidate(libraryProvider(libraryId));
    }
    
    return member;
  }

  Future<bool> removeMember(String libraryId, String userId) async {
    final success = await _service.removeMember(libraryId, userId);
    
    if (success) {
      _ref.invalidate(libraryMembersProvider(libraryId));
      _ref.invalidate(libraryProvider(libraryId));
    }
    
    return success;
  }

  Future<LibraryBook?> addBookToLibrary(String libraryId, String bookId) async {
    final book = await _service.addBookToLibrary(libraryId, bookId);
    
    if (book != null) {
      _ref.invalidate(libraryBooksProvider(libraryId));
      _ref.invalidate(libraryProvider(libraryId));
    }
    
    return book;
  }

  Future<bool> removeBookFromLibrary(String libraryId, String bookId) async {
    final success = await _service.removeBookFromLibrary(libraryId, bookId);
    
    if (success) {
      _ref.invalidate(libraryBooksProvider(libraryId));
      _ref.invalidate(libraryProvider(libraryId));
    }
    
    return success;
  }
}
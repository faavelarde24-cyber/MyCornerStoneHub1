// lib/services/library_service.dart
import 'dart:math';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/library_models.dart';
import 'supabase_service.dart';

class LibraryService {
  final SupabaseClient _client = SupabaseService.client;
  final Logger _logger = Logger();

  /// Generate unique invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Helper method to parse access level from dynamic value
  AccessLevel _parseAccessLevel(dynamic level) {
    if (level == null) return AccessLevel.viewOnly;
    
    try {
      if (level is String) {
        return AccessLevel.values.firstWhere(
          (e) => e.name.toLowerCase() == level.toLowerCase(),
          orElse: () => AccessLevel.viewOnly,
        );
      }
    } catch (e) {
      _logger.w('Error parsing access level: $level');
    }
    return AccessLevel.viewOnly;
  }

  /// Helper method to parse DateTime from dynamic value
  DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    
    try {
      if (date is String) {
        return DateTime.parse(date);
      } else if (date is DateTime) {
        return date;
      }
    } catch (e) {
      _logger.w('Error parsing date: $date');
    }
    return DateTime.now();
  }

  /// Create a new library/class
  Future<Library?> createLibrary({
    required String name,
    String? description,
    String? subject,
    AccessLevel defaultAccessLevel = AccessLevel.viewOnly,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _logger.e('No authenticated user found');
        return null;
      }

      final userResponse = await _client
          .from('Users')
          .select('UsersId, OrganizationId')
          .eq('AuthId', userId)
          .single();

      final usersId = userResponse['UsersId'] as int;
      final orgId = userResponse['OrganizationId'] as int?;

      // Generate unique invite code
      String inviteCode;
      bool isUnique = false;
      int attempts = 0;
      
      do {
        inviteCode = _generateInviteCode();
        final existing = await _client
            .from('Libraries')
            .select('LibraryId')
            .eq('InviteCode', inviteCode)
            .maybeSingle();
        
        isUnique = existing == null;
        attempts++;
      } while (!isUnique && attempts < 10);

      if (!isUnique) {
        _logger.e('Failed to generate unique invite code');
        return null;
      }

      final libraryData = {
        'Name': name,
        'Description': description,
        'Subject': subject,
        'CreatorId': usersId,
        'OrganizationId': orgId,
        'InviteCode': inviteCode,
        'DefaultAccessLevel': defaultAccessLevel.name,
        'BookCount': 0,
        'MemberCount': 0,
        'Status': 'Active',
        'LastUpdateUser': userId.toString(),
        'UserCreated': userId.toString(),
      };

      final response = await _client
          .from('Libraries')
          .insert(libraryData)
          .select()
          .single();

      _logger.i('Library created successfully: ${response['LibraryId']}');

      // Add creator as first member with Owner role
      await _client.from('LibraryMembers').insert({
        'LibraryId': response['LibraryId'],
        'UserId': usersId,
        'AccessLevel': 'interact',
        'Role': 'Owner',
        'LastUpdateUser': userId.toString(),
        'UserCreated': userId.toString(),
      });

      return Library.fromJson(response);
    } on PostgrestException catch (e, stack) {
      _logger.e('Supabase error creating library: ${e.message}', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      _logger.e('Error creating library: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get all libraries created by user
  Future<List<Library>> getUserLibraries() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client.rpc(
        'get_user_libraries',
        params: {'user_auth_id': userId},
      );

      final libraries = (response as List)
          .map((json) => Library.fromJson(json))
          .toList();

      _logger.i('Fetched ${libraries.length} libraries for user');
      return libraries;
    } catch (e, stack) {
      _logger.e('Error fetching user libraries: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get libraries where user is a member (for students)
  Future<List<Library>> getJoinedLibraries() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client.rpc(
        'get_joined_libraries',
        params: {'user_auth_id': userId},
      );

      final libraries = (response as List).map((json) {
        return Library(
          id: json['LibraryId']?.toString() ?? '',
          name: json['Name']?.toString() ?? 'Untitled Library',
          description: json['Description']?.toString(),
          subject: json['Subject']?.toString(),
          creatorId: json['CreatorId']?.toString() ?? '',
          inviteCode: json['InviteCode']?.toString() ?? '',
          defaultAccessLevel: _parseAccessLevel(json['DefaultAccessLevel']),
          bookCount: (json['BookCount'] ?? 0) as int,
          memberCount: (json['MemberCount'] ?? 0) as int,
          createdAt: _parseDateTime(json['DateCreated']),
          updatedAt: _parseDateTime(json['LastUpdateDate']),
        );
      }).toList();

      _logger.i('Fetched ${libraries.length} joined libraries');
      return libraries;
    } catch (e, stack) {
      _logger.e('Error fetching joined libraries: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get single library by ID
  Future<Library?> getLibrary(String libraryId) async {
    try {
      final response = await _client
          .from('Libraries')
          .select()
          .eq('LibraryId', int.parse(libraryId))
          .single();

      return Library.fromJson(response);
    } catch (e, stack) {
      _logger.e('Error fetching library: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update library
  Future<Library?> updateLibrary({
    required String libraryId,
    String? name,
    String? description,
    String? subject,
    AccessLevel? defaultAccessLevel,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final updateData = <String, dynamic>{
        'LastUpdateUser': userId.toString(),
      };

      if (name != null) updateData['Name'] = name;
      if (description != null) updateData['Description'] = description;
      if (subject != null) updateData['Subject'] = subject;
      if (defaultAccessLevel != null) {
        updateData['DefaultAccessLevel'] = defaultAccessLevel.name;
      }

      final response = await _client
          .from('Libraries')
          .update(updateData)
          .eq('LibraryId', int.parse(libraryId))
          .select()
          .single();

      _logger.i('Library updated successfully: $libraryId');
      return Library.fromJson(response);
    } catch (e, stack) {
      _logger.e('Error updating library: $e', error: e, stackTrace: stack);
      return null;
    }
  }

/// Delete library
Future<bool> deleteLibrary(String libraryId) async {
  try {
    _logger.i('🗑️ Attempting to delete library: $libraryId');
    
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _logger.e('No authenticated user found');
      return false;
    }

    // Verify user is the creator before deleting
    final library = await _client
        .from('Libraries')
        .select('CreatorId')
        .eq('LibraryId', int.parse(libraryId))
        .maybeSingle();

    if (library == null) {
      _logger.e('Library not found: $libraryId');
      return false;
    }

    final userResponse = await _client
        .from('Users')
        .select('UsersId')
        .eq('AuthId', userId)
        .single();

    final usersId = userResponse['UsersId'] as int;

    if (library['CreatorId'] != usersId) {
      _logger.e('User is not the creator of this library');
      return false;
    }

    // Delete the library (CASCADE will handle members and books)
    await _client
        .from('Libraries')
        .delete()
        .eq('LibraryId', int.parse(libraryId));

    _logger.i('✅ Library deleted successfully: $libraryId');
    return true;
  } on PostgrestException catch (e, stack) {
    _logger.e('❌ Supabase error deleting library: ${e.message}', 
      error: e, stackTrace: stack);
    return false;
  } catch (e, stack) {
    _logger.e('❌ Error deleting library: $e', error: e, stackTrace: stack);
    return false;
  }
}

  /// Join library using invite code (uses database function)
  Future<Library?> joinLibrary(String inviteCode) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client.rpc(
        'join_library_by_code',
        params: {
          'user_auth_id': userId,
          'invite_code': inviteCode.toUpperCase(),
        },
      );

      // Response is an array with one element containing the result
      final result = (response as List).first;
      
      if (result['Success'] == true && result['LibraryId'] != null) {
        // Fetch and return the full library details
        return await getLibrary(result['LibraryId'].toString());
      } else {
        _logger.e('Failed to join library: ${result['Message']}');
        return null;
      }
    } catch (e, stack) {
      _logger.e('Error joining library: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Add member to library (manual)
  Future<LibraryMember?> addMember({
    required String libraryId,
    required String userId,
    required AccessLevel accessLevel,
    String role = 'Member',
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final memberData = {
        'LibraryId': int.parse(libraryId),
        'UserId': int.parse(userId),
        'AccessLevel': accessLevel.name,
        'Role': role,
        'LastUpdateUser': currentUserId.toString(),
        'UserCreated': currentUserId.toString(),
      };

      final response = await _client
          .from('LibraryMembers')
          .insert(memberData)
          .select()
          .single();

      _logger.i('Member added to library: $libraryId');
      return LibraryMember.fromJson(response);
    } catch (e, stack) {
      _logger.e('Error adding member: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get library members (uses database function)
  Future<List<LibraryMember>> getLibraryMembers(String libraryId) async {
    try {
      final response = await _client.rpc(
        'get_library_members_with_details',
        params: {'library_id': int.parse(libraryId)},
      );

      final members = (response as List).map((json) {
        return LibraryMember(
          id: json['MemberId']?.toString() ?? '',
          libraryId: json['LibraryId']?.toString() ?? '',
          userId: json['UserId']?.toString() ?? '',
          userEmail: json['UserEmail']?.toString() ?? '',
          userName: json['UserFullName']?.toString(),
          accessLevel: _parseAccessLevel(json['AccessLevel']),
          joinedAt: _parseDateTime(json['DateCreated']),
        );
      }).toList();

      _logger.i('Fetched ${members.length} members for library $libraryId');
      return members;
    } catch (e, stack) {
      _logger.e('Error fetching library members: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Remove member from library
  Future<bool> removeMember(String libraryId, String userId) async {
    try {
      await _client
          .from('LibraryMembers')
          .delete()
          .eq('LibraryId', int.parse(libraryId))
          .eq('UserId', int.parse(userId));

      _logger.i('Member removed from library: $libraryId');
      return true;
    } catch (e, stack) {
      _logger.e('Error removing member: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Add book to library
  Future<LibraryBook?> addBookToLibrary(String libraryId, String bookId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final userResponse = await _client
          .from('Users')
          .select('UsersId')
          .eq('AuthId', userId)
          .single();

      final usersId = userResponse['UsersId'] as int;

      final bookData = {
        'LibraryId': int.parse(libraryId),
        'BookId': int.parse(bookId),
        'AddedBy': usersId,
      };

      final response = await _client
          .from('LibraryBooks')
          .insert(bookData)
          .select()
          .single();

      _logger.i('Book added to library: $libraryId');
      return LibraryBook.fromJson(response);
    } catch (e, stack) {
      _logger.e('Error adding book to library: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get library books (uses database function)
  Future<List<LibraryBook>> getLibraryBooks(String libraryId) async {
    try {
      final response = await _client.rpc(
        'get_library_books_with_details',
        params: {'library_id': int.parse(libraryId)},
      );

      final books = (response as List).map((json) {
        return LibraryBook(
          id: json['LibraryBookId']?.toString() ?? '',
          libraryId: json['LibraryId']?.toString() ?? '',
          bookId: json['BookId']?.toString() ?? '',
          bookTitle: json['BookTitle']?.toString() ?? 'Untitled',
          bookCoverUrl: json['BookCoverUrl']?.toString(),
          addedAt: _parseDateTime(json['AddedAt']),
        );
      }).toList();

      _logger.i('Fetched ${books.length} books for library $libraryId');
      return books;
    } catch (e, stack) {
      _logger.e('Error fetching library books: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Remove book from library
  Future<bool> removeBookFromLibrary(String libraryId, String bookId) async {
    try {
      await _client
          .from('LibraryBooks')
          .delete()
          .eq('LibraryId', int.parse(libraryId))
          .eq('BookId', int.parse(bookId));

      _logger.i('Book removed from library: $libraryId');
      return true;
    } catch (e, stack) {
      _logger.e('Error removing book from library: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Check if user has access to library
  Future<AccessLevel?> getUserAccessLevel(String libraryId) async {
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
          .from('LibraryMembers')
          .select('AccessLevel')
          .eq('LibraryId', int.parse(libraryId))
          .eq('UserId', usersId)
          .maybeSingle();

      if (response == null) return null;
      return _parseAccessLevel(response['AccessLevel']);
    } catch (e) {
      _logger.e('Error checking access level: $e');
      return null;
    }
  }
}
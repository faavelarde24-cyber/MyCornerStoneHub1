// lib/models/library_models.dart
import 'package:flutter/material.dart';

enum AccessLevel {
  viewOnly,
  interact,
}

class Library {
  final String id;
  final String name;
  final String? description;
  final String? subject;
  final String creatorId;
  final String inviteCode;
  final AccessLevel defaultAccessLevel;
  final int bookCount;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Library({
    required this.id,
    required this.name,
    this.description,
    this.subject,
    required this.creatorId,
    required this.inviteCode,
    this.defaultAccessLevel = AccessLevel.viewOnly,
    this.bookCount = 0,
    this.memberCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Library.fromJson(Map<String, dynamic> json) {
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
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Description': description,
      'Subject': subject,
      'CreatorId': int.tryParse(creatorId) ?? 0,
      'InviteCode': inviteCode,
      'DefaultAccessLevel': defaultAccessLevel.name,
      'BookCount': bookCount,
      'MemberCount': memberCount,
    };
  }

  static AccessLevel _parseAccessLevel(dynamic level) {
    if (level == null) return AccessLevel.viewOnly;
    
    try {
      if (level is String) {
        return AccessLevel.values.firstWhere(
          (e) => e.name.toLowerCase() == level.toLowerCase(),
          orElse: () => AccessLevel.viewOnly,
        );
      }
    } catch (e) {
      debugPrint('Error parsing access level: $level');
    }
    return AccessLevel.viewOnly;
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    
    try {
      if (date is String) {
        return DateTime.parse(date);
      } else if (date is DateTime) {
        return date;
      }
    } catch (e) {
      debugPrint('Error parsing date: $date');
    }
    return DateTime.now();
  }
}

class LibraryMember {
  final String id;
  final String libraryId;
  final String userId;
  final String userEmail;
  final String? userName;
  final AccessLevel accessLevel;
  final DateTime joinedAt;

  LibraryMember({
    required this.id,
    required this.libraryId,
    required this.userId,
    required this.userEmail,
    this.userName,
    required this.accessLevel,
    required this.joinedAt,
  });

  factory LibraryMember.fromJson(Map<String, dynamic> json) {
    return LibraryMember(
      id: json['MemberId']?.toString() ?? '',
      libraryId: json['LibraryId']?.toString() ?? '',
      userId: json['UserId']?.toString() ?? '',
      userEmail: json['UserEmail']?.toString() ?? '',
      userName: json['UserName']?.toString(),
      accessLevel: Library._parseAccessLevel(json['AccessLevel']),
      joinedAt: Library._parseDateTime(json['JoinedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'LibraryId': int.tryParse(libraryId) ?? 0,
      'UserId': int.tryParse(userId) ?? 0,
      'AccessLevel': accessLevel.name,
    };
  }
}

class LibraryBook {
  final String id;
  final String libraryId;
  final String bookId;
  final String bookTitle;
  final String? bookCoverUrl;
  final DateTime addedAt;

  LibraryBook({
    required this.id,
    required this.libraryId,
    required this.bookId,
    required this.bookTitle,
    this.bookCoverUrl,
    required this.addedAt,
  });

  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    return LibraryBook(
      id: json['LibraryBookId']?.toString() ?? '',
      libraryId: json['LibraryId']?.toString() ?? '',
      bookId: json['BookId']?.toString() ?? '',
      bookTitle: json['BookTitle']?.toString() ?? 'Untitled',
      bookCoverUrl: json['BookCoverUrl']?.toString(),
      addedAt: Library._parseDateTime(json['AddedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'LibraryId': int.tryParse(libraryId) ?? 0,
      'BookId': int.tryParse(bookId) ?? 0,
    };
  }
}
// lib/models/book_search_models.dart

class BookSearchResult {
  final String id;
  final String title;
  final String? author;
  final String? coverImageUrl;
  final String creatorId;
  final DateTime publishedAt;
  final bool isSaved;
  final double? averageRating;
  final int? ratingsCount;

  BookSearchResult({
    required this.id,
    required this.title,
    this.author,
    this.coverImageUrl,
    required this.creatorId,
    required this.publishedAt,
    this.isSaved = false,
    this.averageRating,
    this.ratingsCount,
  });

  factory BookSearchResult.fromJson(
    Map<String, dynamic> json, {
    double? avgRating,
    int? ratingsCount,
    bool? saved,
  }) {
    return BookSearchResult(
      id: json['BookId']?.toString() ?? '',
      title: json['Title'] as String? ?? '',
      author: json['AuthorName'] as String?,
      coverImageUrl: json['CoverImageUrl'] as String?,
      creatorId: json['CreatorId']?.toString() ?? '',
      publishedAt: json['PublishedAt'] != null
          ? DateTime.parse(json['PublishedAt'] as String)
          : DateTime.now(),
      isSaved: saved ?? false,
      averageRating: avgRating,
      ratingsCount: ratingsCount,
    );
  }
}

class BookRating {
  final String id;
  final String bookId;
  final String userId;
  final double rating;
  final String? review;
  final DateTime createdAt;

  BookRating({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory BookRating.fromJson(Map<String, dynamic> json) {
    return BookRating(
      id: json['RatingId']?.toString() ?? '',
      bookId: json['BookId']?.toString() ?? '',
      userId: json['UserId']?.toString() ?? '',
      rating: (json['Rating'] as num?)?.toDouble() ?? 0.0,
      review: json['Review'] as String?,
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'] as String)
          : DateTime.now(),
    );
  }
}

class SavedBook {
  final String id;
  final String bookId;
  final String userId;
  final String? note;
  final DateTime savedAt;

  SavedBook({
    required this.id,
    required this.bookId,
    required this.userId,
    this.note,
    required this.savedAt,
  });

  factory SavedBook.fromJson(Map<String, dynamic> json) {
    return SavedBook(
      id: json['SavedBookId']?.toString() ?? '',
      bookId: json['BookId']?.toString() ?? '',
      userId: json['UserId']?.toString() ?? '',
      note: json['Note'] as String?,
      savedAt: json['SavedAt'] != null
          ? DateTime.parse(json['SavedAt'] as String)
          : DateTime.now(),
    );
  }
}

class SearchFilter {
  final String query;
  final String? author;
  final double? minRating;

  SearchFilter({
    required this.query,
    this.author,
    this.minRating,
  });
}
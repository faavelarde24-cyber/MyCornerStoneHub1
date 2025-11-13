// lib/models/search_models.dart

/// Model for book ratings
class BookRating {
  final String id;
  final String bookId;
  final String userId;
  final double rating; // 1-5 stars
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookRating({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookRating.fromJson(Map<String, dynamic> json) {
    return BookRating(
      id: json['RatingId']?.toString() ?? '',
      bookId: json['BookId']?.toString() ?? '',
      userId: json['UserId']?.toString() ?? '',
      rating: (json['Rating'] as num?)?.toDouble() ?? 0.0,
      review: json['Review'] as String?,
      createdAt: DateTime.parse(json['DateCreated'] as String),
      updatedAt: DateTime.parse(json['LastUpdateDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BookId': int.tryParse(bookId) ?? 0,
      'UserId': int.tryParse(userId) ?? 0,
      'Rating': rating,
      'Review': review,
    };
  }
}

/// Model for saved/bookmarked books
class SavedBook {
  final String id;
  final String bookId;
  final String userId;
  final DateTime savedAt;
  final String? note;

  const SavedBook({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.savedAt,
    this.note,
  });

  factory SavedBook.fromJson(Map<String, dynamic> json) {
    return SavedBook(
      id: json['SavedBookId']?.toString() ?? '',
      bookId: json['BookId']?.toString() ?? '',
      userId: json['UserId']?.toString() ?? '',
      savedAt: DateTime.parse(json['SavedAt'] as String),
      note: json['Note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BookId': int.tryParse(bookId) ?? 0,
      'UserId': int.tryParse(userId) ?? 0,
      'Note': note,
    };
  }
}

/// Enhanced book search result with ratings
class BookSearchResult {
  final String id;
  final String title;
  final String? author;
  final String? description;
  final String? coverImageUrl;
  final String creatorId;
  final int pageCount;
  final DateTime publishedAt;
  final double averageRating;
  final int totalRatings;
  final bool isSaved;

  const BookSearchResult({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.coverImageUrl,
    required this.creatorId,
    this.pageCount = 0,
    required this.publishedAt,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.isSaved = false,
  });

  factory BookSearchResult.fromJson(
    Map<String, dynamic> json, {
    double? avgRating,
    int? ratingsCount,
    bool? saved,
  }) {
    return BookSearchResult(
      id: json['BookId']?.toString() ?? '',
      title: json['Title']?.toString() ?? 'Untitled',
      author: json['AuthorName']?.toString(),
      description: json['Description']?.toString(),
      coverImageUrl: json['CoverImageUrl']?.toString(),
      creatorId: json['CreatorId']?.toString() ?? '',
      pageCount: (json['PageCount'] ?? 0) as int,
      publishedAt: DateTime.parse(json['DateCreated'] as String),
      averageRating: avgRating ?? 0.0,
      totalRatings: ratingsCount ?? 0,
      isSaved: saved ?? false,
    );
  }
}

/// Search filter criteria
class SearchFilter {
  final String? query;
  final String? author;
  final double? minRating;
  final int? minPages;
  final int? maxPages;
  final DateTime? publishedAfter;
  final DateTime? publishedBefore;
  final SearchSortBy sortBy;
  final bool ascending;

  const SearchFilter({
    this.query,
    this.author,
    this.minRating,
    this.minPages,
    this.maxPages,
    this.publishedAfter,
    this.publishedBefore,
    this.sortBy = SearchSortBy.relevance,
    this.ascending = false,
  });

  SearchFilter copyWith({
    String? query,
    String? author,
    double? minRating,
    int? minPages,
    int? maxPages,
    DateTime? publishedAfter,
    DateTime? publishedBefore,
    SearchSortBy? sortBy,
    bool? ascending,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      author: author ?? this.author,
      minRating: minRating ?? this.minRating,
      minPages: minPages ?? this.minPages,
      maxPages: maxPages ?? this.maxPages,
      publishedAfter: publishedAfter ?? this.publishedAfter,
      publishedBefore: publishedBefore ?? this.publishedBefore,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}

enum SearchSortBy {
  relevance,
  rating,
  date,
  title,
  popularity,
}

// ============================================
// INTERNET BOOK MODELS
// ============================================

/// Model for internet books from APIs
class InternetBook {
  final String id;
  final String title;
  final String? author;
  final String? description;
  final String? coverImageUrl;
  final String? publisher;
  final String? publishedDate;
  final int pageCount;
  final double averageRating;
  final int ratingsCount;
  final String? isbn;
  final String? previewLink;
  final String source; // 'google' or 'openlibrary'
  final List<String> categories;

  const InternetBook({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.coverImageUrl,
    this.publisher,
    this.publishedDate,
    this.pageCount = 0,
    this.averageRating = 0.0,
    this.ratingsCount = 0,
    this.isbn,
    this.previewLink,
    required this.source,
    this.categories = const [],
  });

  /// Create from Google Books API response
  factory InternetBook.fromGoogleBooks(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>? ?? {};
    final industryIdentifiers = volumeInfo['industryIdentifiers'] as List? ?? [];
    
    String? isbn;
    for (var identifier in industryIdentifiers) {
      final identifierMap = identifier as Map<String, dynamic>;
      if (identifierMap['type'] == 'ISBN_13') {
        isbn = identifierMap['identifier'] as String?;
        break;
      }
    }

    final authors = volumeInfo['authors'] as List? ?? [];
    final categoriesList = volumeInfo['categories'] as List? ?? [];

    return InternetBook(
      id: json['id'] as String? ?? '',
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      author: authors.isNotEmpty ? authors.first as String : null,
      description: volumeInfo['description'] as String?,
      coverImageUrl: imageLinks['thumbnail'] as String? ?? imageLinks['smallThumbnail'] as String?,
      publisher: volumeInfo['publisher'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int? ?? 0,
      averageRating: (volumeInfo['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: volumeInfo['ratingsCount'] as int? ?? 0,
      isbn: isbn,
      previewLink: volumeInfo['previewLink'] as String?,
      source: 'google',
      categories: categoriesList.map((e) => e.toString()).toList(),
    );
  }

  /// Create from Open Library API response
  factory InternetBook.fromOpenLibrary(Map<String, dynamic> json) {
    final authors = json['author_name'] as List? ?? [];
    final isbnList = json['isbn'] as List? ?? [];
    final coverId = json['cover_i'] as int?;
    
    String? coverUrl;
    if (coverId != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
    }

    final subjects = json['subject'] as List? ?? [];
    final publishers = json['publisher'] as List? ?? [];

    return InternetBook(
      id: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      author: authors.isNotEmpty ? authors.first as String : null,
      description: json['first_sentence'] as String?,
      coverImageUrl: coverUrl,
      publisher: publishers.isNotEmpty ? publishers.first as String : null,
      publishedDate: json['first_publish_year']?.toString(),
      pageCount: json['number_of_pages_median'] as int? ?? 0,
      averageRating: 0.0, // Open Library doesn't provide ratings
      ratingsCount: 0,
      isbn: isbnList.isNotEmpty ? isbnList.first as String : null,
      previewLink: json['key'] != null ? 'https://openlibrary.org${json['key']}' : null,
      source: 'openlibrary',
      categories: subjects.take(5).map((e) => e.toString()).toList(),
    );
  }
}

/// Detailed book information with preview pages
class InternetBookDetails {
  final InternetBook book;
  final String? fullDescription;
  final List<String> previewPages;
  final String? buyLink;
  final String? readLink;

  const InternetBookDetails({
    required this.book,
    this.fullDescription,
    this.previewPages = const [],
    this.buyLink,
    this.readLink,
  });

  factory InternetBookDetails.fromGoogleBooks(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final accessInfo = json['accessInfo'] as Map<String, dynamic>? ?? {};
    final saleInfo = json['saleInfo'] as Map<String, dynamic>? ?? {};

    return InternetBookDetails(
      book: InternetBook.fromGoogleBooks(json),
      fullDescription: volumeInfo['description'] as String?,
      buyLink: saleInfo['buyLink'] as String?,
      readLink: accessInfo['webReaderLink'] as String?,
      previewPages: [], // Google Books doesn't provide direct page images in API
    );
  }
}
//lib/models/book_size_type.dart
enum BookSizeType {
  portrait,
  square,
  landscape,
}

extension BookSizeTypeExtension on BookSizeType {
  String get label {
    switch (this) {
      case BookSizeType.portrait:
        return 'Portrait';
      case BookSizeType.square:
        return 'Square';
      case BookSizeType.landscape:
        return 'Landscape';
    }
  }

  String get description {
    switch (this) {
      case BookSizeType.portrait:
        return 'Great for reading and longer content';
      case BookSizeType.square:
        return 'Ideal for visual stories and albums';
      case BookSizeType.landscape:
        return 'Best for presentations and photo books';
    }
  }

  double get aspectRatio {
    switch (this) {
      case BookSizeType.portrait:
        return 2 / 3; // 2:3 ratio (e.g., 600x900)
      case BookSizeType.square:
        return 1 / 1; // 1:1 ratio (e.g., 800x800)
      case BookSizeType.landscape:
        return 4 / 3; // 4:3 ratio (e.g., 1200x900)
    }
  }

  // Standard dimensions (you can adjust these)
  double get width {
    switch (this) {
      case BookSizeType.portrait:
        return 600;
      case BookSizeType.square:
        return 800;
      case BookSizeType.landscape:
        return 1200;
    }
  }

  double get height {
    switch (this) {
      case BookSizeType.portrait:
        return 900;
      case BookSizeType.square:
        return 800;
      case BookSizeType.landscape:
        return 900;
    }
  }
}
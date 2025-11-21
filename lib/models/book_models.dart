// lib/models/book_models.dart
import 'package:flutter/material.dart';
import 'book_size_type.dart';

class Book {
  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final String creatorId;
  final BookStatus status;
  final PageSize pageSize;
  final BookTheme? theme;
  final BookSettings settings;
  final List<Collaborator> collaborators;
  final int pageCount;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    required this.creatorId,
    this.status = BookStatus.draft,
    required this.pageSize,
    this.theme,
    required this.settings,
    this.collaborators = const [],
    this.pageCount = 0,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['BookId']?.toString() ?? '',
      title: json['Title']?.toString() ?? 'Untitled',
      description: json['Description']?.toString(),
      coverImageUrl: json['CoverImageUrl']?.toString(),
      creatorId: json['CreatorId']?.toString() ?? '',
      status: _parseBookStatus(json['Status']),
      pageSize: PageSize.fromJson(json['PageSize'] ?? {'width': 800, 'height': 600}),
      theme: json['Theme'] != null ? BookTheme.fromJson(json['Theme']) : null,
      settings: BookSettings.fromJson(json['Settings'] ?? {}),
      collaborators: (json['Collaborators'] as List? ?? []).map((c) => Collaborator.fromJson(c)).toList(),
      pageCount: (json['PageCount'] ?? 0) as int,
      viewCount: (json['ViewCount'] ?? 0) as int,
      createdAt: _parseDateTime(json['DateCreated']),
      updatedAt: _parseDateTime(json['LastUpdateDate']),
    );
  }

  static BookStatus _parseBookStatus(dynamic status) {
    if (status == null) return BookStatus.draft;
    
    try {
      if (status is String) {
        return BookStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == status.toLowerCase(),
          orElse: () => BookStatus.draft,
        );
      }
    } catch (e) {
      debugPrint('Error parsing book status: $status');
    }
    return BookStatus.draft;
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

  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'Description': description,
      'CoverImageUrl': coverImageUrl,
      'CreatorId': int.tryParse(creatorId) ?? 0,
      'Status': status.name,
      'PageSize': pageSize.toJson(),
      'Theme': theme?.toJson(),
      'Settings': settings.toJson(),
      'Collaborators': collaborators.map((c) => c.toJson()).toList(),
      'PageCount': pageCount,
      'ViewCount': viewCount,
    };
  }
}

class BookPage {
  final String id;
  final String bookId;
  final int pageNumber;
  final List<PageElement> elements;
  final PageBackground background;
  final PageLayout? layout;
  final PageSize? pageSize;
  final String? template;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookPage({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    this.elements = const [],
    required this.background,
    this.layout,
    this.pageSize,
    this.template,
    required this.createdAt,
    required this.updatedAt,
  });

factory BookPage.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 BookPage.fromJson parsing: ${json['PageId']}');
    
    return BookPage(
      id: json['PageId']?.toString() ?? '',
      bookId: json['BookId']?.toString() ?? '0', // ✅ CHANGED: Default to '0' instead of ''
      pageNumber: (json['PageNumber'] ?? 1) as int,
      elements: (json['Elements'] as List? ?? [])
          .map((e) {
            try {
              return PageElement.fromJson(e);
            } catch (error) {
              debugPrint('⚠️ Error parsing element: $error');
              return null;
            }
          })
          .whereType<PageElement>() // Filter out nulls
          .toList(),
      background: json['Background'] != null 
          ? PageBackground.fromJson(json['Background']) 
          : PageBackground(color: const Color(0xFFFFFFFF)),
      layout: json['Layout'] != null ? PageLayout.fromJson(json['Layout']) : null,
      pageSize: json['PageSize'] != null ? PageSize.fromJson(json['PageSize']) : null,
      template: json['Template']?.toString(),
      createdAt: Book._parseDateTime(json['DateCreated']),
      updatedAt: Book._parseDateTime(json['LastUpdateDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BookId': int.tryParse(bookId) ?? 0,
      'PageNumber': pageNumber,
      'Elements': elements.map((e) => e.toJson()).toList(),
      'Background': background.toJson(),
      'Layout': layout?.toJson(),
      'PageSize': pageSize?.toJson(),
      'Template': template,
    };
  }
}

// ENHANCED PageElement class with advanced text properties
class PageElement {
  final String id;
  final ElementType type;
  final Offset position;
  final Size size;
  final double rotation;
  final Map<String, dynamic> properties;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final double? lineHeight;
  final List<Shadow>? shadows;
  final bool locked;

  PageElement({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.rotation = 0,
    this.properties = const {},
    this.textStyle,
    this.textAlign,
    this.lineHeight,
    this.shadows,
    this.locked = false,
  });

 factory PageElement.shape({
    required String id,
    required ShapeType shapeType,
    required Offset position,
    required Size size,
    required Color color,
    double strokeWidth = 2.0,
    bool filled = true,
  }) {
    return PageElement(
      id: id,
      type: ElementType.shape,
      position: position,
      size: size,
      properties: {
        'shapeType': shapeType.name,
        'color': color.toARGB32().toRadixString(16),
        'strokeWidth': strokeWidth,
        'filled': filled,
      },
      locked: false,
    );
  }

  factory PageElement.text({
    required String id,
    required String text,
    required Offset position,
    required Size size,
    TextStyle? style,
    TextAlign? textAlign,
    double? lineHeight,
    List<Shadow>? shadows,
  }) {
    return PageElement(
      id: id,
      type: ElementType.text,
      position: position,
      size: size,
      properties: {'text': text},
      textStyle: style,
      textAlign: textAlign,
      lineHeight: lineHeight,
      shadows: shadows,
      locked: false,
    );
  }

  factory PageElement.image({
    required String id,
    required String imageUrl,
    required Offset position,
    required Size size,
  }) {
    return PageElement(
      id: id,
      type: ElementType.image,
      position: position,
      size: size,
      properties: {'imageUrl': imageUrl},
      locked: false,
    );
  }

  factory PageElement.fromJson(Map<String, dynamic> json) {
    return PageElement(
      id: json['id']?.toString() ?? '',
      type: ElementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ElementType.text,
      ),
      position: Offset(
        (json['position']?['x'] ?? 0).toDouble(),
        (json['position']?['y'] ?? 0).toDouble(),
      ),
      size: Size(
        (json['size']?['width'] ?? 100).toDouble(),
        (json['size']?['height'] ?? 100).toDouble(),
      ),
      rotation: (json['rotation'] ?? 0).toDouble(),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      textStyle: json['textStyle'] != null ? _textStyleFromJson(json['textStyle']) : null,
      textAlign: json['textAlign'] != null ? _textAlignFromString(json['textAlign']) : null,
      lineHeight: json['lineHeight']?.toDouble(),
      shadows: json['shadows'] != null ? _shadowsFromJson(json['shadows']) : null,
      locked: json['locked'] ?? false,
    );
  }

factory PageElement.audio({
  required String id,
  required String audioUrl,
  required Offset position,
  required Size size,
  String? title,
}) {
  return PageElement(
    id: id,
    type: ElementType.audio,
    position: position,
    size: size,
    properties: {
      'audioUrl': audioUrl,
      'title': title ?? 'Audio',
    },
    locked: false,
  );
}

factory PageElement.video({
  required String id,
  required String videoUrl,
  required Offset position,
  required Size size,
  String? thumbnailUrl,
}) {
  return PageElement(
    id: id,
    type: ElementType.video,
    position: position,
    size: size,
    properties: {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
    },
    locked: false,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'position': {'x': position.dx, 'y': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'rotation': rotation,
      'properties': properties,
      'textStyle': textStyle != null ? _textStyleToJson(textStyle!) : null,
      'textAlign': textAlign?.name,
      'lineHeight': lineHeight,
      'shadows': shadows != null ? _shadowsToJson(shadows!) : null,
      'locked': locked,
    };
  }

  static TextStyle _textStyleFromJson(Map<String, dynamic> json) {
    return TextStyle(
      color: json['color'] != null ? BookTheme._parseColor(json['color']) : null,
      fontSize: (json['fontSize'] ?? 16)?.toDouble() ?? 16.0,
      fontWeight: json['fontWeight'] != null 
          ? FontWeight.values.firstWhere(
              (f) => f.index == json['fontWeight'],
              orElse: () => FontWeight.normal,
            ) 
          : FontWeight.normal,
      fontStyle: json['fontStyle'] != null && json['fontStyle'] == 'italic'
          ? FontStyle.italic
          : FontStyle.normal,
      fontFamily: json['fontFamily'],
      decoration: json['decoration'] != null 
          ? _textDecorationFromString(json['decoration'])
          : null,
      height: json['height']?.toDouble(),
    );
  }

  static Map<String, dynamic> _textStyleToJson(TextStyle style) {
    return {
      if (style.color != null) 'color': style.color!.toARGB32().toRadixString(16),
      if (style.fontSize != null) 'fontSize': style.fontSize,
      if (style.fontWeight != null) 'fontWeight': style.fontWeight!.index,
      if (style.fontStyle != null) 'fontStyle': style.fontStyle == FontStyle.italic ? 'italic' : 'normal',
      if (style.fontFamily != null) 'fontFamily': style.fontFamily,
      if (style.decoration != null) 'decoration': _textDecorationToString(style.decoration!),
      if (style.height != null) 'height': style.height,
    };
  }

  static TextDecoration _textDecorationFromString(String decoration) {
    switch (decoration) {
      case 'underline':
        return TextDecoration.underline;
      case 'lineThrough':
        return TextDecoration.lineThrough;
      case 'overline':
        return TextDecoration.overline;
      default:
        return TextDecoration.none;
    }
  }

  static String _textDecorationToString(TextDecoration decoration) {
    if (decoration == TextDecoration.underline) return 'underline';
    if (decoration == TextDecoration.lineThrough) return 'lineThrough';
    if (decoration == TextDecoration.overline) return 'overline';
    return 'none';
  }

  static TextAlign _textAlignFromString(String align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  static List<Shadow> _shadowsFromJson(List<dynamic> json) {
    return json.map((s) => Shadow(
      color: BookTheme._parseColor(s['color']) ?? Colors.black,
      offset: Offset(s['offsetX']?.toDouble() ?? 0, s['offsetY']?.toDouble() ?? 0),
      blurRadius: s['blurRadius']?.toDouble() ?? 0,
    )).toList();
  }

  static List<Map<String, dynamic>> _shadowsToJson(List<Shadow> shadows) {
    return shadows.map((s) => {
      'color': s.color.toARGB32().toRadixString(16),
      'offsetX': s.offset.dx,
      'offsetY': s.offset.dy,
      'blurRadius': s.blurRadius,
    }).toList();
  }
}

enum ElementType {
  text,
  image,
  shape,
  sticker,
  drawing,
  audio,
  video,
}

enum ShapeType {
  rectangle,
  circle,
  triangle,
  star,
  line,
  arrow,
}

enum BookStatus {
  draft,
  published,
  archived,
}

class PageSize {
  final double width;
  final double height;
  final String orientation; // 'portrait' or 'landscape'

  PageSize({required this.width, required this.height, this.orientation = 'portrait'});

  factory PageSize.fromBookSizeType(BookSizeType sizeType) {
    return PageSize(
      width: sizeType.width,
      height: sizeType.height,
      orientation: sizeType.name,
    );
  }


  factory PageSize.fromJson(Map<String, dynamic> json) {
    return PageSize(
      width: (json['width'] ?? 800).toDouble(),
      height: (json['height'] ?? 600).toDouble(),
      orientation: json['orientation'] ?? 'portrait',
    );
  }

  

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'orientation': orientation,
    };
  }
}

class BookTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final String fontFamily;

  BookTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.fontFamily,
  });

  factory BookTheme.fromJson(Map<String, dynamic> json) {
    return BookTheme(
      primaryColor: _parseColor(json['primaryColor']) ?? const Color(0xFF000000),
      secondaryColor: _parseColor(json['secondaryColor']) ?? const Color(0xFF666666),
      fontFamily: json['fontFamily'] ?? 'Arial',
    );
  }

  static Color? _parseColor(dynamic colorValue) {
    if (colorValue == null) return null;
    
    try {
      if (colorValue is String) {
        // Handle formats like '0xFF000000' or '#FF000000'
        String colorString = colorValue.replaceAll('#', '');
        if (colorString.startsWith('0x')) {
          colorString = colorString.replaceFirst('0x', '');
        }
        // Ensure we have 8 characters for ARGB
        if (colorString.length == 6) {
          colorString = 'FF$colorString'; // Add alpha channel
        }
        return Color(int.parse(colorString, radix: 16));
      } else if (colorValue is int) {
        return Color(colorValue);
      }
    } catch (e) {
      debugPrint('Error parsing color: $colorValue, error: $e');
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor.toARGB32().toRadixString(16),
      'secondaryColor': secondaryColor.toARGB32().toRadixString(16),
      'fontFamily': fontFamily,
    };
  }
}

class BookSettings {
  final bool autoSave;
  final int autoSaveInterval;

  BookSettings({this.autoSave = true, this.autoSaveInterval = 30});

  factory BookSettings.fromJson(Map<String, dynamic> json) {
    return BookSettings(
      autoSave: json['autoSave'] ?? true,
      autoSaveInterval: json['autoSaveInterval'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSave': autoSave,
      'autoSaveInterval': autoSaveInterval,
    };
  }
}

class PageBackground {
  final Color color;
  final String? imageUrl;

  PageBackground({required this.color, this.imageUrl});

  factory PageBackground.fromJson(Map<String, dynamic> json) {
    return PageBackground(
      color: BookTheme._parseColor(json['color']) ?? const Color(0xFFFFFFFF),
      imageUrl: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color.toARGB32().toRadixString(16),
      'image': imageUrl,
    };
  }
}

class PageLayout {
  final String type; // 'grid', 'freeform', etc.
  final Map<String, dynamic> config;

  PageLayout({required this.type, this.config = const {}});

  factory PageLayout.fromJson(Map<String, dynamic> json) {
    return PageLayout(
      type: json['type'] ?? 'freeform',
      config: Map<String, dynamic>.from(json['config'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'config': config,
    };
  }
}

class Collaborator {
  final String userId;
  final String permission; // 'view', 'comment', 'edit'

  Collaborator({required this.userId, required this.permission});

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      userId: json['userId']?.toString() ?? '',
      permission: json['permission']?.toString() ?? 'view',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'permission': permission,
    };
  }
}

// Extension method for Color to get ARGB32 value
extension ColorExtension on Color {
  int toARGB32() {
    return (((a * 255.0).round() & 0xff) << 24) |
        (((r * 255.0).round() & 0xff) << 16) |
        (((g * 255.0).round() & 0xff) << 8) |
        (((b * 255.0).round() & 0xff) << 0);
  }
}
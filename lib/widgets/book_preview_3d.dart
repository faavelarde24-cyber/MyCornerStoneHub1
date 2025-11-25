import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../models/book_models.dart';

/// Simplified 3D book preview for grid/list views
class BookPreview3D extends StatefulWidget {
  final Book book;
  final BookPage? firstPage;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const BookPreview3D({
    super.key,
    required this.book,
    this.firstPage,
    this.width = 160,
    this.height = 200,
    this.onTap,
  });

  @override
  State<BookPreview3D> createState() => _BookPreview3DState();
}

class _BookPreview3DState extends State<BookPreview3D> {
  ui.Image? _backgroundImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  @override
  void didUpdateWidget(BookPreview3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      _loadBackgroundImage();
    }
  }

  Future<void> _loadBackgroundImage() async {
    final imageUrl = widget.firstPage?.background.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final image = NetworkImage(imageUrl);
      final completer = image.resolve(const ImageConfiguration());

      completer.addListener(ImageStreamListener((info, _) {
        if (mounted) {
          setState(() {
            _backgroundImage = info.image;
            _isLoading = false;
          });
        }
      }, onError: (error, stackTrace) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            // Shadow
            Positioned(
              bottom: 5,
              left: 10,
              right: 10,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            
            // 3D Book
            Positioned.fill(
              child: CustomPaint(
                painter: _MiniBook3DPainter(
                  book: widget.book,
                  firstPage: widget.firstPage,
                  backgroundImage: _backgroundImage,
                ),
              ),
            ),
            
            // Loading indicator
            if (_isLoading)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniBook3DPainter extends CustomPainter {
  final Book book;
  final BookPage? firstPage;
  final ui.Image? backgroundImage;

  _MiniBook3DPainter({
    required this.book,
    this.firstPage,
    this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ CRITICAL: Validate size first
    if (size.width <= 0 || size.height <= 0) {
      debugPrint('⚠️ Invalid canvas size: $size');
      return;
    }

    final paint = Paint()..style = PaintingStyle.fill;

    final spineWidth = (size.height * 0.06).clamp(8.0, 12.0);
    final bookWidth = (size.width - spineWidth).clamp(10.0, size.width);
    final bookHeight = size.height.clamp(10.0, double.infinity);

    // ✅ VALIDATE DIMENSIONS
    if (bookWidth <= 0 || bookHeight <= 0 || spineWidth <= 0) {
      debugPrint('⚠️ Invalid book dimensions: width=$bookWidth, height=$bookHeight, spine=$spineWidth');
      return;
    }

    // Draw book spine
    try {
      final spinePath = Path()
        ..moveTo(0, 0)
        ..lineTo(spineWidth, spineWidth / 2)
        ..lineTo(spineWidth, bookHeight - spineWidth / 2)
        ..lineTo(0, bookHeight)
        ..close();

      paint.color = _getDarkerCoverColor();
      canvas.drawPath(spinePath, paint);
    } catch (e) {
      debugPrint('⚠️ Error drawing spine: $e');
    }

    // Draw spine pages
    try {
      _drawSpinePages(canvas, spineWidth, bookHeight);
    } catch (e) {
      debugPrint('⚠️ Error drawing spine pages: $e');
    }

    // Draw main book cover
    try {
      final coverRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(spineWidth, 0, bookWidth, bookHeight),
        topRight: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      );

      paint.color = _getCoverColor();
      canvas.drawRRect(coverRect, paint);

      // Draw first page content
      if (firstPage != null) {
        _drawFirstPageContent(canvas, coverRect);
      } else {
        _drawTitleOnCover(canvas, coverRect);
      }

      // Border
      paint
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(coverRect, paint);
    } catch (e) {
      debugPrint('⚠️ Error drawing book cover: $e');
    }
  }

  void _drawSpinePages(Canvas canvas, double spineWidth, double height) {
    if (spineWidth <= 0 || height <= 0) return;

    final pagePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const pageThickness = 0.8;
    final pageCount = (height / 30).round().clamp(4, 8);
    final pageSpacing = (height - 20) / pageCount;

    if (pageSpacing <= 0) return;

    for (int i = 0; i < pageCount; i++) {
      try {
        final y = 10 + (i * pageSpacing);
        final pagePath = Path()
          ..moveTo(0, y)
          ..lineTo(spineWidth - 1, y + pageThickness)
          ..lineTo(spineWidth - 1, y + pageThickness + 1.5)
          ..lineTo(0, y + 1.5)
          ..close();

        canvas.drawPath(pagePath, pagePaint);
      } catch (e) {
        debugPrint('⚠️ Error drawing spine page $i: $e');
      }
    }
  }

  void _drawFirstPageContent(Canvas canvas, RRect coverRect) {
    if (firstPage == null) return;

    final rect = coverRect.outerRect;
    if (rect.width <= 24 || rect.height <= 24) return;

    final contentRect = Rect.fromLTWH(
      rect.left + 12,
      rect.top + 12,
      rect.width - 24,
      rect.height - 24,
    );

    if (contentRect.width <= 0 || contentRect.height <= 0) return;

    canvas.save();
    try {
      canvas.clipRRect(RRect.fromRectAndRadius(contentRect, const Radius.circular(4)));

      // Draw background color
      final bgPaint = Paint()
        ..color = firstPage!.background.color
        ..style = PaintingStyle.fill;
      canvas.drawRect(contentRect, bgPaint);

      // Draw background image if loaded
      if (backgroundImage != null) {
        paintImage(
          canvas: canvas,
          rect: contentRect,
          image: backgroundImage!,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        );
      }

      // ✅ SAFE SCALE CALCULATION
      if (book.pageSize.width > 0 && rect.width > 0) {
        final scale = (rect.width / book.pageSize.width).clamp(0.1, 0.25);

        // Draw elements (simplified)
        for (var element in firstPage!.elements) {
          try {
            _drawElement(canvas, element, contentRect, scale);
          } catch (e) {
            debugPrint('⚠️ Error drawing element ${element.id}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error in _drawFirstPageContent: $e');
    } finally {
      canvas.restore();
    }
  }

  void _drawElement(Canvas canvas, PageElement element, Rect bounds, double scale) {
    if (scale <= 0 || scale.isNaN || scale.isInfinite) {
      debugPrint('⚠️ Invalid scale: $scale');
      return;
    }

    final scaledWidth = (element.size.width * scale).clamp(8.0, bounds.width);
    final scaledHeight = (element.size.height * scale).clamp(8.0, bounds.height);

    if (scaledWidth <= 0 || scaledHeight <= 0 || scaledWidth.isNaN || scaledHeight.isNaN) {
      return;
    }

    final scaledPos = Offset(
      bounds.left + (element.position.dx * scale).clamp(0, bounds.width - scaledWidth),
      bounds.top + (element.position.dy * scale).clamp(0, bounds.height - scaledHeight),
    );

    final scaledSize = Size(scaledWidth, scaledHeight);

    if (scaledPos.dx > bounds.right || scaledPos.dy > bounds.bottom) return;
    if (scaledPos.dx.isNaN || scaledPos.dy.isNaN) return;

    try {
      switch (element.type) {
        case ElementType.text:
          _drawTextElement(canvas, element, scaledPos, scaledSize);
          break;
        case ElementType.shape:
          _drawShapeElement(canvas, element, scaledPos, scaledSize);
          break;
        case ElementType.image:
          _drawImagePlaceholder(canvas, scaledPos, scaledSize);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('⚠️ Error drawing element type ${element.type}: $e');
    }
  }

  void _drawTextElement(Canvas canvas, PageElement element, Offset pos, Size size) {
    final text = element.properties['text'] as String? ?? '';
    if (text.isEmpty) return;

    try {
      final textStyle = element.textStyle ?? const TextStyle(fontSize: 16, color: Colors.black);
      final baseFontSize = textStyle.fontSize ?? 16;
      final scaledFontSize = (baseFontSize * 0.18).clamp(4.0, 10.0);

      final scaledTextStyle = textStyle.copyWith(
        fontSize: scaledFontSize,
        shadows: [
          if (textStyle.color == Colors.white ||
              (textStyle.color?.computeLuminance() ?? 0) > 0.7)
            const Shadow(
              color: Colors.black26,
              blurRadius: 1,
              offset: Offset(0.5, 0.5),
            ),
        ],
      );

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: scaledTextStyle),
        textAlign: element.textAlign ?? TextAlign.left,
        textDirection: TextDirection.ltr,
        maxLines: 3,
        ellipsis: '...',
      )..layout(maxWidth: size.width);

      textPainter.paint(canvas, pos);
    } catch (e) {
      debugPrint('⚠️ Error drawing text element: $e');
    }
  }

  void _drawShapeElement(Canvas canvas, PageElement element, Offset pos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    try {
      final colorHex = element.properties['color'] as String?;
      final color = _parseColor(colorHex) ?? Colors.blue;
      final filled = element.properties['filled'] as bool? ?? true;

      final paint = Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1;

      final shapeType = element.properties['shapeType'] as String? ?? 'rectangle';
      final rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);

      switch (shapeType) {
        case 'circle':
          canvas.drawOval(rect, paint);
          break;
        case 'triangle':
          final trianglePath = Path()
            ..moveTo(pos.dx + size.width / 2, pos.dy)
            ..lineTo(pos.dx + size.width, pos.dy + size.height)
            ..lineTo(pos.dx, pos.dy + size.height)
            ..close();
          canvas.drawPath(trianglePath, paint);
          break;
        case 'star':
          canvas.drawPath(_createStarPath(pos, size), paint);
          break;
        default:
          final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1));
          canvas.drawRRect(rrect, paint);
          break;
      }
    } catch (e) {
      debugPrint('⚠️ Error drawing shape element: $e');
    }
  }

  Path _createStarPath(Offset pos, Size size) {
    final path = Path();
    final centerX = pos.dx + size.width / 2;
    final centerY = pos.dy + size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;
    const points = 5;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawImagePlaceholder(Canvas canvas, Offset pos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    try {
      final bgPaint = Paint()..color = Colors.grey[300]!;
      final rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
      canvas.drawRect(rect, bgPaint);

      final iconSize = (size.width * 0.3).clamp(6.0, 12.0);
      final iconCenter = Offset(pos.dx + size.width / 2, pos.dy + size.height / 2);

      final iconPaint = Paint()
        ..color = Colors.grey[500]!
        ..style = PaintingStyle.fill;

      canvas.drawCircle(iconCenter, iconSize / 2, iconPaint);
    } catch (e) {
      debugPrint('⚠️ Error drawing image placeholder: $e');
    }
  }

  void _drawTitleOnCover(Canvas canvas, RRect coverRect) {
    final rect = coverRect.outerRect;
    if (rect.width <= 40 || rect.height <= 40) return;

    try {
      final fontSize = (rect.width * 0.08).clamp(10.0, 16.0);

      final textPainter = TextPainter(
        text: TextSpan(
          text: book.title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 3,
        ellipsis: '...',
      )..layout(maxWidth: rect.width - 40);

      final offset = Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      );

      textPainter.paint(canvas, offset);
    } catch (e) {
      debugPrint('⚠️ Error drawing title on cover: $e');
    }
  }

  Color? _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return null;
    
    try {
      String cleanHex = colorHex.toString();
      cleanHex = cleanHex.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
      
      if (cleanHex.isEmpty || cleanHex == '0' || cleanHex.length < 6) {
        return null;
      }
      
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      } else if (cleanHex.length != 8) {
        return null;
      }
      
      final parsed = int.tryParse(cleanHex, radix: 16);
      return parsed != null ? Color(parsed) : null;
    } catch (e) {
      return null;
    }
  }

  Color _getCoverColor() {
    if (book.theme?.primaryColor != null) {
      return book.theme!.primaryColor;
    }
    
    try {
      final hash = book.id.hashCode.abs();
      if (hash == 0) return const Color(0xFFF59E0B);
      
      return Color.fromARGB(
        255,
        ((hash & 0xFF0000) >> 16).clamp(50, 255),
        ((hash & 0x00FF00) >> 8).clamp(50, 255),
        (hash & 0x0000FF).clamp(50, 255),
      );
    } catch (e) {
      return const Color(0xFFF59E0B);
    }
  }

  Color _getDarkerCoverColor() {
    try {
      final baseColor = _getCoverColor();
      return Color.fromARGB(
        255,
        ((baseColor.r * 255.0 * 0.7).round().clamp(0, 255)),
        ((baseColor.g * 255.0 * 0.7).round().clamp(0, 255)),
        ((baseColor.b * 255.0 * 0.7).round().clamp(0, 255)),
      );
    } catch (e) {
      return const Color(0xFFB37808);
    }
  }

  @override
  bool shouldRepaint(_MiniBook3DPainter oldDelegate) {
    return oldDelegate.book.id != book.id ||
        oldDelegate.firstPage?.id != firstPage?.id ||
        oldDelegate.backgroundImage != backgroundImage;
  }
}
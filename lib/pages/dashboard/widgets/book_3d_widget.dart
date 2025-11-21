// lib/pages/dashboard/widgets/book_3d_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';
import '../../../app_theme.dart';

class Book3DWidget extends ConsumerStatefulWidget {
  final Book book;
  final bool isSelected;
  final VoidCallback onTap;

  const Book3DWidget({
    super.key,
    required this.book,
    required this.isSelected,
    required this.onTap,
  });

  @override
  ConsumerState<Book3DWidget> createState() => _Book3DWidgetState();
}

class _Book3DWidgetState extends ConsumerState<Book3DWidget> {
  ui.Image? _backgroundImage;
  bool _isLoadingImage = false;
  int _buildCount = 0;
  
  // ✅ REPLACE THIS GETTER (around line 18-22)
  String get _bookIdShort {
    if (widget.book.id.isEmpty) return 'EMPTY';
    if (widget.book.id.length <= 8) return widget.book.id;
    return widget.book.id.substring(0, 8);
  }

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 [Book3D-$_bookIdShort] initState called');
    debugPrint('🎬 [Book3D] Book: ${widget.book.title}');
    _loadBackgroundImage();
  }
  @override
  void didUpdateWidget(Book3DWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🔄 [Book3D] didUpdateWidget called');
    debugPrint('🔄 [Book3D] Old book: ${oldWidget.book.id}');
    debugPrint('🔄 [Book3D] New book: ${widget.book.id}');
    
    if (oldWidget.book.id != widget.book.id) {
      debugPrint('🔄 [Book3D] ⚠️ Book changed! Reloading image...');
      _loadBackgroundImage();
    } else {
      debugPrint('🔄 [Book3D] Same book, no reload needed');
    }
  }

  Future<void> _loadBackgroundImage() async {
  debugPrint('🖼️ [Book3D-$_bookIdShort] === START _loadBackgroundImage ===');
  debugPrint('🖼️ [Book3D] Book title: ${widget.book.title}');
  debugPrint('🖼️ [Book3D] Book ID length: ${widget.book.id.length}');
  debugPrint('🖼️ [Book3D] Current _isLoadingImage: $_isLoadingImage');
  debugPrint('🖼️ [Book3D] Current _backgroundImage: ${_backgroundImage != null ? "LOADED" : "NULL"}');
  
  // ✅ FIX: Use .future to await the pages (not .when which checks current state)
  debugPrint('🖼️ [Book3D] Fetching pages (awaiting future)...');
  
  try {
    // ✅ THIS IS THE KEY FIX: .future waits for the provider to complete
    final pages = await ref.read(bookPagesProvider(widget.book.id).future);

    
    debugPrint('🖼️ [Book3D] ✅ Pages loaded: ${pages.length} pages');
    
    if (pages.isEmpty) {
      debugPrint('🖼️ [Book3D] ⚠️ No pages found, exiting');
      return;
    }
    
    final firstPage = pages.first;
    debugPrint('🖼️ [Book3D] First page ID: ${firstPage.id}');
    debugPrint('🖼️ [Book3D] Background color: ${firstPage.background.color}');
    
    final imageUrl = firstPage.background.imageUrl;
    debugPrint('🖼️ [Book3D] Image URL: ${imageUrl ?? "NULL"}');
    debugPrint('🖼️ [Book3D] Image URL isEmpty: ${imageUrl?.isEmpty ?? true}');
    
    if (imageUrl != null && imageUrl.isNotEmpty && !_isLoadingImage) {
      final urlPreview = imageUrl.length > 50 
          ? '${imageUrl.substring(0, 50)}...' 
          : imageUrl;
      debugPrint('🖼️ [Book3D] 🚀 Starting image load from: $urlPreview');
      
      if (!mounted) {
        debugPrint('🖼️ [Book3D] ⚠️ Widget unmounted before image load');
        return;
      }
      
      setState(() => _isLoadingImage = true);
      debugPrint('🖼️ [Book3D] Set _isLoadingImage = true');
      
      try {
        final startTime = DateTime.now();
        debugPrint('🖼️ [Book3D] ⏱️ Image fetch started at: $startTime');
        
        final image = NetworkImage(imageUrl);
        final completer = image.resolve(const ImageConfiguration());
        
        debugPrint('🖼️ [Book3D] ImageStream created, adding listener...');
        
        completer.addListener(ImageStreamListener((info, _) {
          final endTime = DateTime.now();
          final duration = endTime.difference(startTime).inMilliseconds;
          
          debugPrint('🖼️ [Book3D] ✅ Image loaded successfully!');
          debugPrint('🖼️ [Book3D] ⏱️ Load time: ${duration}ms');
          debugPrint('🖼️ [Book3D] Image dimensions: ${info.image.width}x${info.image.height}');
          
          if (mounted) {
            setState(() {
              _backgroundImage = info.image;
              _isLoadingImage = false;
            });
            debugPrint('🖼️ [Book3D] ✅ State updated with image');
          } else {
            debugPrint('🖼️ [Book3D] ⚠️ Widget unmounted, cannot update state');
          }
        }, onError: (error, stackTrace) {
          debugPrint('🖼️ [Book3D] ❌ ERROR loading image: $error');
          debugPrint('🖼️ [Book3D] Stack trace: $stackTrace');
          
          if (mounted) {
            setState(() => _isLoadingImage = false);
            debugPrint('🖼️ [Book3D] Reset _isLoadingImage to false after error');
          }
        }));
        
        debugPrint('🖼️ [Book3D] Listener added, waiting for image...');
        
      } catch (e) {
        debugPrint('🖼️ [Book3D] ❌ EXCEPTION in image loading: $e');
        if (mounted) {
          setState(() => _isLoadingImage = false);
        }
      }
    } else {
      if (imageUrl == null || imageUrl.isEmpty) {
        debugPrint('🖼️ [Book3D] ℹ️ No image URL to load');
      } else if (_isLoadingImage) {
        debugPrint('🖼️ [Book3D] ⏳ Already loading image, skipping');
      }
    }
  } catch (e, stack) {
    debugPrint('🖼️ [Book3D] ❌ ERROR loading pages: $e');
    debugPrint('🖼️ [Book3D] Stack: $stack');
  }
  
  debugPrint('🖼️ [Book3D-$_bookIdShort] === END _loadBackgroundImage ===\n');
} 

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    debugPrint('🏗️ [Book3D-$_bookIdShort] === BUILD #$_buildCount ===');
    debugPrint('🏗️ [Book3D] Book: ${widget.book.title}');
    debugPrint('🏗️ [Book3D] isSelected: ${widget.isSelected}');
    debugPrint('🏗️ [Book3D] Has background image: ${_backgroundImage != null}');
    debugPrint('🏗️ [Book3D] Is loading image: $_isLoadingImage');
    
    final scale = widget.isSelected ? 1.0 : 0.85;
    
    if (widget.isSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(currentBookIdProvider.notifier).setBookId(widget.book.id);
      });
    }
    
    final pagesAsync = ref.watch(bookPagesProvider(widget.book.id));

    pagesAsync.whenData((pages) {
      if (pages.isNotEmpty && widget.isSelected) {
        final firstPage = pages.first;
        debugPrint('📖 === Book3DWidget Debug ===');
        debugPrint('Book: ${widget.book.title} (ID: ${widget.book.id})');
        debugPrint('First Page ID: ${firstPage.id}');
        debugPrint('Background Color: ${firstPage.background.color}');
        debugPrint('Background Color Hex: ${firstPage.background.color.toARGB32().toRadixString(16)}');
        debugPrint('Background Image: ${firstPage.background.imageUrl ?? "none"}');
        debugPrint('Elements: ${firstPage.elements.length}');
      }
    });

    final aspectRatio = widget.book.pageSize.width / widget.book.pageSize.height;
    
    const double baseHeight = 380.0;
    final double baseWidth = baseHeight * aspectRatio;
    
    final double constrainedWidth = baseWidth.clamp(200.0, 400.0);
    final double constrainedHeight = baseHeight;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scaleByDouble(scale, scale, scale, 1.0),
        child: Stack(
          children: [
            // Shadow
            Positioned(
              bottom: 10,
              left: 20,
              right: 20,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            
            // 3D Book
            Center(
              child: SizedBox(
                width: constrainedWidth,
                height: constrainedHeight,
                child: CustomPaint(
                  painter: Book3DPainter(
                    book: widget.book,
                    firstPage: _getFirstPage(pagesAsync),
                    aspectRatio: aspectRatio,
                    backgroundImage: _backgroundImage,
                  ),
                  child: Container(),
                ),
              ),
            ),
            
            // Book type badge
            if (widget.isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getBookTypeLabel(aspectRatio),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  BookPage? _getFirstPage(AsyncValue<List<BookPage>> pagesAsync) {
    return pagesAsync.when(
      data: (pages) => pages.isNotEmpty ? pages.first : null,
      loading: () => null,
      error: (_, _) => null,
    );
  }
  
  String _getBookTypeLabel(double aspectRatio) {
    if (aspectRatio < 0.85) {
      return 'Portrait';
    } else if (aspectRatio > 1.15) {
      return 'Landscape';
    } else {
      return 'Square';
    }
  }
}

class Book3DPainter extends CustomPainter {
  final Book book;
  final BookPage? firstPage;
  final double aspectRatio;
  final ui.Image? backgroundImage; // ✅ Add this

  Book3DPainter({
    required this.book,
    this.firstPage,
    required this.aspectRatio,
    this.backgroundImage, // ✅ Add this
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final spineWidth = (size.height * 0.04).clamp(12.0, 18.0);
    final bookWidth = size.width - spineWidth;
    final bookHeight = size.height;

    // Draw book spine
    final spinePath = Path()
      ..moveTo(0, 0)
      ..lineTo(spineWidth, spineWidth / 2)
      ..lineTo(spineWidth, bookHeight - spineWidth / 2)
      ..lineTo(0, bookHeight)
      ..close();

    paint.color = _getDarkerCoverColor();
    canvas.drawPath(spinePath, paint);

    _drawSpinePages(canvas, spineWidth, bookHeight);

    // Draw main book cover
    final coverRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(spineWidth, 0, bookWidth, bookHeight),
      topRight: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
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
  }

  void _drawSpinePages(Canvas canvas, double spineWidth, double height) {
    final pagePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const pageThickness = 1.0;
    final pageCount = (height / 50).round().clamp(6, 10);
    final pageSpacing = (height - 40) / pageCount;

    for (int i = 0; i < pageCount; i++) {
      final y = 20 + (i * pageSpacing);
      final pagePath = Path()
        ..moveTo(0, y)
        ..lineTo(spineWidth - 2, y + pageThickness)
        ..lineTo(spineWidth - 2, y + pageThickness + 2)
        ..lineTo(0, y + 2)
        ..close();

      canvas.drawPath(pagePath, pagePaint);
    }
  }

  void _drawFirstPageContent(Canvas canvas, RRect coverRect) {
    final rect = coverRect.outerRect;
    final contentRect = Rect.fromLTWH(
      rect.left + 16,
      rect.top + 16,
      rect.width - 32,
      rect.height - 32,
    );

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(contentRect, const Radius.circular(6)));

    // ✅ Draw background color
    final bgPaint = Paint()
      ..color = firstPage!.background.color
      ..style = PaintingStyle.fill;
    canvas.drawRect(contentRect, bgPaint);

    // ✅ Draw background image if loaded
    if (backgroundImage != null) {
      paintImage(
        canvas: canvas,
        rect: contentRect,
        image: backgroundImage!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
    }
    
    final scale = (rect.width / book.pageSize.width).clamp(0.15, 0.35);
    
    // Draw elements
    for (var element in firstPage!.elements) {
      _drawElement(canvas, element, contentRect, scale);
    }

    canvas.restore();
  }

  void _drawElement(Canvas canvas, PageElement element, Rect bounds, double scale) {
    final scaledPos = Offset(
      bounds.left + (element.position.dx * scale).clamp(0, bounds.width - (element.size.width * scale)),
      bounds.top + (element.position.dy * scale).clamp(0, bounds.height - (element.size.height * scale)),
    );
    final scaledSize = Size(
      (element.size.width * scale).clamp(10.0, bounds.width),
      (element.size.height * scale).clamp(10.0, bounds.height),
    );

    if (scaledPos.dx > bounds.right || scaledPos.dy > bounds.bottom) return;

    switch (element.type) {
      case ElementType.text:
        _drawTextElement(canvas, element, scaledPos, scaledSize);
        break;
      case ElementType.shape:
        _drawShapeElement(canvas, element, scaledPos, scaledSize);
        break;
      case ElementType.image:
        _drawImagePlaceholder(canvas, element, scaledPos, scaledSize);
        break;
      case ElementType.video:
        _drawVideoPlaceholder(canvas, scaledPos, scaledSize);
        break;
      case ElementType.audio:
        _drawAudioPlaceholder(canvas, scaledPos, scaledSize);
        break;
      default:
        break;
    }
  }

  void _drawTextElement(Canvas canvas, PageElement element, Offset pos, Size size) {
    final text = element.properties['text'] as String? ?? '';
    if (text.isEmpty) return;

    final textStyle = element.textStyle ?? const TextStyle(fontSize: 16, color: Colors.black);
    final baseFontSize = textStyle.fontSize ?? 16;
    final scaledFontSize = (baseFontSize * 0.25).clamp(6.0, 14.0);
    
    final scaledTextStyle = textStyle.copyWith(
      fontSize: scaledFontSize,
      shadows: [
        if (textStyle.color == Colors.white || 
            (textStyle.color?.computeLuminance() ?? 0) > 0.7)
          const Shadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
      ],
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: scaledTextStyle),
      textAlign: element.textAlign ?? TextAlign.left,
      textDirection: TextDirection.ltr,
      maxLines: 5,
      ellipsis: '...',
    )..layout(maxWidth: size.width);

    textPainter.paint(canvas, pos);
  }

  void _drawShapeElement(Canvas canvas, PageElement element, Offset pos, Size size) {
    final colorHex = element.properties['color'] as String?;
    final color = _parseColor(colorHex) ?? Colors.blue;
    final filled = element.properties['filled'] as bool? ?? true;

    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.5;

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
      case 'line':
        canvas.drawLine(
          Offset(pos.dx, pos.dy + size.height / 2),
          Offset(pos.dx + size.width, pos.dy + size.height / 2),
          Paint()
            ..color = color
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
        break;
      case 'arrow':
        canvas.drawPath(_createArrowPath(pos, size), paint);
        break;
      default:
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
        canvas.drawRRect(rrect, paint);
        break;
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

  Path _createArrowPath(Offset pos, Size size) {
    final path = Path();
    final shaftWidth = size.height * 0.3;
    final headWidth = size.height * 0.8;
    final headLength = size.width * 0.3;
    
    path.moveTo(pos.dx, pos.dy + (size.height - shaftWidth) / 2);
    path.lineTo(pos.dx + size.width - headLength, pos.dy + (size.height - shaftWidth) / 2);
    path.lineTo(pos.dx + size.width - headLength, pos.dy + (size.height - headWidth) / 2);
    path.lineTo(pos.dx + size.width, pos.dy + size.height / 2);
    path.lineTo(pos.dx + size.width - headLength, pos.dy + (size.height + headWidth) / 2);
    path.lineTo(pos.dx + size.width - headLength, pos.dy + (size.height + shaftWidth) / 2);
    path.lineTo(pos.dx, pos.dy + (size.height + shaftWidth) / 2);
    path.close();
    
    return path;
  }

  void _drawImagePlaceholder(Canvas canvas, PageElement element, Offset pos, Size size) {
    final bgPaint = Paint()..color = Colors.grey[200]!;
    final borderPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    final rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
    canvas.drawRect(rect, bgPaint);
    canvas.drawRect(rect, borderPaint);
    
    final iconSize = (size.width * 0.3).clamp(8.0, 20.0);
    final iconCenter = Offset(pos.dx + size.width / 2, pos.dy + size.height / 2);
    
    final iconPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;
    
    final iconPath = Path()
      ..moveTo(iconCenter.dx - iconSize / 2, iconCenter.dy + iconSize / 3)
      ..lineTo(iconCenter.dx - iconSize / 4, iconCenter.dy - iconSize / 3)
      ..lineTo(iconCenter.dx + iconSize / 4, iconCenter.dy)
      ..lineTo(iconCenter.dx + iconSize / 2, iconCenter.dy + iconSize / 3)
      ..close();
    
    canvas.drawPath(iconPath, iconPaint);
  }

  void _drawVideoPlaceholder(Canvas canvas, Offset pos, Size size) {
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.8);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, bgPaint);
    
    final iconSize = (size.width * 0.25).clamp(8.0, 16.0);
    final playPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final playPath = Path()
      ..moveTo(pos.dx + size.width / 2 - iconSize / 3, pos.dy + size.height / 2 - iconSize / 2)
      ..lineTo(pos.dx + size.width / 2 - iconSize / 3, pos.dy + size.height / 2 + iconSize / 2)
      ..lineTo(pos.dx + size.width / 2 + iconSize / 2, pos.dy + size.height / 2)
      ..close();
    
    canvas.drawPath(playPath, playPaint);
  }

  void _drawAudioPlaceholder(Canvas canvas, Offset pos, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF4F46E5).withValues(alpha: 0.9);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, bgPaint);
    
    final waveColor = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final centerY = pos.dy + size.height / 2;
    final waveWidth = size.width * 0.6;
    final startX = pos.dx + size.width * 0.2;
    
    for (int i = 0; i < 3; i++) {
      final x = startX + (waveWidth / 2) * i;
      final height = (i == 1) ? size.height * 0.4 : size.height * 0.25;
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        waveColor,
      );
    }
  }

  Color? _parseColor(String? colorHex) {
    if (colorHex == null) return null;
    try {
      return Color(int.parse(colorHex, radix: 16));
    } catch (e) {
      return null;
    }
  }

  void _drawTitleOnCover(Canvas canvas, RRect coverRect) {
    final rect = coverRect.outerRect;
    final fontSize = (rect.width * 0.07).clamp(14.0, 24.0);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: book.title,
        style: TextStyle(
          fontFamily: AppTheme.fontName,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: AppTheme.white,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '...',
    )..layout(maxWidth: rect.width - 60);

    final offset = Offset(
      rect.left + (rect.width - textPainter.width) / 2,
      rect.top + (rect.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, offset);
  }

  Color _getCoverColor() {
    if (book.theme?.primaryColor != null) {
      return book.theme!.primaryColor;
    }
    final hash = book.id.hashCode;
    return Color.fromARGB(
      255,
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
    );
  }

  Color _getDarkerCoverColor() {
    final baseColor = _getCoverColor();
    return Color.fromARGB(
      255,
      ((baseColor.r * 255.0 * 0.7).round() & 0xff),
      ((baseColor.g * 255.0 * 0.7).round() & 0xff),
      ((baseColor.b * 255.0 * 0.7).round() & 0xff),
    );
  }

  @override
  bool shouldRepaint(Book3DPainter oldDelegate) {
    return oldDelegate.book.id != book.id || 
           oldDelegate.firstPage?.id != firstPage?.id ||
           oldDelegate.aspectRatio != aspectRatio ||
           oldDelegate.backgroundImage != backgroundImage; // ✅ Repaint when image loads
  }
}
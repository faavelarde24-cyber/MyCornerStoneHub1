import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/book_models.dart';
import '../utils/image_cache_manager.dart';

class PageThumbnailWidget extends StatefulWidget {
  final BookPage page;
  final double width;
  final double height;
  final bool showBorder;

  const PageThumbnailWidget({
    super.key,
    required this.page,
    this.width = 120,
    this.height = 160,
    this.showBorder = true,
  });

  @override
  State<PageThumbnailWidget> createState() => _PageThumbnailWidgetState();
}

class _PageThumbnailWidgetState extends State<PageThumbnailWidget> {
  ui.Image? _backgroundImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  @override
  void didUpdateWidget(PageThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.id != widget.page.id) {
      _loadBackgroundImage();
    }
  }

Future<void> _loadBackgroundImage() async {
  final imageUrl = widget.page.background.imageUrl;
  if (imageUrl == null || imageUrl.isEmpty || _isLoading) return;

  // ✅ Check cache first
  final cacheManager = ImageCacheManager();
  final cachedImage = cacheManager.get(imageUrl);
  
  if (cachedImage != null) {
    if (mounted) {
      setState(() => _backgroundImage = cachedImage);
    }
    return;
  }

  setState(() => _isLoading = true);

  try {
    final image = NetworkImage(imageUrl);
    final completer = image.resolve(const ImageConfiguration());

    completer.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        // ✅ Save to cache
        cacheManager.put(imageUrl, info.image);
        
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
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: widget.showBorder
            ? Border.all(color: Colors.grey[300]!, width: 1)
            : null,
        boxShadow: widget.showBorder
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: _PageThumbnailPainter(
            page: widget.page,
            backgroundImage: _backgroundImage,
          ),
          child: _isLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[400],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _PageThumbnailPainter extends CustomPainter {
  final BookPage page;
  final ui.Image? backgroundImage;

  _PageThumbnailPainter({
    required this.page,
    this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background color
    final bgPaint = Paint()
      ..color = page.background.color
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw background image if available
    if (backgroundImage != null) {
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: backgroundImage!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low, // Low quality for thumbnails
      );
    }

    // Calculate scale to fit page content into thumbnail
    final scaleX = size.width / (page.pageSize?.width ?? 800);
    final scaleY = size.height / (page.pageSize?.height ?? 600);
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Draw elements (simplified for thumbnail)
    for (var element in page.elements) {
      _drawElement(canvas, element, size, scale);
    }
  }

  void _drawElement(Canvas canvas, PageElement element, Size bounds, double scale) {
    final scaledPos = Offset(
      element.position.dx * scale,
      element.position.dy * scale,
    );
    final scaledSize = Size(
      element.size.width * scale,
      element.size.height * scale,
    );

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
  }

  void _drawTextElement(Canvas canvas, PageElement element, Offset pos, Size size) {
    final text = element.properties['text'] as String? ?? '';
    if (text.isEmpty) return;

    final textStyle = element.textStyle ?? const TextStyle(fontSize: 16, color: Colors.black);
    final scaledFontSize = (textStyle.fontSize ?? 16) * 0.15;

    final scaledTextStyle = textStyle.copyWith(
      fontSize: scaledFontSize.clamp(4.0, 10.0),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: scaledTextStyle),
      textAlign: element.textAlign ?? TextAlign.left,
      textDirection: TextDirection.ltr,
      maxLines: 3,
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
      ..strokeWidth = 1;

    final rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    canvas.drawRRect(rrect, paint);
  }

  void _drawImagePlaceholder(Canvas canvas, Offset pos, Size size) {
    final bgPaint = Paint()..color = Colors.grey[300]!;
    final rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
    canvas.drawRect(rect, bgPaint);

    // Small icon
    final iconSize = size.width * 0.3;
    final iconCenter = Offset(pos.dx + size.width / 2, pos.dy + size.height / 2);
    final iconPaint = Paint()..color = Colors.grey[500]!;
    canvas.drawCircle(iconCenter, iconSize / 3, iconPaint);
  }

  Color? _parseColor(String? colorHex) {
    if (colorHex == null) return null;
    try {
      return Color(int.parse(colorHex, radix: 16));
    } catch (e) {
      return null;
    }
  }

  @override
  bool shouldRepaint(_PageThumbnailPainter oldDelegate) {
    return oldDelegate.page.id != page.id ||
        oldDelegate.backgroundImage != backgroundImage;
  }
}
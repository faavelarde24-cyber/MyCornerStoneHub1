// lib/pages/book_view/widgets/page_content_widget.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/book_models.dart';
import '../../../pages/book_creator/widgets/audio_player_widget.dart';
import '../../../pages/book_creator/widgets/video_player_widget.dart';

class PageContentWidget extends StatelessWidget {
  final BookPage page;
  final bool isBackside;

  const PageContentWidget({
    super.key,
    required this.page,
    this.isBackside = false,
  });

 @override
Widget build(BuildContext context) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Container(
      color: isBackside
          ? page.background.color.withValues(alpha: 0.9)
          : page.background.color,
      child: Stack(
        children: [
          // Background image (if any)
          if (page.background.imageUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: isBackside ? 0.7 : 1.0,
                child: Image.network(
                  page.background.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),

          // Page elements (text, images, shapes, etc.)
          ...page.elements.map((element) {
            // ✅ CRITICAL: Allow interaction for audio and video elements
            final isInteractive = element.type == ElementType.audio || 
                                   element.type == ElementType.video;
            
            return Positioned(
              left: element.position.dx,
              top: element.position.dy,
              child: Transform.rotate(
                angle: element.rotation,
                child: Opacity(
                  opacity: isBackside ? 0.6 : 1.0,
                  child: isInteractive
                      ? _buildElementContent(element) // ✅ Interactive elements (no IgnorePointer)
                      : IgnorePointer(
                          child: _buildElementContent(element), // ❌ Non-interactive elements
                        ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}
  Widget _buildElementContent(PageElement element) {
    switch (element.type) {
      case ElementType.text:
        return Container(
          width: element.size.width,
          height: element.size.height,
          padding: const EdgeInsets.all(8),
          alignment: _getAlignment(element.textAlign ?? TextAlign.left),
          child: Text(
            element.properties['text'] ?? '',
            style: (element.textStyle ?? const TextStyle(fontSize: 18, color: Colors.black))
                .copyWith(
                  height: element.lineHeight,
                  shadows: element.shadows,
                ),
            textAlign: element.textAlign ?? TextAlign.left,
          ),
        );

      case ElementType.image:
        return SizedBox(
          width: element.size.width,
          height: element.size.height,
          child: Image.network(
            element.properties['imageUrl'] ?? '',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Center(child: Icon(Icons.broken_image, size: 48)),
              );
            },
          ),
        );

      case ElementType.shape:
        return CustomPaint(
          size: element.size,
          painter: ShapePainter(
            shapeType: _parseShapeType(element.properties['shapeType']),
            color: _parseColor(element.properties['color']),
            strokeWidth: (element.properties['strokeWidth'] ?? 2.0).toDouble(),
            filled: element.properties['filled'] ?? true,
          ),
        );

      case ElementType.audio:
        return SizedBox(
          width: element.size.width,
          height: element.size.height,
          child: AudioPlayerWidget(
            audioUrl: element.properties['audioUrl'] ?? '',
            title: element.properties['title'],
            backgroundColor: const Color(0xFF2C3E50),
            accentColor: const Color(0xFF3498DB),
          ),
        );

      case ElementType.video:
        return SizedBox(
          width: element.size.width,
          height: element.size.height,
          child: VideoPlayerWidget(
            videoUrl: element.properties['videoUrl'] ?? '',
            thumbnailUrl: element.properties['thumbnailUrl'],
            backgroundColor: const Color(0xFF000000),
            accentColor: const Color(0xFF3498DB),
          ),
        );
            default:
              return const SizedBox();
            }
  }

  Alignment _getAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left:
        return Alignment.centerLeft;
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.justify:
        return Alignment.centerLeft;
      default:
        return Alignment.centerLeft;
    }
  }

  ShapeType _parseShapeType(dynamic type) {
    if (type == null) return ShapeType.rectangle;
    if (type is ShapeType) return type;
    if (type is String) {
      return ShapeType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => ShapeType.rectangle,
      );
    }
    return ShapeType.rectangle;
  }

  Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return Colors.blue;

    try {
      if (colorValue is String) {
        String colorString = colorValue.replaceAll('#', '');
        if (colorString.startsWith('0x')) {
          colorString = colorString.replaceFirst('0x', '');
        }
        if (colorString.length == 6) {
          colorString = 'FF$colorString';
        }
        return Color(int.parse(colorString, radix: 16));
      } else if (colorValue is int) {
        return Color(colorValue);
      }
    } catch (e) {
      debugPrint('Error parsing color: $colorValue');
    }
    return Colors.blue;
  }
}

// Custom Painter for Shapes (same as in book_creator_page.dart)
class ShapePainter extends CustomPainter {
  final ShapeType shapeType;
  final Color color;
  final double strokeWidth;
  final bool filled;

  ShapePainter({
    required this.shapeType,
    required this.color,
    required this.strokeWidth,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke;

    switch (shapeType) {
      case ShapeType.rectangle:
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;

      case ShapeType.circle:
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          math.min(size.width, size.height) / 2,
          paint,
        );
        break;

      case ShapeType.triangle:
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case ShapeType.star:
        final path = _createStarPath(size);
        canvas.drawPath(path, paint);
        break;

      case ShapeType.line:
        canvas.drawLine(
          Offset(0, size.height / 2),
          Offset(size.width, size.height / 2),
          paint,
        );
        break;

      case ShapeType.arrow:
        final path = Path()
          ..moveTo(0, size.height / 2)
          ..lineTo(size.width * 0.7, size.height / 2)
          ..lineTo(size.width * 0.7, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width * 0.7, size.height)
          ..lineTo(size.width * 0.7, size.height / 2)
          ..close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  Path _createStarPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = math.min(size.width, size.height) / 2;
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

  @override
  bool shouldRepaint(ShapePainter oldDelegate) {
    return oldDelegate.shapeType != shapeType ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.filled != filled;
  }
}
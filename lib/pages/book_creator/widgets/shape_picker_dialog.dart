// lib/pages/book_creator/widgets/shape_picker_dialog.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/book_models.dart';

class ShapePickerDialog extends StatefulWidget {
  final Function(ShapeType shapeType, Color color, double strokeWidth) onShapeSelected;

  const ShapePickerDialog({
    super.key,
    required this.onShapeSelected,
  });

  @override
  State<ShapePickerDialog> createState() => _ShapePickerDialogState();
}

class _ShapePickerDialogState extends State<ShapePickerDialog> {
  ShapeType _selectedShape = ShapeType.rectangle;
  Color _selectedColor = Colors.blue;
  double _strokeWidth = 2.0;
  bool _filled = true;

  // Predefined color palette
  final List<Color> _colorPalette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
    Colors.lime,
    Colors.brown,
    Colors.grey,
    Colors.black,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Shape',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Shape Type Selection
              const Text(
                'Shape Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildShapeTypeGrid(),
              
              const SizedBox(height: 24),

              // Color Selection
              const Text(
                'Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildColorPalette(),
              
              const SizedBox(height: 24),

              // Stroke Width
              const Text(
                'Stroke Width',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _strokeWidth,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      label: _strokeWidth.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() => _strokeWidth = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _strokeWidth.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Fill Toggle
              SwitchListTile(
                title: const Text('Filled'),
                value: _filled,
                onChanged: (value) {
                  setState(() => _filled = value);
                },
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // Preview
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildPreview(),
              
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onShapeSelected(
                        _selectedShape,
                        _selectedColor,
                        _strokeWidth,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Add Shape'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShapeTypeGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ShapeType.values.map((shapeType) {
        final isSelected = _selectedShape == shapeType;
        return InkWell(
          onTap: () {
            setState(() => _selectedShape = shapeType);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getShapeIcon(shapeType),
                  size: 32,
                  color: isSelected ? Colors.blue : Colors.grey.shade700,
                ),
                const SizedBox(height: 4),
                Text(
                  _getShapeName(shapeType),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPalette() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colorPalette.map((color) {
        final isSelected = _selectedColor == color;
        return InkWell(
          onTap: () {
            setState(() => _selectedColor = color);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(120, 120),
          painter: _ShapePreviewPainter(
            shapeType: _selectedShape,
            color: _selectedColor,
            strokeWidth: _strokeWidth,
            filled: _filled,
          ),
        ),
      ),
    );
  }

  IconData _getShapeIcon(ShapeType shapeType) {
    switch (shapeType) {
      case ShapeType.rectangle:
        return Icons.crop_square;
      case ShapeType.circle:
        return Icons.circle_outlined;
      case ShapeType.triangle:
        return Icons.change_history;
      case ShapeType.star:
        return Icons.star_outline;
      case ShapeType.line:
        return Icons.remove;
      case ShapeType.arrow:
        return Icons.arrow_forward;
    }
  }

  String _getShapeName(ShapeType shapeType) {
    switch (shapeType) {
      case ShapeType.rectangle:
        return 'Rectangle';
      case ShapeType.circle:
        return 'Circle';
      case ShapeType.triangle:
        return 'Triangle';
      case ShapeType.star:
        return 'Star';
      case ShapeType.line:
        return 'Line';
      case ShapeType.arrow:
        return 'Arrow';
    }
  }
}

// Preview Painter
class _ShapePreviewPainter extends CustomPainter {
  final ShapeType shapeType;
  final Color color;
  final double strokeWidth;
  final bool filled;

  _ShapePreviewPainter({
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

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.8,
    );

    switch (shapeType) {
      case ShapeType.rectangle:
        canvas.drawRect(rect, paint);
        break;

      case ShapeType.circle:
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          size.width * 0.4,
          paint,
        );
        break;

      case ShapeType.triangle:
        final path = Path()
          ..moveTo(size.width / 2, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case ShapeType.star:
        final path = _createStarPath(size);
        canvas.drawPath(path, paint);
        break;

      case ShapeType.line:
        canvas.drawLine(
          Offset(rect.left, size.height / 2),
          Offset(rect.right, size.height / 2),
          paint,
        );
        break;

      case ShapeType.arrow:
        final path = Path()
          ..moveTo(rect.left, size.height / 2)
          ..lineTo(rect.right - (rect.width * 0.3), size.height / 2)
          ..lineTo(rect.right - (rect.width * 0.3), rect.top)
          ..lineTo(rect.right, size.height / 2)
          ..lineTo(rect.right - (rect.width * 0.3), rect.bottom)
          ..lineTo(rect.right - (rect.width * 0.3), size.height / 2)
          ..close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  Path _createStarPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width * 0.4;
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
  bool shouldRepaint(_ShapePreviewPainter oldDelegate) {
    return oldDelegate.shapeType != shapeType ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.filled != filled;
  }
}
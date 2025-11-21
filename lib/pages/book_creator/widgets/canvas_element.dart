import 'package:flutter/material.dart';
import '../../../models/book_models.dart';

class CanvasElement extends StatelessWidget {
  final PageElement element;
  final bool isSelected;
  final Offset currentPosition;
  final Size currentSize;
  final double currentRotation;
  final Function(String) onTap;
  final Function(DragStartDetails) onDragStart;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails) onDragEnd;
  
  const CanvasElement({
    super.key,
    required this.element,
    required this.isSelected,
    required this.currentPosition,
    required this.currentSize,
    required this.currentRotation,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      child: Transform.translate(
        offset: currentPosition,
        child: Transform.rotate(
          angle: currentRotation,
          child: GestureDetector(
            onTap: () => onTap(element.id),
            onPanStart: onDragStart,
            onPanUpdate: onDragUpdate,
            onPanEnd: onDragEnd,
            child: Container(
              width: currentSize.width,
              height: currentSize.height,
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    // Move your _buildElementContent logic here
    return const Placeholder(); // Temporary
  }
}
//lib/pages/book_creator/widgets/book_size_card.dart
import 'package:flutter/material.dart';
import '../../../models/book_size_type.dart';

class BookSizeCard extends StatefulWidget {
  final BookSizeType sizeType;
  final bool isSelected;
  final VoidCallback onTap;

  const BookSizeCard({
    super.key,
    required this.sizeType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<BookSizeCard> createState() => _BookSizeCardState();
}

class _BookSizeCardState extends State<BookSizeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected 
                  ? const Color(0xFF3B82F6)
                  : _isHovered 
                      ? const Color(0xFFE5E7EB)
                      : Colors.transparent,
              width: widget.isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: widget.isSelected || _isHovered ? 20 : 10,
                offset: Offset(0, widget.isSelected || _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Book Size Preview
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: _isHovered || widget.isSelected ? 1.05 : 1.0,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _buildSizePreview(),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Label
              Text(
                widget.sizeType.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isSelected 
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF1F2937),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                widget.sizeType.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Dimensions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isSelected 
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.sizeType.width.toInt()} × ${widget.sizeType.height.toInt()}px',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.isSelected 
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              
              // Checkmark for selected state
              if (widget.isSelected) ...[
                const SizedBox(height: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizePreview() {
    // Calculate preview dimensions (scaled down proportionally)
    final double maxDimension = 140;
    final double previewWidth = widget.sizeType.width > widget.sizeType.height
        ? maxDimension
        : maxDimension * widget.sizeType.aspectRatio;
    final double previewHeight = widget.sizeType.height > widget.sizeType.width
        ? maxDimension
        : maxDimension / widget.sizeType.aspectRatio;

    return Container(
      width: previewWidth,
      height: previewHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mock header lines
            Container(
              width: previewWidth * 0.6,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: previewWidth * 0.4,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Spacer(),
            // Mock content lines
            for (int i = 0; i < 3; i++) ...[
              Container(
                width: previewWidth * (0.8 - i * 0.1),
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}
// lib/pages/book_view/widgets/book_view_controls.dart
import 'package:flutter/material.dart';
import '../../../app_theme.dart';

class BookViewControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isDarkMode;
  final bool isSinglePageMode;
  final double zoomLevel;
  final VoidCallback onClose;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleViewMode;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomReset;
  final Function(int) onJumpToPage;

  const BookViewControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isDarkMode,
    required this.isSinglePageMode,
    required this.zoomLevel,
    required this.onClose,
    required this.onToggleTheme,
    required this.onToggleViewMode,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomReset,
    required this.onJumpToPage,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Close button
              _buildControlButton(
                icon: Icons.close,
                tooltip: 'Close (Esc)',
                onPressed: onClose,
              ),

              const SizedBox(width: 16),

              // Page counter and jump
              _buildPageCounter(context),

              const Spacer(),

              // View mode toggle
              _buildControlButton(
                icon: isSinglePageMode ? Icons.book : Icons.menu_book,
                tooltip: isSinglePageMode ? 'Two-Page View (S)' : 'Single-Page View (S)',
                onPressed: onToggleViewMode,
              ),

              const SizedBox(width: 8),

              // Zoom controls
              _buildZoomControls(),

              const SizedBox(width: 8),

              // Theme toggle
              _buildControlButton(
                icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
                tooltip: 'Toggle Theme',
                onPressed: onToggleTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildPageCounter(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPageJumpDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.book, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '$currentPage / $totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontName,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom Out
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 18),
            color: Colors.white,
            onPressed: zoomLevel > 0.5 ? onZoomOut : null,
            tooltip: 'Zoom Out',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          // Zoom percentage
          GestureDetector(
            onTap: onZoomReset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${(zoomLevel * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontName,
                ),
              ),
            ),
          ),

          // Zoom In
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 18),
            color: Colors.white,
            onPressed: zoomLevel < 2.0 ? onZoomIn : null,
            tooltip: 'Zoom In',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  void _showPageJumpDialog(BuildContext context) {
    final controller = TextEditingController(text: currentPage.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Page', style: AppTheme.headline),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page Number (1-$totalPages)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null && page >= 1 && page <= totalPages) {
              onJumpToPage(page);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= totalPages) {
                onJumpToPage(page);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid page number (1-$totalPages)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}
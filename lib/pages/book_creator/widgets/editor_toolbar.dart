// lib/pages/book_creator/widgets/editor_toolbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/book_providers.dart';

class EditorToolbar extends ConsumerWidget {
  final Color appBarColor;
  final Color textColor;
  final String bookId;
  final VoidCallback onAddText;
  final VoidCallback onAddImage;
  final VoidCallback onAddShape;
  final VoidCallback onAddAudio;
  final VoidCallback onAddVideo;
  final VoidCallback? onDelete;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool hasSelectedElement;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onToggleGrid;
  final bool gridEnabled;
  final VoidCallback onBackgroundSettings;

  const EditorToolbar({
    super.key,
    required this.appBarColor,
    required this.textColor,
    required this.bookId,
    required this.onAddText,
    required this.onAddImage,
    required this.onAddShape,
    required this.onAddAudio,
    required this.onAddVideo,
    required this.onDelete,
    required this.onUndo,
    required this.onRedo,
    required this.hasSelectedElement,
    required this.canUndo,
    required this.canRedo,
    required this.onToggleGrid,
    required this.gridEnabled,
    required this.onBackgroundSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(bookPagesProvider);
    final pageIndex = ref.watch(currentPageIndexProvider);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: appBarColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Add Content Section
          _buildToolbarButton(
            icon: Icons.text_fields,
            label: 'Text',
            onPressed: onAddText,
            textColor: textColor,
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.image,
            label: 'Image',
            onPressed: onAddImage,
            textColor: textColor,
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.crop_square,
            label: 'Shape',
            onPressed: onAddShape,
            textColor: textColor,
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.audiotrack,
            label: 'Audio',
            onPressed: onAddAudio,
            textColor: textColor,
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.videocam,
            label: 'Video',
            onPressed: onAddVideo,
            textColor: textColor,
          ),
          
          const VerticalDivider(width: 20),
          
          // Edit Section
          _buildToolbarButton(
            icon: Icons.undo,
            label: 'Undo',
            onPressed: canUndo ? onUndo : null,
            textColor: canUndo ? textColor : textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.redo,
            label: 'Redo',
            onPressed: canRedo ? onRedo : null,
            textColor: canRedo ? textColor : textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onPressed: hasSelectedElement ? onDelete : null,
            textColor: hasSelectedElement ? Colors.red : textColor.withValues(alpha: 0.3),
          ),
          
          const VerticalDivider(width: 20),
          
          // View Settings
          _buildToolbarButton(
            icon: gridEnabled ? Icons.grid_on : Icons.grid_off,
            label: 'Grid',
            onPressed: onToggleGrid,
            textColor: gridEnabled ? Colors.blue : textColor,
          ),
          const SizedBox(width: 4),
          _buildToolbarButton(
            icon: Icons.palette,
            label: 'Background',
            onPressed: onBackgroundSettings,
            textColor: textColor,
          ),
          
          const Spacer(),
          
          // Page Navigation
          pagesAsync.when(
            data: (pages) => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: pageIndex > 0
                      ? () => ref.read(currentPageIndexProvider.notifier).setPageIndex(pageIndex - 1)
                      : null,
                  tooltip: 'Previous Page',
                ),
                Text(
                  'Page ${pageIndex + 1} of ${pages.length}',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: pageIndex < pages.length - 1
                      ? () => ref.read(currentPageIndexProvider.notifier).setPageIndex(pageIndex + 1)
                      : null,
                  tooltip: 'Next Page',
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Error'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    required Color textColor,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
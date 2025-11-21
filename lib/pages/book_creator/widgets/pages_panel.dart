// lib/pages/book_creator/widgets/pages_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';

class PagesPanel extends ConsumerStatefulWidget {
  final Color panelColor;
  final Color textColor;
  final String bookId;
  final VoidCallback? onPanelToggle;

  const PagesPanel({
    super.key,
    required this.panelColor,
    required this.textColor,
    required this.bookId,
    this.onPanelToggle,
  });

  @override
  ConsumerState<PagesPanel> createState() => _PagesPanelState();
}

class _PagesPanelState extends ConsumerState<PagesPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(bookPagesProvider(widget.bookId));
    final pageIndex = ref.watch(currentPageIndexProvider);

    return Container(
      width: _isExpanded ? 200 : 60,
      decoration: BoxDecoration(
        color: widget.panelColor,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isExpanded
                ? pagesAsync.when(
                    data: (pages) => ReorderableListView.builder(
                      padding: const EdgeInsets.all(0),
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        return _buildPageListItem(
                          pages[index],
                          index,
                          widget.textColor,
                          pageIndex,
                          widget.bookId,
                          ref,
                          key: Key('page-${pages[index].id}'),
                        );
                      },
                      onReorder: (oldIndex, newIndex) async {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        await _reorderPage(ref, widget.bookId, oldIndex, newIndex);
                      },
                      buildDefaultDragHandles: false,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Error: $error')),
                  )
                : pagesAsync.when(
                    data: (pages) => ListView.builder(
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        return _buildCollapsedPageItem(
                          pages[index],
                          index,
                          pageIndex,
                        );
                      },
                    ),
                    loading: () => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Icon(Icons.error_outline, color: widget.textColor, size: 20),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_isExpanded) ...[
            Icon(Icons.auto_stories, color: widget.textColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pages',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () async {
                final pageActions = ref.read(pageActionsProvider);
                await pageActions.addPage(widget.bookId);
              },
              tooltip: 'Add Page',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() => _isExpanded = false);
                Future.delayed(const Duration(milliseconds: 300), () {
                  widget.onPanelToggle?.call();
                });
              },
              tooltip: 'Collapse',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() => _isExpanded = true);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      widget.onPanelToggle?.call();
                    });
                  },
                  tooltip: 'Expand Pages',
                  color: widget.textColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedPageItem(BookPage page, int index, int currentIndex) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => ref.read(currentPageIndexProvider.notifier).setPageIndex(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha:0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: _buildPageThumbnail(page, index, compact: true),
      ),
    );
  }

  Widget _buildPageListItem(
    BookPage page,
    int index,
    Color textColor,
    int currentIndex,
    String bookId,
    WidgetRef ref, {
    Key? key,
  }) {
    final isSelected = index == currentIndex;

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha:0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: GestureDetector(
                onTap: null, // Prevent triggering page selection
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.drag_handle,
                    size: 16,
                    color: widget.textColor.withValues(alpha:0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _buildPageThumbnail(page, index),
          ],
        ),
        title: Text(
          'Page ${index + 1}',
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
          onSelected: (value) async {
            final pageActions = ref.read(pageActionsProvider);
            final pages = ref.read(bookPagesProvider(widget.bookId)).value;
            
            switch (value) {
              case 'duplicate':
                await pageActions.duplicatePage(page.id, bookId);
                break;
              case 'delete':
                if (pages != null && pages.length > 1) {
                  await pageActions.deletePage(page.id, bookId);
                }
                break;
              case 'move_up':
                if (index > 0) {
                  await _reorderPage(ref, bookId, index, index - 1);
                }
                break;
              case 'move_down':
                if (pages != null && index < pages.length - 1) {
                  await _reorderPage(ref, bookId, index, index + 1);
                }
                break;
              case 'move_to_top':
                if (index > 0) {
                  await _reorderPage(ref, bookId, index, 0);
                }
                break;
              case 'move_to_bottom':
                if (pages != null && index < pages.length - 1) {
                  await _reorderPage(ref, bookId, index, pages.length - 1);
                }
                break;
            }
          },
          itemBuilder: (context) {
            final pages = ref.read(bookPagesProvider(widget.bookId)).value;
            final canDelete = pages != null && pages.length > 1;
            final canMoveUp = index > 0;
            final canMoveDown = pages != null && index < pages.length - 1;
            final canMoveToTop = index > 0;
            final canMoveToBottom = pages != null && index < pages.length - 1;

            return [
              if (canMoveUp)
                const PopupMenuItem(
                  value: 'move_up',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 16),
                      SizedBox(width: 8),
                      Text('Move Up'),
                    ],
                  ),
                ),
              if (canMoveDown)
                const PopupMenuItem(
                  value: 'move_down',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, size: 16),
                      SizedBox(width: 8),
                      Text('Move Down'),
                    ],
                  ),
                ),
              if (canMoveToTop)
                const PopupMenuItem(
                  value: 'move_to_top',
                  child: Row(
                    children: [
                      Icon(Icons.vertical_align_top, size: 16),
                      SizedBox(width: 8),
                      Text('Move to Top'),
                    ],
                  ),
                ),
              if (canMoveToBottom)
                const PopupMenuItem(
                  value: 'move_to_bottom',
                  child: Row(
                    children: [
                      Icon(Icons.vertical_align_bottom, size: 16),
                      SizedBox(width: 8),
                      Text('Move to Bottom'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              if (canDelete)
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ];
          },
        ),
        onTap: () => ref.read(currentPageIndexProvider.notifier).setPageIndex(index),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minLeadingWidth: 60,
        horizontalTitleGap: 8,
      ),
    );
  }

  Future<void> _reorderPage(WidgetRef ref, String bookId, int oldIndex, int newIndex) async {
    final pagesAsync = ref.read(bookPagesProvider(bookId));
    
    await pagesAsync.when(
      data: (pages) async {
        if (pages.isEmpty || oldIndex >= pages.length || newIndex >= pages.length) {
          return;
        }
        
        final pageActions = ref.read(pageActionsProvider);
        
        // Create new ordered list
        final List<BookPage> updatedPages = List.from(pages);
        final BookPage pageToMove = updatedPages.removeAt(oldIndex);
        updatedPages.insert(newIndex, pageToMove);
        
        // Call the reorder method
        await pageActions.reorderPages(bookId, updatedPages);
        
        // Update current page index if needed
        final currentIndex = ref.read(currentPageIndexProvider);
        if (currentIndex == oldIndex) {
          ref.read(currentPageIndexProvider.notifier).setPageIndex(newIndex);
        } else if (currentIndex > oldIndex && currentIndex <= newIndex) {
          // If moving a page up past the current page, adjust current index
          ref.read(currentPageIndexProvider.notifier).setPageIndex(currentIndex - 1);
        } else if (currentIndex < oldIndex && currentIndex >= newIndex) {
          // If moving a page down past the current page, adjust current index
          ref.read(currentPageIndexProvider.notifier).setPageIndex(currentIndex + 1);
        }
      },
      loading: () {},
      error: (error, stack) {
        debugPrint('Error reordering page: $error');
      },
    );
  }

  // Get actual page dimensions (with fallback to book dimensions)
  (double, double) _getCanvasDimensions(BookPage page) {
    if (page.pageSize != null) {
      return (page.pageSize!.width, page.pageSize!.height);
    }
    
    final bookAsync = ref.read(bookProvider(widget.bookId));
    return bookAsync.when(
      data: (book) {
        if (book?.pageSize != null) {
          return (book!.pageSize.width, book.pageSize.height);
        }
        return (800.0, 600.0);
      },
      loading: () => (800.0, 600.0),
      error: (_, _) => (800.0, 600.0),
    );
  }

  Widget _buildPageThumbnail(BookPage page, int index, {bool compact = false}) {
    final (canvasWidth, canvasHeight) = _getCanvasDimensions(page);
    final aspectRatio = canvasWidth / canvasHeight;
    
    double thumbnailWidth;
    double thumbnailHeight;
    
    if (compact) {
      thumbnailHeight = 50.0;
      thumbnailWidth = thumbnailHeight * aspectRatio;
      
      if (thumbnailWidth > 60) {
        thumbnailWidth = 60.0;
        thumbnailHeight = thumbnailWidth / aspectRatio;
      }
    } else {
      thumbnailHeight = 60.0;
      thumbnailWidth = thumbnailHeight * aspectRatio;
      
      if (thumbnailWidth > 70) {
        thumbnailWidth = 70.0;
        thumbnailHeight = thumbnailWidth / aspectRatio;
      }
    }

    return Container(
      width: thumbnailWidth,
      height: thumbnailHeight,
      decoration: BoxDecoration(
        color: page.background.color,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            if (page.background.imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  page.background.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            ...page.elements.map((element) => _buildElementPreview(
              element, 
              page, 
              canvasWidth, 
              canvasHeight, 
              thumbnailWidth, 
              thumbnailHeight
            )),
            
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementPreview(
    PageElement element, 
    BookPage page, 
    double canvasWidth, 
    double canvasHeight,
    double thumbnailWidth,
    double thumbnailHeight,
  ) {
    final scaleX = thumbnailWidth / canvasWidth;
    final scaleY = thumbnailHeight / canvasHeight;
    
    final scaledLeft = element.position.dx * scaleX;
    final scaledTop = element.position.dy * scaleY;
    final scaledWidth = element.size.width * scaleX;
    final scaledHeight = element.size.height * scaleY;
    
    if (scaledWidth < 2 || scaledHeight < 2) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      left: scaledLeft,
      top: scaledTop,
      width: scaledWidth,
      height: scaledHeight,
      child: Transform.rotate(
        angle: element.rotation,
        child: _buildElementThumbnailContent(element, scaledWidth, scaledHeight),
      ),
    );
  }

  Widget _buildElementThumbnailContent(PageElement element, double width, double height) {
    switch (element.type) {
      case ElementType.text:
        return Container(
          color: Colors.white.withValues(alpha:0.8),
          padding: const EdgeInsets.all(1),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              element.properties['text']?.toString() ?? '',
              style: const TextStyle(fontSize: 4, color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      
      case ElementType.image:
        final imageUrl = element.properties['imageUrl'];
        if (imageUrl == null) return const SizedBox.shrink();
        
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.image, size: 8),
          ),
        );
      
      case ElementType.shape:
        return Container(
          decoration: BoxDecoration(
            color: _parseColor(element.properties['color']),
            borderRadius: _getShapeRadius(element.properties['shapeType']),
          ),
        );
      
      case ElementType.audio:
        return Container(
          color: const Color(0xFF2C3E50),
          child: const Center(
            child: Icon(Icons.audiotrack, size: 8, color: Colors.white),
          ),
        );
      
      case ElementType.video:
        return Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.play_circle_outline, size: 8, color: Colors.white),
          ),
        );
      
      default:
        return Container(
          color: Colors.grey.shade400,
        );
    }
  }

  BorderRadius? _getShapeRadius(dynamic shapeType) {
    if (shapeType == null) return null;
    
    final type = shapeType is String ? shapeType : shapeType.toString();
    
    if (type.contains('circle')) {
      return BorderRadius.circular(100);
    }
    
    return null;
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
      debugPrint('Error parsing color in thumbnail: $colorValue');
    }
    return Colors.blue;
  }
}
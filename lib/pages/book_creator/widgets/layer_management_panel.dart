// lib/pages/book_creator/widgets/layer_management_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';

class LayerManagementPanel extends ConsumerStatefulWidget {
  final Color panelColor;
  final Color textColor;
  final String? selectedElementId;
  final Function(String) onElementSelected;
  final Function(List<PageElement>) onLayerOrderChanged;

  const LayerManagementPanel({
    super.key,
    required this.panelColor,
    required this.textColor,
    this.selectedElementId,
    required this.onElementSelected,
    required this.onLayerOrderChanged,
  });

  @override
  ConsumerState<LayerManagementPanel> createState() => _LayerManagementPanelState();
}

class _LayerManagementPanelState extends ConsumerState<LayerManagementPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final bookId = ref.watch(currentBookIdProvider);
    if (bookId == null) return const SizedBox.shrink();

    final pagesAsync = ref.watch(bookPagesProvider);
    final pageIndex = ref.watch(currentPageIndexProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 280 : 60,
      decoration: BoxDecoration(
        color: widget.panelColor,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
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
          if (_isExpanded) ...[
            Expanded(
              child: pagesAsync.when(
                data: (pages) {
                  if (pages.isEmpty || pageIndex >= pages.length) {
                    return _buildEmptyState();
                  }

                  final currentPage = pages[pageIndex];
                  if (currentPage.elements.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildLayersList(currentPage, bookId);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.layers,
            color: widget.textColor,
            size: 20,
          ),
          if (_isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Layers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.textColor,
                ),
              ),
            ),
          ],
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              color: widget.textColor,
            ),
            onPressed: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            tooltip: _isExpanded ? 'Collapse' : 'Expand',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No layers yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add elements to see them here',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayersList(BookPage currentPage, String bookId) {
    // Reverse the list to show top layer first
    final reversedElements = currentPage.elements.reversed.toList();

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: reversedElements.length,
      onReorder: (oldIndex, newIndex) {
        _handleReorder(oldIndex, newIndex, reversedElements, currentPage);
      },
      itemBuilder: (context, index) {
        final element = reversedElements[index];
        final isSelected = widget.selectedElementId == element.id;
        final layerNumber = reversedElements.length - index;

        return _buildLayerItem(
          key: ValueKey(element.id),
          element: element,
          isSelected: isSelected,
          layerNumber: layerNumber,
          currentPage: currentPage,
          bookId: bookId,
        );
      },
    );
  }

  Widget _buildLayerItem({
    required Key key,
    required PageElement element,
    required bool isSelected,
    required int layerNumber,
    required BookPage currentPage,
    required String bookId,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getElementIcon(element.type),
            color: isSelected ? Colors.white : widget.textColor,
            size: 20,
          ),
        ),
        title: Text(
          _getElementName(element, layerNumber),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: widget.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _getElementSubtitle(element),
          style: TextStyle(
            fontSize: 11,
            color: widget.textColor.withValues(alpha:0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: widget.textColor,
            size: 20,
          ),
          onSelected: (value) {
            _handleLayerAction(value, element, currentPage, bookId);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'bring_forward',
              child: Row(
                children: [
                  Icon(Icons.arrow_upward, size: 18),
                  SizedBox(width: 8),
                  Text('Bring Forward'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'send_backward',
              child: Row(
                children: [
                  Icon(Icons.arrow_downward, size: 18),
                  SizedBox(width: 8),
                  Text('Send Backward'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'bring_to_front',
              child: Row(
                children: [
                  Icon(Icons.vertical_align_top, size: 18),
                  SizedBox(width: 8),
                  Text('Bring to Front'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'send_to_back',
              child: Row(
                children: [
                  Icon(Icons.vertical_align_bottom, size: 18),
                  SizedBox(width: 8),
                  Text('Send to Back'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 18),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => widget.onElementSelected(element.id),
      ),
    );
  }

  void _handleReorder(
    int oldIndex,
    int newIndex,
    List<PageElement> reversedElements,
    BookPage currentPage,
  ) {
    // Adjust indices if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Create new order
    final List<PageElement> newOrder = List.from(reversedElements);
    final element = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, element);

    // Reverse back to original order
    final finalOrder = newOrder.reversed.toList();

    // Notify parent
    widget.onLayerOrderChanged(finalOrder);
  }

  void _handleLayerAction(
    String action,
    PageElement element,
    BookPage currentPage,
    String bookId,
  ) {
    final elements = currentPage.elements;
    final currentIndex = elements.indexWhere((e) => e.id == element.id);

    if (currentIndex == -1) return;

    List<PageElement> newOrder = List.from(elements);

    switch (action) {
      case 'bring_forward':
        if (currentIndex < elements.length - 1) {
          final temp = newOrder[currentIndex];
          newOrder[currentIndex] = newOrder[currentIndex + 1];
          newOrder[currentIndex + 1] = temp;
          widget.onLayerOrderChanged(newOrder);
        }
        break;

      case 'send_backward':
        if (currentIndex > 0) {
          final temp = newOrder[currentIndex];
          newOrder[currentIndex] = newOrder[currentIndex - 1];
          newOrder[currentIndex - 1] = temp;
          widget.onLayerOrderChanged(newOrder);
        }
        break;

      case 'bring_to_front':
        newOrder.removeAt(currentIndex);
        newOrder.add(element);
        widget.onLayerOrderChanged(newOrder);
        break;

      case 'send_to_back':
        newOrder.removeAt(currentIndex);
        newOrder.insert(0, element);
        widget.onLayerOrderChanged(newOrder);
        break;

      case 'duplicate':
        _duplicateElement(element, currentPage);
        break;

      case 'delete':
        _deleteElement(element, currentPage);
        break;
    }
  }

  Future<void> _duplicateElement(PageElement element, BookPage currentPage) async {
    final pageActions = ref.read(pageActionsProvider);
    
    final newElement = PageElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: element.type,
      position: Offset(element.position.dx + 20, element.position.dy + 20),
      size: element.size,
      rotation: element.rotation,
      properties: Map.from(element.properties),
      textStyle: element.textStyle,
      textAlign: element.textAlign,
      lineHeight: element.lineHeight,
      shadows: element.shadows,
    );

    await pageActions.addElement(currentPage.id, newElement);
    widget.onElementSelected(newElement.id);
  }

  Future<void> _deleteElement(PageElement element, BookPage currentPage) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Layer'),
        content: const Text('Are you sure you want to delete this layer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final pageActions = ref.read(pageActionsProvider);
      await pageActions.removeElement(currentPage.id, element.id);
    }
  }

  IconData _getElementIcon(ElementType type) {
    switch (type) {
      case ElementType.text:
        return Icons.text_fields;
      case ElementType.image:
        return Icons.image;
      case ElementType.shape:
        return Icons.crop_square;
      default:
        return Icons.layers;
    }
  }

  String _getElementName(PageElement element, int layerNumber) {
    switch (element.type) {
      case ElementType.text:
        final text = element.properties['text'] as String? ?? '';
        return text.isEmpty ? 'Text Layer $layerNumber' : text;
      case ElementType.image:
        return 'Image Layer $layerNumber';
      case ElementType.shape:
        final shapeType = element.properties['shapeType'];
        return '$shapeType Layer $layerNumber';
      default:
        return 'Layer $layerNumber';
    }
  }

  String _getElementSubtitle(PageElement element) {
    switch (element.type) {
      case ElementType.text:
        return 'Text • ${element.size.width.toInt()} x ${element.size.height.toInt()}';
      case ElementType.image:
        return 'Image • ${element.size.width.toInt()} x ${element.size.height.toInt()}';
      case ElementType.shape:
        return 'Shape • ${element.size.width.toInt()} x ${element.size.height.toInt()}';
      default:
        return '${element.size.width.toInt()} x ${element.size.height.toInt()}';
    }
  }
}
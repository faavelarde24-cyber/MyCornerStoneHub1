// lib/pages/book_creator/widgets/properties_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';

class PropertiesPanel extends ConsumerStatefulWidget {
  final String bookId;
  final String? selectedElementId;
  final Color panelColor;
  final Color textColor;
  final Map<String, PageElement> localElementCache;
  final Function(PageElement, TextStyle) onUpdateTextStyle;
  final Function(PageElement, TextAlign) onUpdateTextAlign;
  final Function(PageElement, double) onUpdateLineHeight;
  final Function(PageElement, List<Shadow>) onUpdateShadows;
  final Function(PageElement) onEditText;
  final Function(String) onElementSelected;
  final Function(List<PageElement>) onLayerOrderChanged;
  final VoidCallback? onPanelToggle;

  const PropertiesPanel({
    super.key,
    required this.bookId,
    required this.selectedElementId,
    required this.panelColor,
    required this.textColor,
    required this.localElementCache,
    required this.onUpdateTextStyle,
    required this.onUpdateTextAlign,
    required this.onUpdateLineHeight,
    required this.onUpdateShadows,
    required this.onEditText,
    required this.onElementSelected,
    required this.onLayerOrderChanged,
    this.onPanelToggle,
  });

  @override
  ConsumerState<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends ConsumerState<PropertiesPanel> with SingleTickerProviderStateMixin {
  double? _currentSliderValue;
  double? _currentLineHeightValue;
  late TabController _tabController;
  bool _isExpanded = true;

  // Collapse state for property sections (resets when element changes)
  final Map<String, bool> _collapsedSections = {
    'font_family': false,
    'font_size': false,
    'alignment': false,
    'line_spacing': false,
    'text_style': false,
    'text_color': false,
    'text_effects': false,
  };

  final List<String> _fontFamilies = [
    'Roboto', 'Arial', 'Times New Roman', 'Courier New', 'Georgia',
    'Verdana', 'Comic Sans MS', 'Trebuchet MS', 'Impact', 'Palatino',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset collapse state when switching to a different element (Non-Persistent)
    if (oldWidget.selectedElementId != widget.selectedElementId) {
      setState(() {
        _collapsedSections.updateAll((key, value) => false);
      });
    }
  }


  void _toggleSection(String sectionKey) {
    setState(() {
      _collapsedSections[sectionKey] = !(_collapsedSections[sectionKey] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(bookPagesProvider(widget.bookId));
    final pageIndex = ref.watch(currentPageIndexProvider);

return Container(
  width: _isExpanded ? 320 : 60,
  decoration: BoxDecoration(
    color: widget.panelColor,
    border: Border(left: BorderSide(color: Colors.grey.shade300)),
  ),
  child: Column(
    children: [
      _buildHeader(),
      if (_isExpanded) _buildTabBar(),
      if (_isExpanded)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPropertiesTab(pagesAsync, pageIndex),
              _buildLayersTab(pagesAsync, pageIndex),
            ],
          ),
        )
      else
        Expanded(
          child: Center(
            child: _buildCollapsedIcon(),
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
          Icon(Icons.tune, color: widget.textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Properties',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.textColor,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() => _isExpanded = false);
              
              // ✅ Trigger callback after animation
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
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _isExpanded = true);
                  
                  // ✅ Trigger callback after animation
                  Future.delayed(const Duration(milliseconds: 300), () {
                    widget.onPanelToggle?.call();
                  });
                },
                tooltip: 'Expand Properties',
                color: widget.textColor,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildCollapsedIcon() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.tune,
          color: widget.textColor.withValues(alpha: 0.6),
          size: 24,
        ),
        const SizedBox(height: 8),
        RotatedBox(
          quarterTurns: -1,
          child: Text(
            'Properties',
            style: TextStyle(
              fontSize: 12,
              color: widget.textColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTabBar() {
  return Container(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
    ),
    child: TabBar(
      controller: _tabController,
      labelColor: Colors.blue,
      unselectedLabelColor: widget.textColor.withValues(alpha: 0.6),
      indicatorColor: Colors.blue,
      tabs: const [
        Tab(icon: Icon(Icons.tune, size: 20), text: 'Properties'),
        Tab(icon: Icon(Icons.layers, size: 20), text: 'Layers'),
      ],
    ),
  );
}

Widget _buildPropertiesTab(AsyncValue<List<BookPage>> pagesAsync, int pageIndex) {
  // 🚀 NEW: If element is in cache, use it directly WITHOUT waiting for provider
  if (widget.selectedElementId != null && 
      widget.localElementCache.containsKey(widget.selectedElementId!)) {
    
    debugPrint('🎯 [PropertiesPanel] Using CACHED element (skipping provider): ${widget.selectedElementId}');
    
    final cachedElement = widget.localElementCache[widget.selectedElementId!]!;
    return SingleChildScrollView(
      child: _buildElementProperties(cachedElement, widget.textColor, 'cached'),
    );
  }
  
  // 🚀 ONLY use provider when cache doesn't exist
  return pagesAsync.when(
    data: (pages) {
      if (pages.isEmpty || pageIndex >= pages.length) {
        return _buildEmptyPropertiesState();
      }

      final currentPage = pages[pageIndex];
      PageElement? selectedElement;

      if (widget.selectedElementId != null) {
        try {
          selectedElement = currentPage.elements.firstWhere(
            (e) => e.id == widget.selectedElementId
          );
          debugPrint('📋 [PropertiesPanel] Using PROVIDER element: ${widget.selectedElementId}');
        } catch (_) {
          debugPrint('⚠️ [PropertiesPanel] Element not found: ${widget.selectedElementId}');
        }
      }

      return selectedElement != null
          ? _buildElementProperties(selectedElement, widget.textColor, currentPage.id)
          : _buildEmptyPropertiesState();
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, _) => Center(child: Text('Error', style: TextStyle(color: widget.textColor))),
  );
}
  Widget _buildLayersTab(AsyncValue<List<BookPage>> pagesAsync, int pageIndex) {
    return pagesAsync.when(
      data: (pages) {
        if (pages.isEmpty || pageIndex >= pages.length) {
          return _buildEmptyLayersState();
        }

        final currentPage = pages[pageIndex];
        if (currentPage.elements.isEmpty) {
          return _buildEmptyLayersState();
        }

        return _buildLayersList(currentPage);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildEmptyPropertiesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 64, color: widget.textColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Select an element\nto edit properties',
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.textColor.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLayersState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_outlined, size: 48, color: Colors.grey.shade400),
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
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayersList(BookPage currentPage) {
    final reversedElements = currentPage.elements.reversed.toList();

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: reversedElements.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;

        final List<PageElement> newOrder = List.from(reversedElements);
        final element = newOrder.removeAt(oldIndex);
        newOrder.insert(newIndex, element);

        final finalOrder = newOrder.reversed.toList();
        widget.onLayerOrderChanged(finalOrder);
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
        leading: Stack(
          children: [
            Container(
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
            // Lock indicator
            if (element.locked)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
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
            color: widget.textColor.withValues(alpha: 0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: widget.textColor, size: 20),
          onSelected: (value) => _handleLayerAction(value, element, currentPage),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'bring_to_front',
              child: Row(children: [
                Icon(Icons.vertical_align_top, size: 18),
                SizedBox(width: 8),
                Text('Bring to Front'),
              ]),
            ),
            const PopupMenuItem(
              value: 'bring_forward',
              child: Row(children: [
                Icon(Icons.arrow_upward, size: 18),
                SizedBox(width: 8),
                Text('Bring Forward'),
              ]),
            ),
            const PopupMenuItem(
              value: 'send_backward',
              child: Row(children: [
                Icon(Icons.arrow_downward, size: 18),
                SizedBox(width: 8),
                Text('Send Backward'),
              ]),
            ),
            const PopupMenuItem(
              value: 'send_to_back',
              child: Row(children: [
                Icon(Icons.vertical_align_bottom, size: 18),
                SizedBox(width: 8),
                Text('Send to Back'),
              ]),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'toggle_lock',
              child: Row(children: [
                Icon(
                  element.locked ? Icons.lock_open : Icons.lock,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(element.locked ? 'Unlock Layer' : 'Lock Layer'),
              ]),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(children: [
                Icon(Icons.copy, size: 18),
                SizedBox(width: 8),
                Text('Duplicate'),
              ]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
        onTap: () => widget.onElementSelected(element.id),
      ),
    );
  }

  void _handleLayerAction(String action, PageElement element, BookPage currentPage) async {
    final pageActions = ref.read(pageActionsProvider);
    final elements = currentPage.elements;
    final currentIndex = elements.indexWhere((e) => e.id == element.id);

    if (currentIndex == -1) return;

    List<PageElement>? newOrder;

    switch (action) {
      case 'bring_to_front':
        // Move to end of list (top layer)
        newOrder = List.from(elements);
        newOrder.removeAt(currentIndex);
        newOrder.add(element);
        break;

      case 'bring_forward':
        // Move up one position
        if (currentIndex < elements.length - 1) {
          newOrder = List.from(elements);
          newOrder.removeAt(currentIndex);
          newOrder.insert(currentIndex + 1, element);
        }
        break;

      case 'send_backward':
        // Move down one position
        if (currentIndex > 0) {
          newOrder = List.from(elements);
          newOrder.removeAt(currentIndex);
          newOrder.insert(currentIndex - 1, element);
        }
        break;

      case 'send_to_back':
        // Move to start of list (bottom layer)
        newOrder = List.from(elements);
        newOrder.removeAt(currentIndex);
        newOrder.insert(0, element);
        break;

      case 'toggle_lock':
        await pageActions.toggleElementLock(currentPage.id, element.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(element.locked ? 'Layer unlocked' : 'Layer locked'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
        return;

      case 'duplicate':
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
          locked: false,
        );
        await pageActions.addElement(currentPage.id, newElement);
        widget.onElementSelected(newElement.id);
        return;

      case 'delete':
        // Prevent deleting locked elements
        if (element.locked) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot delete locked layer. Unlock it first.'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
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
          await pageActions.removeElement(currentPage.id, element.id);
        }
        return;
    }

    // Apply layer reordering
    if (newOrder != null) {
      await pageActions.reorderElements(currentPage.id, newOrder);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layer order updated'),
            duration: Duration(seconds: 1),
          ),
        );
      }
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
      case ElementType.audio:
        return Icons.audiotrack;
      case ElementType.video:
        return Icons.videocam;
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
      case ElementType.audio:
        final title = element.properties['title'] as String?;
        return title ?? 'Audio Layer $layerNumber';
      case ElementType.video:
        return 'Video Layer $layerNumber';
      default:
        return 'Layer $layerNumber';
    }
  }

  String _getElementSubtitle(PageElement element) => '${element.size.width.toInt()} x ${element.size.height.toInt()}';

  // ====== COLLAPSIBLE SECTIONS ======
  Widget _buildCollapsibleSection({
    required String sectionKey,
    required String title,
    required Widget child,
  }) {
    final isCollapsed = _collapsedSections[sectionKey] ?? false;

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleSection(sectionKey),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  isCollapsed ? Icons.add : Icons.remove,
                  size: 18,
                  color: widget.textColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.textColor,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: child,
          ),
          crossFadeState: isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ====== TEXT PROPERTIES (WITH COLLAPSE) ======
  Widget _buildElementProperties(PageElement element, Color textColor, String pageId) {
    if (element.type == ElementType.text) {
      return _buildTextProperties(element, textColor);
    } else if (element.type == ElementType.image) {
      return _buildImageProperties(element, textColor);
    } else if (element.type == ElementType.audio) {
      return _buildAudioProperties(element, textColor);
    } else if (element.type == ElementType.video) {
      return _buildVideoProperties(element, textColor);
    }
    return const SizedBox();
  }

Widget _buildTextProperties(PageElement element, Color textColor) {
  // ✅ CRITICAL: Use cached element if available for ALL property reads
  final displayElement = widget.localElementCache[element.id] ?? element;
  
  final double elementFontSize = displayElement.textStyle?.fontSize ?? 18.0;
  final double displayFontSize = _currentSliderValue ?? elementFontSize;
  final double elementLineHeight = displayElement.lineHeight ?? 1.2;
  final double displayLineHeight = _currentLineHeightValue ?? elementLineHeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionButton(
            icon: Icons.edit,
            label: 'Edit Text Content',
            onPressed: () => widget.onEditText(element),
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          
          _buildCollapsibleSection(
            sectionKey: 'font_family',
            title: 'Font Family',
            child: _buildFontFamilyDropdown(element, textColor),
          ),
          
          _buildCollapsibleSection(
            sectionKey: 'font_size',
            title: 'Font Size',
            child: Column(
              children: [
                _buildFontSizeSlider(element, displayFontSize, textColor),
                const SizedBox(height: 8),
                _buildQuickSizeButtons(element),
              ],
            ),
          ),
          
          _buildCollapsibleSection(
            sectionKey: 'alignment',
            title: 'Text Alignment',
            child: _buildAlignmentButtons(element, textColor),
          ),
          
          _buildCollapsibleSection(
            sectionKey: 'line_spacing',
            title: 'Line Spacing',
            child: _buildLineHeightSlider(element, displayLineHeight, textColor),
          ),
          
          _buildCollapsibleSection(
            sectionKey: 'text_style',
            title: 'Text Style',
            child: _buildTextStyleButtons(element, textColor),
          ),
          
          _buildCollapsibleSection(
            sectionKey: 'text_color',
            title: 'Text Color',
            child: _buildColorPicker(element, textColor),
          ),
          
          _buildCollapsibleSection(
            sectionKey: 'text_effects',
            title: 'Text Effects',
            child: _buildShadowControls(element, textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildImageProperties(PageElement element, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Image Properties', textColor),
          const SizedBox(height: 16),
          Text(
            'Size: ${element.size.width.round()} x ${element.size.height.round()}',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Position: (${element.position.dx.round()}, ${element.position.dy.round()})',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioProperties(PageElement element, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Audio Properties', textColor),
          const SizedBox(height: 16),
          Text(
            'Title: ${element.properties['title'] ?? 'Audio'}',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Size: ${element.size.width.round()} x ${element.size.height.round()}',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoProperties(PageElement element, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Video Properties', textColor),
          const SizedBox(height: 16),
          Text(
            'Size: ${element.size.width.round()} x ${element.size.height.round()}',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: textColor,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSectionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

Widget _buildFontFamilyDropdown(PageElement element, Color textColor) {
  final currentFont = element.textStyle?.fontFamily ?? 'Roboto';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(8),
    ),
    child: DropdownButton<String>(
      value: _fontFamilies.contains(currentFont) ? currentFont : _fontFamilies[0],
      isExpanded: true,
      underline: const SizedBox(),
      items: _fontFamilies
          .map((font) => DropdownMenuItem(
                value: font,
                child: Text(font, style: TextStyle(fontFamily: font)),
              ))
          .toList(),
      onChanged: (newFont) {
        if (newFont != null) {
          // ✅ IMMEDIATE: Update via callback
          final newStyle = (element.textStyle ?? const TextStyle()).copyWith(fontFamily: newFont);
          widget.onUpdateTextStyle(element, newStyle);
        }
      },
    ),
  );
}


Widget _buildFontSizeSlider(PageElement element, double displayValue, Color textColor) {
  return Row(
    children: [
      Expanded(
        child: Slider(
          value: displayValue.clamp(8.0, 200.0),
          min: 8,
          max: 200,
          divisions: 192,
          label: '${displayValue.round()}',
          onChanged: (value) {
            // ✅ IMMEDIATE: Update local UI state (no database call)
            setState(() {
              _currentSliderValue = value;
            });
            
            // ✅ OPTIMISTIC: Update parent's local state map immediately
            final newStyle = (element.textStyle ?? const TextStyle()).copyWith(fontSize: value);
            widget.onUpdateTextStyle(element, newStyle);
          },
          onChangeEnd: (value) {
            // ✅ CLEANUP: Just clear the local slider state
            // Database write already happened via debounced updateElement
            if (mounted) {
              setState(() {
                _currentSliderValue = null;
              });
            }
          },
        ),
      ),
      Container(
        width: 50,
        alignment: Alignment.center,
        child: Text(
          '${displayValue.round()}',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}

Widget _buildQuickSizeButtons(PageElement element) {
  return Wrap(
    spacing: 8,
    children: [12, 18, 24, 32, 48, 64].map((size) {
      final isSelected = (element.textStyle?.fontSize ?? 18).round() == size;
      return ElevatedButton(
        onPressed: () {
          // ✅ IMMEDIATE: Update via callback (no waiting)
          final newStyle = (element.textStyle ?? const TextStyle()).copyWith(fontSize: size.toDouble());
          widget.onUpdateTextStyle(element, newStyle);
          
          // ✅ CLEANUP: Clear slider state
          if (mounted) {
            setState(() {
              _currentSliderValue = null;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          minimumSize: const Size(45, 36),
          padding: EdgeInsets.zero,
          elevation: isSelected ? 3 : 1,
        ),
        child: Text(size.toString(), style: const TextStyle(fontSize: 12)),
      );
    }).toList(),
  );
}

  Widget _buildAlignmentButtons(PageElement element, Color textColor) {
    final currentAlign = element.textAlign ?? TextAlign.left;
    return Row(
      children: [
        Expanded(child: _buildAlignButton(Icons.format_align_left, TextAlign.left, currentAlign, element)),
        const SizedBox(width: 8),
        Expanded(child: _buildAlignButton(Icons.format_align_center, TextAlign.center, currentAlign, element)),
        const SizedBox(width: 8),
        Expanded(child: _buildAlignButton(Icons.format_align_right, TextAlign.right, currentAlign, element)),
        const SizedBox(width: 8),
        Expanded(child: _buildAlignButton(Icons.format_align_justify, TextAlign.justify, currentAlign, element)),
      ],
    );
  }

Widget _buildAlignButton(IconData icon, TextAlign align, TextAlign currentAlign, PageElement element) {
  final isSelected = currentAlign == align;
  return IconButton(
    icon: Icon(icon),
    onPressed: () {
      // ✅ IMMEDIATE: No delays, no invalidations
      widget.onUpdateTextAlign(element, align);
    },
    style: IconButton.styleFrom(
      backgroundColor: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.grey.shade200,
      foregroundColor: isSelected ? Colors.blue : Colors.grey.shade700,
    ),
  );
}

Widget _buildLineHeightSlider(PageElement element, double displayValue, Color textColor) {
  return Row(
    children: [
      Expanded(
        child: Slider(
          value: displayValue.clamp(0.5, 3.0),
          min: 0.5,
          max: 3.0,
          divisions: 25,
          label: displayValue.toStringAsFixed(1),
          onChanged: (value) {
            // ✅ IMMEDIATE: Update local state
            setState(() => _currentLineHeightValue = value);
            
            // ✅ OPTIMISTIC: Update parent immediately
            widget.onUpdateLineHeight(element, value);
          },
          onChangeEnd: (value) {
            // ✅ CLEANUP: Clear local state
            if (mounted) {
              setState(() {
                _currentLineHeightValue = null;
              });
            }
          },
        ),
      ),
      Container(
        width: 50,
        alignment: Alignment.center,
        child: Text(
          displayValue.toStringAsFixed(1),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}

Widget _buildTextStyleButtons(PageElement element, Color textColor) {
  // ✅ Use cached element for instant bold/italic/underline highlighting
  final displayElement = widget.localElementCache[element.id] ?? element;
  
  return Row(
    children: [
      // Bold
      Expanded(
        child: _buildStyleButton(
          icon: Icons.format_bold,
          isActive: (displayElement.textStyle?.fontWeight ?? FontWeight.normal) == FontWeight.bold,
          onPressed: () {
            // ✅ IMMEDIATE: No delays
            final isBold = element.textStyle?.fontWeight == FontWeight.bold;
            final newStyle = (element.textStyle ?? const TextStyle()).copyWith(
              fontWeight: isBold ? FontWeight.normal : FontWeight.bold
            );
            widget.onUpdateTextStyle(element, newStyle);
          },
        ),
      ),
      const SizedBox(width: 8),
      // Italic
      Expanded(
        child: _buildStyleButton(
          icon: Icons.format_italic,
          isActive: (element.textStyle?.fontStyle ?? FontStyle.normal) == FontStyle.italic,
          onPressed: () {
            // ✅ IMMEDIATE
            final isItalic = element.textStyle?.fontStyle == FontStyle.italic;
            final newStyle = (element.textStyle ?? const TextStyle()).copyWith(
              fontStyle: isItalic ? FontStyle.normal : FontStyle.italic
            );
            widget.onUpdateTextStyle(element, newStyle);
          },
        ),
      ),
      const SizedBox(width: 8),
      // Underline
      Expanded(
        child: _buildStyleButton(
          icon: Icons.format_underlined,
          isActive: element.textStyle?.decoration == TextDecoration.underline,
          onPressed: () {
            // ✅ IMMEDIATE
            final isUnderlined = element.textStyle?.decoration == TextDecoration.underline;
            final newStyle = (element.textStyle ?? const TextStyle()).copyWith(
              decoration: isUnderlined ? TextDecoration.none : TextDecoration.underline
            );
            widget.onUpdateTextStyle(element, newStyle);
          },
        ),
      ),
    ],
  );
}

Widget _buildStyleButton({required IconData icon, required bool isActive, required VoidCallback onPressed}) {
  return IconButton(
    icon: Icon(icon),
    onPressed: onPressed, // ✅ Callback already optimized in _buildTextStyleButtons
    style: IconButton.styleFrom(
      backgroundColor: isActive ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
      foregroundColor: isActive ? Colors.blue : Colors.grey.shade700,
      side: BorderSide(color: isActive ? Colors.blue : Colors.grey.shade400, width: isActive ? 2 : 1),
    ),
  );
}


Widget _buildColorPicker(PageElement element, Color textColor) {
  final colors = [
    Colors.black, Colors.white, Colors.red, Colors.blue,
    Colors.green, Colors.orange, Colors.purple, Colors.pink,
    Colors.teal, Colors.amber, Colors.indigo, Colors.brown,
  ];
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: colors.map((color) {
      final isSelected = (element.textStyle?.color ?? Colors.black) == color;
      return GestureDetector(
        onTap: () {
          // ✅ IMMEDIATE: No delays
          final newStyle = (element.textStyle ?? const TextStyle()).copyWith(color: color);
          widget.onUpdateTextStyle(element, newStyle);
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade400,
              width: isSelected ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 20,
                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                )
              : null,
        ),
      );
    }).toList(),
  );
}

Widget _buildShadowControls(PageElement element, Color textColor) {


  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SwitchListTile(
        title: Text('Text Shadow', style: TextStyle(fontSize: 13, color: textColor)),
        value: element.shadows != null && element.shadows!.isNotEmpty,
        onChanged: (value) {
          // ✅ IMMEDIATE
          if (value) {
            widget.onUpdateShadows(element, [
              const Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4)
            ]);
          } else {
            widget.onUpdateShadows(element, []);
          }
        },
        contentPadding: EdgeInsets.zero,
      ),
      if (element.shadows != null && element.shadows!.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('Shadow Intensity', style: TextStyle(fontSize: 11, color: textColor)),
        Slider(
          value: element.shadows!.first.blurRadius.clamp(0.0, 20.0),
          min: 0,
          max: 20,
          onChanged: (value) {
            // ✅ IMMEDIATE
            final currentShadow = element.shadows!.first;
            widget.onUpdateShadows(element, [
              Shadow(color: currentShadow.color, offset: currentShadow.offset, blurRadius: value)
            ]);
          },
        ),
      ],
    ],
  );
}
}
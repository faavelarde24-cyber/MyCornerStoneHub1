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
  final Function(PageElement, TextStyle) onUpdateTextStyle;
  final Function(PageElement, TextAlign) onUpdateTextAlign;
  final Function(PageElement, double) onUpdateLineHeight;
  final Function(PageElement, List<Shadow>) onUpdateShadows;
  final Function(PageElement) onEditText;
  final VoidCallback onClearSliderState;
  final Function(String) onElementSelected;
  final Function(List<PageElement>) onLayerOrderChanged;

  const PropertiesPanel({
    super.key,
    required this.bookId,
    required this.selectedElementId,
    required this.panelColor,
    required this.textColor,
    required this.onUpdateTextStyle,
    required this.onUpdateTextAlign,
    required this.onUpdateLineHeight,
    required this.onUpdateShadows,
    required this.onEditText,
    required this.onClearSliderState,
    required this.onElementSelected,
    required this.onLayerOrderChanged,
  });

  @override
  ConsumerState<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends ConsumerState<PropertiesPanel> with SingleTickerProviderStateMixin {
  double? _currentSliderValue;
  double? _currentLineHeightValue;
  late TabController _tabController;

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

  void _clearSliderState() {
    if (_currentSliderValue != null || _currentLineHeightValue != null) {
      setState(() {
        _currentSliderValue = null;
        _currentLineHeightValue = null;
      });
    }
    widget.onClearSliderState();
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(bookPagesProvider);
    final pageIndex = ref.watch(currentPageIndexProvider);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: widget.panelColor,
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPropertiesTab(pagesAsync, pageIndex),
                _buildLayersTab(pagesAsync, pageIndex),
              ],
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
    return pagesAsync.when(
      data: (pages) {
        if (pages.isEmpty || pageIndex >= pages.length) {
          return Center(child: Text('No page', style: TextStyle(color: widget.textColor)));
        }

        final currentPage = pages[pageIndex];
        PageElement? selectedElement;

        if (widget.selectedElementId != null) {
          try {
            selectedElement = currentPage.elements.firstWhere((e) => e.id == widget.selectedElementId);
          } catch (_) {}
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
            color: widget.textColor.withValues(alpha: 0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: widget.textColor, size: 20),
          onSelected: (value) => _handleLayerAction(value, element, currentPage),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy, size: 18), SizedBox(width: 8), Text('Duplicate')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
          ],
        ),
        onTap: () => widget.onElementSelected(element.id),
      ),
    );
  }

  void _handleLayerAction(String action, PageElement element, BookPage currentPage) async {
    final pageActions = ref.read(pageActionsProvider);

    switch (action) {
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
        );
        await pageActions.addElement(currentPage.id, newElement);
        widget.onElementSelected(newElement.id);
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Layer'),
            content: const Text('Are you sure you want to delete this layer?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await pageActions.removeElement(currentPage.id, element.id);
        }
        break;
    }
  }

  IconData _getElementIcon(ElementType type) {
    switch (type) {
      case ElementType.text: return Icons.text_fields;
      case ElementType.image: return Icons.image;
      case ElementType.shape: return Icons.crop_square;
      default: return Icons.layers;
    }
  }

  String _getElementName(PageElement element, int layerNumber) {
    switch (element.type) {
      case ElementType.text:
        final text = element.properties['text'] as String? ?? '';
        return text.isEmpty ? 'Text Layer $layerNumber' : text;
      case ElementType.image: return 'Image Layer $layerNumber';
      case ElementType.shape:
        final shapeType = element.properties['shapeType'];
        return '$shapeType Layer $layerNumber';
      default: return 'Layer $layerNumber';
    }
  }

  String _getElementSubtitle(PageElement element) => '${element.size.width.toInt()} x ${element.size.height.toInt()}';

  // ====== TEXT PROPERTIES (Same as before) ======
  Widget _buildElementProperties(PageElement element, Color textColor, String pageId) {
    if (element.type == ElementType.text) {
      return _buildTextProperties(element, textColor);
    } else if (element.type == ElementType.image) {
      return _buildImageProperties(element, textColor);
    }
    return const SizedBox();
  }

  Widget _buildTextProperties(PageElement element, Color textColor) {
    final double elementFontSize = element.textStyle?.fontSize ?? 18.0;
    final double displayFontSize = _currentSliderValue ?? elementFontSize;
    final double elementLineHeight = element.lineHeight ?? 1.2;
    final double displayLineHeight = _currentLineHeightValue ?? elementLineHeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionButton(icon: Icons.edit, label: 'Edit Text Content', onPressed: () => widget.onEditText(element), color: Colors.blue),
          const SizedBox(height: 20),
          _buildSectionTitle('Font Family', textColor),
          const SizedBox(height: 8),
          _buildFontFamilyDropdown(element, textColor),
          const SizedBox(height: 20),
          _buildSectionTitle('Font Size', textColor),
          const SizedBox(height: 8),
          _buildFontSizeSlider(element, displayFontSize, textColor),
          const SizedBox(height: 8),
          _buildQuickSizeButtons(element),
          const SizedBox(height: 20),
          _buildSectionTitle('Text Alignment', textColor),
          const SizedBox(height: 8),
          _buildAlignmentButtons(element, textColor),
          const SizedBox(height: 20),
          _buildSectionTitle('Line Spacing', textColor),
          const SizedBox(height: 8),
          _buildLineHeightSlider(element, displayLineHeight, textColor),
          const SizedBox(height: 20),
          _buildSectionTitle('Text Style', textColor),
          const SizedBox(height: 8),
          _buildTextStyleButtons(element, textColor),
          const SizedBox(height: 20),
          _buildSectionTitle('Text Color', textColor),
          const SizedBox(height: 8),
          _buildColorPicker(element, textColor),
          const SizedBox(height: 20),
          _buildSectionTitle('Text Effects', textColor),
          const SizedBox(height: 8),
          _buildShadowControls(element, textColor),
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
          Text('Size: ${element.size.width.round()} x ${element.size.height.round()}', style: TextStyle(color: textColor, fontSize: 12)),
          const SizedBox(height: 8),
          Text('Position: (${element.position.dx.round()}, ${element.position.dy.round()})', style: TextStyle(color: textColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 13, letterSpacing: 0.5));
  }

  Widget _buildSectionButton({required IconData icon, required String label, required VoidCallback onPressed, required Color color}) {
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
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
      child: DropdownButton<String>(
        value: _fontFamilies.contains(currentFont) ? currentFont : _fontFamilies[0],
        isExpanded: true,
        underline: const SizedBox(),
        items: _fontFamilies.map((font) => DropdownMenuItem(value: font, child: Text(font, style: TextStyle(fontFamily: font)))).toList(),
        onChanged: (newFont) {
          if (newFont != null) {
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
            min: 8, max: 200, divisions: 192,
            label: '${displayValue.round()}',
            onChanged: (value) => setState(() => _currentSliderValue = value),
            onChangeEnd: (value) {
              final newStyle = (element.textStyle ?? const TextStyle()).copyWith(fontSize: value);
              widget.onUpdateTextStyle(element, newStyle);
              _clearSliderState();
            },
          ),
        ),
        Container(width: 50, alignment: Alignment.center, child: Text('${displayValue.round()}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
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
            final newStyle = (element.textStyle ?? const TextStyle()).copyWith(fontSize: size.toDouble());
            widget.onUpdateTextStyle(element, newStyle);
            _clearSliderState();
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
      onPressed: () => widget.onUpdateTextAlign(element, align),
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
            min: 0.5, max: 3.0, divisions: 25,
            label: displayValue.toStringAsFixed(1),
            onChanged: (value) => setState(() => _currentLineHeightValue = value),
            onChangeEnd: (value) {
              widget.onUpdateLineHeight(element, value);
              _clearSliderState();
            },
          ),
        ),
        Container(width: 50, alignment: Alignment.center, child: Text(displayValue.toStringAsFixed(1), style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildTextStyleButtons(PageElement element, Color textColor) {
    return Row(
      children: [
        Expanded(child: _buildStyleButton(icon: Icons.format_bold, isActive: (element.textStyle?.fontWeight ?? FontWeight.normal) == FontWeight.bold, onPressed: () {
          final isBold = element.textStyle?.fontWeight == FontWeight.bold;
          final newStyle = (element.textStyle ?? const TextStyle()).copyWith(fontWeight: isBold ? FontWeight.normal : FontWeight.bold);
          widget.onUpdateTextStyle(element, newStyle);
        })),
        const SizedBox(width: 8),
        Expanded(child: _buildStyleButton(icon: Icons.format_italic, isActive: (element.textStyle?.fontStyle ?? FontStyle.normal) == FontStyle.italic, onPressed: () {
          final isItalic = element.textStyle?.fontStyle == FontStyle.italic;
          final newStyle = (element.textStyle ?? const TextStyle()).copyWith(fontStyle: isItalic ? FontStyle.normal : FontStyle.italic);
          widget.onUpdateTextStyle(element, newStyle);
        })),
        const SizedBox(width: 8),
        Expanded(child: _buildStyleButton(icon: Icons.format_underlined, isActive: element.textStyle?.decoration == TextDecoration.underline, onPressed: () {
          final isUnderlined = element.textStyle?.decoration == TextDecoration.underline;
          final newStyle = (element.textStyle ?? const TextStyle()).copyWith(decoration: isUnderlined ? TextDecoration.none : TextDecoration.underline);
          widget.onUpdateTextStyle(element, newStyle);
        })),
      ],
    );
  }
Widget _buildStyleButton({required IconData icon, required bool isActive, required VoidCallback onPressed}) {
return IconButton(
icon: Icon(icon),
onPressed: onPressed,
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
        final newStyle = (element.textStyle ?? const TextStyle()).copyWith(color: color);
        widget.onUpdateTextStyle(element, newStyle);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade400, width: isSelected ? 3 : 1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: isSelected ? Icon(Icons.check, size: 20, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white) : null,
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
if (value) {
widget.onUpdateShadows(element, [const Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4)]);
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
min: 0, max: 20,
onChanged: (value) {
final currentShadow = element.shadows!.first;
widget.onUpdateShadows(element, [Shadow(color: currentShadow.color, offset: currentShadow.offset, blurRadius: value)]);
},
),
],
],
);
}
}
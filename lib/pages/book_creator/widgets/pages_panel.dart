// lib/pages/book_creator/widgets/pages_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';

class PagesPanel extends ConsumerStatefulWidget {
  final Color panelColor;
  final Color textColor;
  final String bookId;

  const PagesPanel({
    super.key,
    required this.panelColor,
    required this.textColor,
    required this.bookId,
  });

  @override
  ConsumerState<PagesPanel> createState() => _PagesPanelState();
}

class _PagesPanelState extends ConsumerState<PagesPanel> {
  bool _isExpanded = true; // Start expanded

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(bookPagesProvider);
    final pageIndex = ref.watch(currentPageIndexProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 200 : 60,
      decoration: BoxDecoration(
        color: widget.panelColor,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_isExpanded)
            Expanded(
              child: pagesAsync.when(
                data: (pages) => ListView.builder(
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return _buildPageListItem(
                      pages[index],
                      index,
                      widget.textColor,
                      pageIndex,
                      widget.bookId,
                      ref,
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
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
        children: [
          Icon(Icons.auto_stories, color: widget.textColor, size: 20),
          if (_isExpanded) ...[
            const SizedBox(width: 12),
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
          ],
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              color: widget.textColor,
            ),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            tooltip: _isExpanded ? 'Collapse' : 'Expand',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildPageListItem(
    BookPage page,
    int index,
    Color textColor,
    int currentIndex,
    String bookId,
    WidgetRef ref,
  ) {
    final isSelected = index == currentIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 50,
          decoration: BoxDecoration(
            color: Color(int.parse(
              page.background.color.toARGB32().toRadixString(16),
              radix: 16,
            )),
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          'Page ${index + 1}',
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
          onSelected: (value) async {
            final pageActions = ref.read(pageActionsProvider);
            switch (value) {
              case 'duplicate':
                await pageActions.duplicatePage(page.id, bookId);
                break;
              case 'delete':
                final pages = ref.read(bookPagesProvider).value;
                if (pages != null && pages.length > 1) {
                  await pageActions.deletePage(page.id, bookId);
                }
                break;
            }
          },
          itemBuilder: (context) {
            final pages = ref.read(bookPagesProvider).value;
            final canDelete = pages != null && pages.length > 1;

            return [
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              if (canDelete)
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ];
          },
        ),
        onTap: () => ref.read(currentPageIndexProvider.notifier).setPageIndex(index),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        minLeadingWidth: 0,
      ),
    );
  }
}
// lib/pages/book_creator/widgets/pages_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';
import '../../../services/undo_redo_manager.dart';

class PagesPanel extends ConsumerStatefulWidget {
  final Color panelColor;
  final Color textColor;
  final String bookId;
  final VoidCallback? onPanelToggle;
  final UndoRedoManager? pageOrderUndoManager;

  const PagesPanel({
    super.key,
    required this.panelColor,
    required this.textColor,
    required this.bookId,
    this.onPanelToggle,
    this.pageOrderUndoManager,
  });

  @override
  ConsumerState<PagesPanel> createState() => _PagesPanelState();
}

class _PagesPanelState extends ConsumerState<PagesPanel> {
  bool _isExpanded = true;

  // ✅ Multi-select state
  final Set<int> _selectedPageIndices = {};
  bool _isMultiSelectMode = false;

  // ✅ Focus node for keyboard shortcuts
  final FocusNode _focusNode = FocusNode();

  // 🚀 Local page order state (like combine_books_page)
  List<BookPage>? _localPageOrder;

  @override
  void initState() {
    super.initState();
    // Listener will be set up in build() method
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // ✅ HELPER METHODS FOR SAFE LOGGING
  /// Safe substring that handles short IDs
  String _safeSubstring(String id, [int length = 8]) {
    if (id.isEmpty) return 'EMPTY_ID';
    if (id.length <= length) return id;
    return id.substring(0, length);
  }

  String _formatPageIds(List<BookPage> pages) {
    return pages.map((p) => _safeSubstring(p.id)).join(", ");
  }

  String _formatPageNumbers(List<BookPage> pages) {
    return pages.map((p) => p.pageNumber).join(", ");
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(bookPagesProvider(widget.bookId));
    final pageIndex = ref.watch(currentPageIndexProvider);

    // ✅ CRITICAL FIX: Set up listener in build() method
    ref.listen<AsyncValue<List<BookPage>>>(
      bookPagesProvider(widget.bookId),
      (previous, next) {
        debugPrint('');
        debugPrint('🔔 ════════════════════════════════════════════════════════════════');
        debugPrint('🔔 [PagesPanel] PROVIDER LISTENER TRIGGERED');
        debugPrint('🔔 ════════════════════════════════════════════════════════════════');
        debugPrint('🔔 Timestamp: ${DateTime.now().toIso8601String()}');
        debugPrint('🔔 Widget mounted: $mounted');
        debugPrint('🔔 Book ID: ${_safeSubstring(widget.bookId)}...');
        
        // Log previous state
        if (previous == null) {
          debugPrint('📊 PREVIOUS STATE: NULL (first load)');
        } else {
          previous.whenData((prevPages) {
            debugPrint('📊 PREVIOUS STATE:');
            debugPrint('   - Page count: ${prevPages.length}');
            if (prevPages.isNotEmpty) {
              debugPrint('   - Page IDs: ${_formatPageIds(prevPages)}');
              debugPrint('   - Page numbers: ${_formatPageNumbers(prevPages)}');
            }
          });
        }
        
        next.whenData((newPages) {
          if (!mounted) {
            debugPrint('❌ Widget NOT mounted - aborting update');
            debugPrint('🔔 ════════════════════════════════════════════════════════════════\n');
            return;
          }
          
          debugPrint('📊 NEW STATE FROM PROVIDER:');
          debugPrint('   - Page count: ${newPages.length}');
          if (newPages.isNotEmpty) {
            debugPrint('   - Page IDs: ${_formatPageIds(newPages)}');
            debugPrint('   - Page numbers: ${_formatPageNumbers(newPages)}');
          }
          
          // Compare with local state
          if (_localPageOrder != null) {
            debugPrint('📦 LOCAL STATE (before update):');
            debugPrint('   - Page count: ${_localPageOrder!.length}');
            debugPrint('   - Page IDs: ${_formatPageIds(_localPageOrder!)}');
            debugPrint('   - Page numbers: ${_formatPageNumbers(_localPageOrder!)}');
            
            // Check if order actually changed
            bool orderChanged = false;
            if (_localPageOrder!.length == newPages.length) {
              for (int i = 0; i < newPages.length; i++) {
                if (_localPageOrder![i].id != newPages[i].id) {
                  orderChanged = true;
                  debugPrint('   ⚠️  DIFFERENCE at index $i:');
                  debugPrint('      Local: ${_safeSubstring(_localPageOrder![i].id)} (page ${_localPageOrder![i].pageNumber})');
                  debugPrint('      Provider: ${_safeSubstring(newPages[i].id)} (page ${newPages[i].pageNumber})');
                  break;
                }
              }
            } else {
              orderChanged = true;
              debugPrint('   ⚠️  LENGTH MISMATCH: local=${_localPageOrder!.length}, provider=${newPages.length}');
            }
            
            if (orderChanged) {
              debugPrint('   🔄 ORDER HAS CHANGED - will update local state');
            } else {
              debugPrint('   ✅ ORDER UNCHANGED - local state matches provider');
            }
          } else {
            debugPrint('📦 LOCAL STATE: NULL (first load)');
          }
          
          // Update local state after current frame
          debugPrint('⏳ Scheduling local state update via postFrameCallback...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              debugPrint('✅ PostFrameCallback: Updating local state');
              setState(() {
                _localPageOrder = List<BookPage>.from(newPages);
              });
              debugPrint('✅ Local state updated successfully');
            } else {
              debugPrint('❌ PostFrameCallback: Widget not mounted, skipping update');
            }
          });
        });
        
        debugPrint('🔔 ════════════════════════════════════════════════════════════════\n');
      },
    );

    // ✅ Initialize local state from provider (first load only)
    pagesAsync.whenData((providerPages) {
      if (_localPageOrder == null && providerPages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _localPageOrder == null) {
            setState(() {
              _localPageOrder = List<BookPage>.from(providerPages);
            });
          }
        });
      }
    });

    return KeyboardListener(
      focusNode: _focusNode..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // Ctrl+A - Select all pages
          if (HardwareKeyboard.instance.isControlPressed && 
              event.logicalKey == LogicalKeyboardKey.keyA) {
            setState(() {
              pagesAsync.whenData((pages) {
                _selectedPageIndices.clear();
                _selectedPageIndices.addAll(List.generate(pages.length, (i) => i));
                _isMultiSelectMode = true;
              });
            });
          }
          
          // Escape - Clear selection
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            setState(() {
              _selectedPageIndices.clear();
              _isMultiSelectMode = false;
            });
          }
        }
      },
      child: Container(
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
            // ✅ Multi-select info banner
            if (_isMultiSelectMode && _selectedPageIndices.isNotEmpty)
              _buildMultiSelectBanner(),
            Expanded(
              child: _isExpanded
                  ? pagesAsync.when(
                      data: (pages) {
                        // 🚀 Use local state if available, otherwise use provider data
                        final displayPages = _localPageOrder ?? pages;
                        
                        return ReorderableListView.builder(
                          padding: const EdgeInsets.all(0),
                          itemCount: displayPages.length,
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final double elevation = Tween<double>(
                                  begin: 0,
                                  end: 6,
                                ).evaluate(animation);
                                
                                final double scale = Tween<double>(
                                  begin: 1.0,
                                  end: 1.05,
                                ).evaluate(animation);
                                
                                return Transform.scale(
                                  scale: scale,
                                  child: Material(
                                    elevation: elevation,
                                    borderRadius: BorderRadius.circular(8),
                                    shadowColor: Colors.blue.withValues(alpha: 0.5),
                                    child: child,
                                  ),
                                );
                              },
                              child: child,
                            );
                          },
                          itemBuilder: (context, index) {
                            return _buildPageListItem(
                              displayPages[index],
                              index,
                              widget.textColor,
                              pageIndex,
                              widget.bookId,
                              ref,
                              key: Key('page-${displayPages[index].id}'),
                            );
                          },
                          onReorder: (oldIndex, newIndex) {
                            debugPrint('');
                            debugPrint('🖱️  ═══════════════════════════════════════════════════════════════');
                            debugPrint('🖱️  [PagesPanel] USER DRAGGED PAGE');
                            debugPrint('🖱️  ═══════════════════════════════════════════════════════════════');
                            debugPrint('🖱️  Timestamp: ${DateTime.now().toIso8601String()}');
                            debugPrint('🖱️  From index: $oldIndex');
                            debugPrint('🖱️  To index: $newIndex (raw)');
                            
                            if (displayPages.isEmpty) {
                              debugPrint('❌ No display pages available!');
                              debugPrint('🖱️  ═══════════════════════════════════════════════════════════════\n');
                              return;
                            }
                            
                            debugPrint('📄 Current display order (BEFORE local update):');
                            debugPrint('   IDs: ${_formatPageIds(displayPages)}');
                            debugPrint('   Numbers: ${_formatPageNumbers(displayPages)}');
                            
                            // 🚀 STEP 1: Update local state IMMEDIATELY
                            setState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                                debugPrint('🖱️  Adjusted newIndex: $newIndex (drag-down adjustment)');
                              }
                              
                              // Create new list with reordered pages
                              final updatedPages = List<BookPage>.from(displayPages);
                              final pageToMove = updatedPages.removeAt(oldIndex);
                              
                              debugPrint('🖱️  Moving page: ${_safeSubstring(pageToMove.id)} (page ${pageToMove.pageNumber})');
                              
                              updatedPages.insert(newIndex, pageToMove);
                              
                              // Store in local state for instant UI update
                              _localPageOrder = updatedPages;
                              
                              debugPrint('📄 New display order (AFTER local update):');
                              debugPrint('   IDs: ${_formatPageIds(_localPageOrder!)}');
                              debugPrint('   Numbers: ${_formatPageNumbers(_localPageOrder!)}');
                            });
                            
                            debugPrint('✅ Local state updated - UI should reflect new order instantly');
                            debugPrint('💾 Starting background database write...');
                            
                            // 🚀 STEP 2: Write to database in background
                            if (_isMultiSelectMode && _selectedPageIndices.isNotEmpty) {
                              _reorderMultiplePages(ref, widget.bookId, oldIndex, newIndex, displayPages);
                            } else {
                              _reorderPage(ref, widget.bookId, oldIndex, newIndex);
                            }
                            
                            debugPrint('🖱️  ═══════════════════════════════════════════════════════════════\n');
                          },
                          buildDefaultDragHandles: false,
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text('Error: $error')),
                    )
                  : pagesAsync.when(
                      data: (pages) {
                        // 🚀 Use local state for collapsed view too
                        final displayPages = _localPageOrder ?? pages;
                        
                        return ListView.builder(
                          itemCount: displayPages.length,
                          itemBuilder: (context, index) {
                            return _buildCollapsedPageItem(
                              displayPages[index],
                              index,
                              pageIndex,
                            );
                          },
                        );
                      },
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
      ),
    );
  }

  // ✅ Multi-select banner
  Widget _buildMultiSelectBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_selectedPageIndices.length} page${_selectedPageIndices.length > 1 ? 's' : ''} selected',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              setState(() {
                _selectedPageIndices.clear();
                _isMultiSelectMode = false;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'Clear selection (Esc)',
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
                debugPrint('🆕 [PagesPanel] Add Page button clicked');
                final pageActions = ref.read(pageActionsProvider);
                await pageActions.addPage(widget.bookId);
                debugPrint('🆕 [PagesPanel] Add Page completed');
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
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
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
    final isMultiSelected = _selectedPageIndices.contains(index);

    return Material(
      key: key,
      elevation: 0,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isMultiSelected 
              ? Colors.blue.withValues(alpha: 0.2)
              : (isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMultiSelected 
                ? Colors.blue 
                : (isSelected ? Colors.blue : Colors.grey.shade300),
            width: isMultiSelected || isSelected ? 2 : 1,
          ),
        ),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: widget.textColor.withValues(alpha: 0.5),
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
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Page'),
                        content: Text('Are you sure you want to delete Page ${index + 1}?'),
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
                    
                    if (confirm == true) {
                      await pageActions.deletePage(page.id, bookId);
                    }
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
          onTap: () {
            if (HardwareKeyboard.instance.isControlPressed) {
              setState(() {
                if (_selectedPageIndices.contains(index)) {
                  _selectedPageIndices.remove(index);
                  if (_selectedPageIndices.isEmpty) {
                    _isMultiSelectMode = false;
                  }
                } else {
                  _selectedPageIndices.add(index);
                  _isMultiSelectMode = true;
                }
              });
            } else {
              setState(() {
                _selectedPageIndices.clear();
                _isMultiSelectMode = false;
              });
              ref.read(currentPageIndexProvider.notifier).setPageIndex(index);
            }
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minLeadingWidth: 60,
          horizontalTitleGap: 8,
        ),
      ),
    );
  }

  Future<void> _reorderPage(WidgetRef ref, String bookId, int oldIndex, int newIndex) async {
    final startTime = DateTime.now();
    
    debugPrint('');
    debugPrint('📋 ═══════════════════════════════════════════════════════════════');
    debugPrint('📋 [_reorderPage] START');
    debugPrint('📋 ═══════════════════════════════════════════════════════════════');
    debugPrint('📋 Timestamp: ${startTime.toIso8601String()}');
    debugPrint('📋 Book ID: ${_safeSubstring(bookId)}...');
    debugPrint('📋 From index: $oldIndex → To index: $newIndex');
    
    // Get the current display order (local state)
    final displayPages = _localPageOrder;
    if (displayPages == null || displayPages.isEmpty) {
      debugPrint('❌ No local page order available');
      debugPrint('📋 ═══════════════════════════════════════════════════════════════\n');
      return;
    }
    
    debugPrint('📋 Total pages: ${displayPages.length}');
    debugPrint('📋 Moving page: ${displayPages[oldIndex].pageNumber} (ID: ${_safeSubstring(displayPages[oldIndex].id)})');
    debugPrint('📋 Current order:');
    debugPrint('   IDs: ${_formatPageIds(displayPages)}');
    debugPrint('   Numbers: ${_formatPageNumbers(displayPages)}');
    
    // ✅ Write to database in background
    debugPrint('💾 Calling pageActions.reorderPages...');
    final pageActions = ref.read(pageActionsProvider);
    
    final dbWriteStart = DateTime.now();
    final success = await pageActions.reorderPages(
      bookId, 
      displayPages,
      shouldInvalidate: false, // Don't invalidate yet
    );
    final dbWriteEnd = DateTime.now();
    final dbDuration = dbWriteEnd.difference(dbWriteStart).inMilliseconds;
    
    if (success) {
      debugPrint('⏳ Waiting 200ms for database to settle...');
      await Future.delayed(const Duration(milliseconds: 200));

      
      // ✅ Wait for database to settle, THEN clear local state and invalidate
      debugPrint('🔄 Invalidating bookPagesProvider...');
      ref.invalidate(bookPagesProvider(bookId));
      
      debugPrint('🔄 Invalidating bookPagesProvider...');
      final invalidateStart = DateTime.now();
      ref.invalidate(bookPagesProvider(bookId));
      final invalidateEnd = DateTime.now();
      final invalidateDuration = invalidateEnd.difference(invalidateStart).inMilliseconds;
      debugPrint('✅ Provider invalidated (${invalidateDuration}ms)');
      
      // Update current page index if needed
      final currentIndex = ref.read(currentPageIndexProvider);
      debugPrint('📍 Current page index: $currentIndex');
      
      if (currentIndex == oldIndex) {
        debugPrint('   → Moving current index from $currentIndex to $newIndex');
        ref.read(currentPageIndexProvider.notifier).setPageIndex(newIndex);
      } else if (currentIndex > oldIndex && currentIndex <= newIndex) {
        final newCurrentIndex = currentIndex - 1;
        debugPrint('   → Adjusting current index from $currentIndex to $newCurrentIndex');
        ref.read(currentPageIndexProvider.notifier).setPageIndex(newCurrentIndex);
      } else if (currentIndex < oldIndex && currentIndex >= newIndex) {
        final newCurrentIndex = currentIndex + 1;
        debugPrint('   → Adjusting current index from $currentIndex to $newCurrentIndex');
        ref.read(currentPageIndexProvider.notifier).setPageIndex(newCurrentIndex);
      } else {
        debugPrint('   → Current index unchanged');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Page ${oldIndex + 1} moved to position ${newIndex + 1}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      debugPrint('❌ Database write FAILED (${dbDuration}ms)');
debugPrint('🔄 Invalidating provider to restore previous state...');
  ref.invalidate(bookPagesProvider(bookId));
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Failed to reorder pages'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

final endTime = DateTime.now();
final totalDuration = endTime.difference(startTime).inMilliseconds;

debugPrint('📋 ═══════════════════════════════════════════════════════════════');
debugPrint('📋 [_reorderPage] END (Total: ${totalDuration}ms)');
debugPrint('📋 ═══════════════════════════════════════════════════════════════\n');
}
Future<void> _reorderMultiplePages(
WidgetRef ref,
String bookId,
int draggedIndex,
int targetIndex,
List<BookPage> allPages,
) async {
debugPrint('📋 === MULTI-PAGE REORDER START ===');
debugPrint('   Selected pages: $_selectedPageIndices');
debugPrint('   Dragged index: $draggedIndex → Target: $targetIndex');
if (!_selectedPageIndices.contains(draggedIndex)) {
  _selectedPageIndices.add(draggedIndex);
}

final sortedSelectedIndices = _selectedPageIndices.toList()..sort();
debugPrint('   Sorted selection: $sortedSelectedIndices');

final selectedPages = <BookPage>[];
final remainingPages = <BookPage>[];

for (int i = 0; i < allPages.length; i++) {
  if (sortedSelectedIndices.contains(i)) {
    selectedPages.add(allPages[i]);
  } else {
    remainingPages.add(allPages[i]);
  }
}

debugPrint('   Selected pages count: ${selectedPages.length}');
debugPrint('   Remaining pages count: ${remainingPages.length}');

int insertionPoint = targetIndex;

for (int selectedIdx in sortedSelectedIndices) {
  if (selectedIdx < targetIndex) {
    insertionPoint--;
  }
}

insertionPoint = insertionPoint.clamp(0, remainingPages.length);
debugPrint('   Insertion point in remaining pages: $insertionPoint');

final List<BookPage> reorderedPages = [];
reorderedPages.addAll(remainingPages.sublist(0, insertionPoint));
reorderedPages.addAll(selectedPages);

if (insertionPoint < remainingPages.length) {
  reorderedPages.addAll(remainingPages.sublist(insertionPoint));
}

debugPrint('   Final page count: ${reorderedPages.length}');

final pageActions = ref.read(pageActionsProvider);
final success = await pageActions.reorderPages(
  bookId, 
  reorderedPages,
  shouldInvalidate: false, // ✅ Don't invalidate during reorder
);

if (success) {
  debugPrint('✅ Multi-page reorder successful');
  
  // ✅ Wait then invalidate
  await Future.delayed(const Duration(milliseconds: 100));
  ref.invalidate(bookPagesProvider(bookId));
  
  final newSelectedIndices = <int>{};
  for (int i = 0; i < selectedPages.length; i++) {
    newSelectedIndices.add(insertionPoint + i);
  }
  
  setState(() {
    _selectedPageIndices.clear();
    _selectedPageIndices.addAll(newSelectedIndices);
  });
  
  debugPrint('   Updated selection: $_selectedPageIndices');
  
  ref.read(currentPageIndexProvider.notifier).setPageIndex(insertionPoint);
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Moved ${selectedPages.length} page${selectedPages.length > 1 ? 's' : ''} successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
} else {
  debugPrint('❌ Multi-page reorder failed');
  
  ref.invalidate(bookPagesProvider(bookId));
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Failed to move pages'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

debugPrint('📋 === MULTI-PAGE REORDER END ===\n');
}
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
        color: Colors.black.withValues(alpha: 0.1),
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
              color: Colors.black.withValues(alpha: 0.6),
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
color: Colors.white.withValues(alpha: 0.8),
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
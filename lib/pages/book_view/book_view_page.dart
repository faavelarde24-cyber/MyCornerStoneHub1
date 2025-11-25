// lib/pages/book_view/book_view_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/book_models.dart';
import '../../providers/book_providers.dart';
import 'widgets/book_view_controls.dart';
import 'widgets/page_spread_widget.dart';

class BookViewPage extends ConsumerStatefulWidget {
  final String bookId;

  const BookViewPage({super.key, required this.bookId});

  @override
  ConsumerState<BookViewPage> createState() => _BookViewPageState();
}

class _BookViewPageState extends ConsumerState<BookViewPage>
    with SingleTickerProviderStateMixin {
  int _currentPageIndex = 0; // Represents "spread index" in two-page mode
  int _targetPageIndex = 0; // The spread we're animating TO (for pre-showing destination)

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late Animation<double> _curlAnimation;
  late Animation<double> _shadowAnimation;
  late ScrollController _horizontalController;
  late ScrollController _verticalController;

  
  double _dragProgress = 0.0;
  bool _isDragging = false;
  FlipDirection? _flipDirection;
  bool _isDarkMode = false;
  bool _isSinglePageMode = false;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 === BookViewPage initState START ===');
    
    _targetPageIndex = _currentPageIndex; // Initialize target to match current

      _horizontalController = ScrollController();
      _verticalController = ScrollController();
    
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Slightly slower for realism
    );

    // Create curved animations for natural motion
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic, // Smooth acceleration and deceleration
    );

    // Page curl effect (more pronounced at the middle of the flip)
    _curlAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Shadow intensity (peaks in the middle of the flip)
    _shadowAnimation = Tween<double>(begin: 0.2, end: 0.7).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOut,
      ),
    );

    debugPrint('🎬 Flip animations initialized');

    // Set current book and load pages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('📚 Setting current book ID: ${widget.bookId}');
      ref.read(currentBookIdProvider.notifier).setBookId(widget.bookId);
      ref.read(currentPageIndexProvider.notifier).setPageIndex(0);
      
      _calculateInitialZoom();
    });
    
    debugPrint('🟢 === BookViewPage initState END ===');
  }

  @override
  void dispose() {
    debugPrint('🔴 BookViewPage disposing');
    _flipController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  // === HELPER METHODS ===

  int _getTotalPages() {
    final pagesAsync = ref.read(bookPagesProvider(widget.bookId));
    final totalPages = pagesAsync.when(
      data: (pages) => pages.length,
      loading: () => 0,
      error: (_, _) => 0,
    );
    debugPrint('📚 Total pages: $totalPages');
    return totalPages;
  }

  int _getTotalSpreads() {
    final totalPages = _getTotalPages();
    if (totalPages == 0) return 0;
    
    // Spread 0 = cover only
    // Spreads 1+ = pairs of pages (1-2, 3-4, 5-6, etc.)
    // Last spread = "End of Book" page
    final spreadsAfterCover = ((totalPages - 1) / 2).ceil();
    final totalSpreads = 1 + spreadsAfterCover + 1; // ✅ +1 for end page
    
    debugPrint('📊 Total Pages: $totalPages → Total Spreads (with end page): $totalSpreads');
    return totalSpreads;
  }

  (int? leftPageIndex, int? rightPageIndex) _getPagesForSpread(int spreadIndex) {
    final totalPages = _getTotalPages();
    final totalSpreadCount = _getTotalSpreads();
    
    if (spreadIndex == 0) {
      // Cover spread: blank + page 0
      debugPrint('📖 Spread 0 (Cover): null + 0');
      return (null, 0);
    }
    
    // ✅ Check if this is the "End of Book" spread (last spread)
    if (spreadIndex == totalSpreadCount - 1) {
      debugPrint('📖 Spread $spreadIndex: END OF BOOK PAGE');
      return (-1, -1); // Special marker for end page
    }
    
    // For spread N (where N > 0):
    // Left page = (2 * N - 1), Right page = (2 * N)
    final leftPage = (2 * spreadIndex - 1);
    final rightPage = (2 * spreadIndex);
    
    // Clamp to available pages
    final left = leftPage < totalPages ? leftPage : null;
    final right = rightPage < totalPages ? rightPage : null;
    
    debugPrint('📖 Spread $spreadIndex: ${left ?? "null"} + ${right ?? "null"}');
    return (left, right);
  }

  int _getCurrentPageDisplay() {
    if (_isSinglePageMode) {
      return _currentPageIndex + 1;
    }
    
    // Two-page spread mode
    if (_currentPageIndex == 0) {
      return 1; // Cover page
    }
    
    // For spread N (where N > 0), show the left page number
    // Spread 1 = pages 1-2, so show "2"
    // Spread 2 = pages 3-4, so show "3"
    final leftPageNumber = (2 * _currentPageIndex - 1) + 1; // Convert to 1-based
    
    debugPrint('📊 Spread $_currentPageIndex → Displaying page $leftPageNumber');
    return leftPageNumber;
  }

  void _calculateInitialZoom() {
    debugPrint('🔍 === _calculateInitialZoom START ===');
    
    final bookAsync = ref.read(bookProvider(widget.bookId));
    bookAsync.whenData((book) {
      if (book == null) {
        debugPrint('❌ Book is null, cannot calculate zoom');
        return;
      }
      
      final screenSize = MediaQuery.of(context).size;
      final pageWidth = book.pageSize.width;
      final pageHeight = book.pageSize.height;
      
      debugPrint('📐 Screen Size: ${screenSize.width} x ${screenSize.height}');
      debugPrint('📄 Page Size: $pageWidth x $pageHeight');
      
      // Calculate max canvas width (accounting for two-page spread + gutter)
      final maxCanvasWidth = (pageWidth * 2) + 24;
      final maxCanvasHeight = pageHeight;
      
      debugPrint('📊 Max Canvas Size: $maxCanvasWidth x $maxCanvasHeight');
      
      // Calculate zoom that fits within 80% of screen
      final horizontalZoom = (screenSize.width * 0.8) / maxCanvasWidth;
      final verticalZoom = (screenSize.height * 0.8) / maxCanvasHeight;
      
      debugPrint('🔢 Horizontal Zoom: $horizontalZoom');
      debugPrint('🔢 Vertical Zoom: $verticalZoom');
      
      // Use the smaller zoom to ensure everything fits
      final calculatedZoom = (horizontalZoom < verticalZoom ? horizontalZoom : verticalZoom).clamp(0.3, 1.0);
      
      debugPrint('🎯 Calculated Zoom: $calculatedZoom');
      
      // Default to 70% zoom, or calculated zoom if smaller
      final initialZoom = calculatedZoom < 0.7 ? calculatedZoom : 0.7;
      
      setState(() {
        _zoomLevel = initialZoom;
      });
      
      debugPrint('✅ Initial Zoom Level Set: ${(_zoomLevel * 51).round()}%');
      WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalController.hasClients && _verticalController.hasClients) {
        // Calculate center position
        final maxHorizontal = _horizontalController.position.maxScrollExtent;
        final maxVertical = _verticalController.position.maxScrollExtent;
        
        // Jump to center (adjust these values to change starting position)
        _horizontalController.jumpTo(maxHorizontal * 0.5);
        _verticalController.jumpTo(maxVertical * 0.4);
        
        debugPrint('📍 Scroll position set - H: ${maxHorizontal / 8}, V: ${maxVertical / 8}');
      }
    });
    
    debugPrint('🔍 === _calculateInitialZoom END ===');
  });
}



  // === NAVIGATION METHODS ===

  void _goToPage(int pageNumber) {
    debugPrint('📖 _goToPage called with page number: $pageNumber');
    
    // Convert page number (1-based) to spread index
    int spreadIndex;
    if (pageNumber == 1) {
      spreadIndex = 0; // Cover
    } else {
      // Pages 2-3 = spread 1, pages 4-5 = spread 2, etc.
      spreadIndex = ((pageNumber - 1) / 2).ceil();
    }
    
    final maxSpread = _getTotalSpreads() - 1;
    spreadIndex = spreadIndex.clamp(0, maxSpread);
    
    debugPrint('📖 Page $pageNumber → Spread $spreadIndex');
    
    setState(() {
      _currentPageIndex = spreadIndex;
      ref.read(currentPageIndexProvider.notifier).setPageIndex(_currentPageIndex);
    });
    
    debugPrint('✅ Current spread index set to: $_currentPageIndex');
  }

  void _flipForward() {
    debugPrint('➡️ === _flipForward START ===');
    debugPrint('Current Spread Index: $_currentPageIndex');
    debugPrint('Single Page Mode: $_isSinglePageMode');
    
    final totalSpreads = _getTotalSpreads();
    
    if (_isSinglePageMode) {
      final totalPages = _getTotalPages();
      if (_currentPageIndex >= totalPages - 1) {
        debugPrint('⚠️ Already at last page');
        return;
      }
      
      // Calculate NEXT page
      final nextIndex = (_currentPageIndex + 1).clamp(0, totalPages - 1);
      
      setState(() {
        _flipDirection = FlipDirection.forward;
        _targetPageIndex = nextIndex; // Set target IMMEDIATELY
      });
      HapticFeedback.lightImpact();
      debugPrint('🎯 Target set to: $_targetPageIndex');
      
      _flipController.forward(from: 0.0).then((_) {
        _playPageFlipSound();
        setState(() {
          _currentPageIndex = _targetPageIndex; // Commit target to current
          _flipDirection = null;
          _dragProgress = 0.0;
        });
        _flipController.reset();
        debugPrint('✅ Moved to page $_currentPageIndex');
      });
    } else {
      // Two-page spread mode
      if (_currentPageIndex >= totalSpreads - 1) {
        debugPrint('⚠️ Already at last spread');
        return;
      }
      
      // Calculate NEXT spread
      final nextIndex = (_currentPageIndex + 1).clamp(0, totalSpreads - 1);
      
      setState(() {
        _flipDirection = FlipDirection.forward;
        _targetPageIndex = nextIndex; // Set target IMMEDIATELY
      });
      HapticFeedback.lightImpact();
      debugPrint('🎯 Target set to: $_targetPageIndex');
      
      _flipController.forward(from: 0.0).then((_) {
        _playPageFlipSound();
        setState(() {
          _currentPageIndex = _targetPageIndex; // Commit target to current
          _flipDirection = null;
          _dragProgress = 0.0;
        });
        _flipController.reset();
        debugPrint('✅ Moved to spread $_currentPageIndex');
      });
    }
    
    debugPrint('➡️ === _flipForward END ===');
  }

  void _flipBackward() {
    debugPrint('⬅️ === _flipBackward START ===');
    debugPrint('Current Spread Index: $_currentPageIndex');
    
    if (_currentPageIndex <= 0) {
      debugPrint('⚠️ Already at first spread/page');
      return;
    }
    
    // Calculate PREVIOUS index
    final prevIndex = _isSinglePageMode
        ? (_currentPageIndex - 1).clamp(0, _getTotalPages() - 1)
        : (_currentPageIndex - 1).clamp(0, _getTotalSpreads() - 1);
    
    setState(() {
      _flipDirection = FlipDirection.backward;
      _targetPageIndex = prevIndex; // Set target IMMEDIATELY
    });
    HapticFeedback.lightImpact();
    debugPrint('🎯 Target set to: $_targetPageIndex');
    
    _flipController.forward(from: 0.0).then((_) {
      _playPageFlipSound();
      setState(() {
        _currentPageIndex = _targetPageIndex; // Commit target to current
        _flipDirection = null;
        _dragProgress = 0.0;
      });
      _flipController.reset();
      debugPrint('✅ Moved to ${_isSinglePageMode ? "page" : "spread"} $_currentPageIndex');
    });
    
    debugPrint('⬅️ === _flipBackward END ===');
  }

  void _playPageFlipSound() {
    // Add a subtle haptic feedback for page flip completion
    HapticFeedback.mediumImpact();
  }

  void _snapBack() {
    // Animate back to resting position with spring effect
    setState(() {
      _flipDirection = _dragProgress < 0 ? FlipDirection.forward : FlipDirection.backward;
      _targetPageIndex = _currentPageIndex; // Reset target to current
    });
    
    _flipController.reverse(from: _dragProgress.abs()).then((_) {
      setState(() {
        _dragProgress = 0.0;
        _flipDirection = null;
      });
      _flipController.reset();
    });
    
    HapticFeedback.lightImpact();
  }

  // === DRAG HANDLERS ===

  void _onHorizontalDragStart(DragStartDetails details) {
    debugPrint('👆 Drag START at ${details.globalPosition}');
    setState(() {
      _isDragging = true;
      _dragProgress = 0.0;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      // More responsive drag calculation
      final screenWidth = MediaQuery.of(context).size.width;
      const dragSensitivity = 0.5; // Lower = more sensitive
      
      _dragProgress += details.delta.dx / (screenWidth * dragSensitivity);
      _dragProgress = _dragProgress.clamp(-1.0, 1.0);

      if (_dragProgress < -0.05 && _flipDirection != FlipDirection.forward) {
        _flipDirection = FlipDirection.forward;
        debugPrint('🔄 Flip direction: FORWARD (drag: ${_dragProgress.toStringAsFixed(2)})');
      } else if (_dragProgress > 0.05 && _flipDirection != FlipDirection.backward) {
        _flipDirection = FlipDirection.backward;
        debugPrint('🔄 Flip direction: BACKWARD (drag: ${_dragProgress.toStringAsFixed(2)})');
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    debugPrint('👆 Drag END - Progress: $_dragProgress');
    setState(() {
      _isDragging = false;
    });

    if (_dragProgress.abs() > 0.3) {
      // Threshold met - complete the flip
      final maxLimit = _isSinglePageMode ? _getTotalPages() - 1 : _getTotalSpreads() - 1;
      
      if (_dragProgress < 0 && _currentPageIndex < maxLimit) {
        debugPrint('✅ Flip forward triggered (drag: ${_dragProgress.toStringAsFixed(2)})');
        
        // Set target first
        final nextIndex = _isSinglePageMode
            ? (_currentPageIndex + 1).clamp(0, _getTotalPages() - 1)
            : (_currentPageIndex + 1).clamp(0, _getTotalSpreads() - 1);
        
        setState(() {
          _targetPageIndex = nextIndex;
        });
        
        // Animate from current drag progress to completion
        _flipController.forward(from: _dragProgress.abs()).then((_) {
          setState(() {
            _currentPageIndex = _targetPageIndex;
            _flipDirection = null;
            _dragProgress = 0.0;
          });
          _flipController.reset();
          HapticFeedback.mediumImpact();
          debugPrint('✅ Flip complete - now at: $_currentPageIndex');
        });
      } else if (_dragProgress > 0 && _currentPageIndex > 0) {
        debugPrint('✅ Flip backward triggered (drag: ${_dragProgress.toStringAsFixed(2)})');
        
        // Set target first
        final prevIndex = _isSinglePageMode
            ? (_currentPageIndex - 1).clamp(0, _getTotalPages() - 1)
            : (_currentPageIndex - 1).clamp(0, _getTotalSpreads() - 1);
        
        setState(() {
          _targetPageIndex = prevIndex;
        });
        
        _flipController.forward(from: _dragProgress.abs()).then((_) {
          setState(() {
            _currentPageIndex = _targetPageIndex;
            _flipDirection = null;
            _dragProgress = 0.0;
          });
          _flipController.reset();
          HapticFeedback.mediumImpact();
          debugPrint('✅ Flip complete - now at: $_currentPageIndex');
        });
      } else {
        debugPrint('⚠️ Cannot flip (boundary reached)');
        _snapBack();
      }
    } else {
      // Threshold not met - snap back with spring animation
      debugPrint('⚠️ Drag threshold not met (${_dragProgress.toStringAsFixed(2)}), snapping back');
      _snapBack();
    }
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    debugPrint('⌨️ Key pressed: ${key.keyLabel}');

    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.space) {
      _flipForward();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _flipBackward();
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
    } else if (key == LogicalKeyboardKey.keyS) {
      setState(() => _isSinglePageMode = !_isSinglePageMode);
      debugPrint('🔄 View mode toggled: ${_isSinglePageMode ? "Single" : "Two-page"}');
    }
  }

  // === BUILD METHODS ===

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ === BookViewPage build START ===');
    
    final bookAsync = ref.watch(bookProvider(widget.bookId));
    final pagesAsync = ref.watch(bookPagesProvider(widget.bookId));

    final backgroundColor = _isDarkMode ? const Color(0xFF2C3440) : const Color(0xFFE5E5E5);

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: bookAsync.when(
          data: (book) {
            if (book == null) {
              debugPrint('❌ Book is null');
              return const Center(child: Text('Book not found'));
            }

            debugPrint('📚 Book loaded: ${book.title}');

            return pagesAsync.when(
              data: (pages) {
                if (pages.isEmpty) {
                  debugPrint('❌ No pages available');
                  return const Center(child: Text('No pages available'));
                }

                debugPrint('📄 Pages loaded: ${pages.length}');

                return Stack(
                  children: [
                    // Main book canvas
                    Center(
                      child: _buildBookCanvas(book, pages),
                    ),

                    // Top controls
                    BookViewControls(
                      currentPage: _getCurrentPageDisplay(),
                      totalPages: pages.length,
                      isDarkMode: _isDarkMode,
                      isSinglePageMode: _isSinglePageMode,
                      zoomLevel: _zoomLevel,
                      onClose: () => Navigator.pop(context),
                      onToggleTheme: () => setState(() => _isDarkMode = !_isDarkMode),
                      onToggleViewMode: () => setState(() => _isSinglePageMode = !_isSinglePageMode),
                      onZoomIn: () => setState(() => _zoomLevel = (_zoomLevel + 0.1).clamp(0.3, 2.0)),
                      onZoomOut: () => setState(() => _zoomLevel = (_zoomLevel - 0.1).clamp(0.3, 2.0)),
                      onZoomReset: () => setState(() => _zoomLevel = 1.0),
                      onJumpToPage: (page) => _goToPage(page),
                    ),

                    // Navigation arrows
                    if (_currentPageIndex > 0)
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _buildArrowButton(
                            icon: Icons.chevron_left,
                            onPressed: _flipBackward,
                          ),
                        ),
                      ),

                    // Check against correct max limit
                    if (_isSinglePageMode 
                        ? _currentPageIndex < pages.length - 1
                        : _currentPageIndex < _getTotalSpreads() - 1)
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _buildArrowButton(
                            icon: Icons.chevron_right,
                            onPressed: _flipForward,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                debugPrint('❌ Error loading pages: $error');
                return Center(child: Text('Error: $error'));
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            debugPrint('❌ Error loading book: $error');
            return Center(child: Text('Error: $error'));
          },
        ),
      ),
    );
  }

  Widget _buildBookCanvas(Book book, List<BookPage> pages) {
    debugPrint('🎨 === _buildBookCanvas START ===');
    debugPrint('Current Index: $_currentPageIndex (${_isSinglePageMode ? "Page" : "Spread"})');
    debugPrint('Single Page Mode: $_isSinglePageMode');
    debugPrint('Zoom Level: $_zoomLevel');
    
    final pageWidth = book.pageSize.width;
    final pageHeight = book.pageSize.height;
    
    debugPrint('📏 Page Dimensions: $pageWidth x $pageHeight');

    int? leftPageIndex;
    int? rightPageIndex;

    // CRITICAL: During animation, show TARGET spread (destination)
    // This way the page flips away to reveal what's underneath
    final displayIndex = (_flipController.isAnimating || _isDragging)
        ? _targetPageIndex
        : _currentPageIndex;

    debugPrint('🎯 Display Index: $displayIndex (Animating: ${_flipController.isAnimating}, Target: $_targetPageIndex, Current: $_currentPageIndex)');

    if (_isSinglePageMode) {
      // Single page mode: just show display page
      leftPageIndex = null;
      rightPageIndex = displayIndex < pages.length ? displayIndex : null;
      debugPrint('📖 Single Page Mode - Page $displayIndex');
    } else {
      // Two-page spread mode: use helper method with display index
      final (left, right) = _getPagesForSpread(displayIndex);
      leftPageIndex = left;
      rightPageIndex = right;
      
      // ✅ Check for end of book page
      if (left == -1 && right == -1) {
        debugPrint('📖 Showing END OF BOOK page');
        leftPageIndex = -1; // Special marker
        rightPageIndex = -1; // Special marker
      }
    }

    // ✅ Handle end of book page
    final leftPage = (leftPageIndex != null && leftPageIndex >= 0 && leftPageIndex < pages.length)
        ? pages[leftPageIndex] 
        : null;
    final rightPage = (rightPageIndex != null && rightPageIndex >= 0 && rightPageIndex < pages.length)
        ? pages[rightPageIndex] 
        : null;

    // ✅ Check if we're showing the end page
    final isEndOfBookPage = leftPageIndex == -1 && rightPageIndex == -1;

    debugPrint('📄 Left Page: ${leftPage != null ? "Page $leftPageIndex" : "null"}');
    debugPrint('📄 Right Page: ${rightPage != null ? "Page $rightPageIndex" : "null"}');

    final isFirstSpread = _currentPageIndex == 0 && !_isSinglePageMode;
    final bool showingTwoPages = leftPage != null && rightPage != null;
    
    // Calculate content width based on what we're actually showing
    final contentWidth = _isSinglePageMode 
        ? pageWidth 
        : (isFirstSpread
            ? pageWidth + 12  // Cover: just right page + half gutter
            : (showingTwoPages 
                ? (pageWidth * 2) + 24  // Normal spread: both pages + gutter
                : pageWidth + 12));  // Last page if odd: just one page + half gutter

    debugPrint('📏 Content Width: $contentWidth (First Spread: $isFirstSpread, Two Pages: $showingTwoPages)');
    final contentHeight = pageHeight;

    final maxContainerWidth = (pageWidth * 2) + 24;
    final maxContainerHeight = pageHeight;

    debugPrint('📐 Content Size: $contentWidth x $contentHeight');
    debugPrint('📐 Container Size (Fixed): $maxContainerWidth x $maxContainerHeight');
    
    debugPrint('🎨 === _buildBookCanvas END ===');

return Container(
  color: _isDarkMode ? const Color(0xFF2C3440) : const Color(0xFFE5E5E5),
  child: Center(
    child: SingleChildScrollView(
      controller: _horizontalController,  
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        controller: _verticalController,  
        scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: GestureDetector(
                onHorizontalDragStart: _onHorizontalDragStart,
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                child: Transform.scale(
                  scale: _zoomLevel,
                  alignment: Alignment.center,
                  child: Container(
                    width: maxContainerWidth,
                    height: maxContainerHeight,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        height: contentHeight,
                        child: Stack(
                          children: [
                            PageSpreadWidget(
                              leftPage: leftPage,
                              rightPage: rightPage,
                              pageWidth: pageWidth,
                              pageHeight: pageHeight,
                              isSinglePageMode: _isSinglePageMode,
                              isFirstPage: isFirstSpread,
                              isEndPage: isEndOfBookPage,
                              onRestartBook: () => _goToPage(1),
                            ),

                            if (_flipDirection != null && (_flipController.isAnimating || _isDragging))
                              _buildTurningPageOverlay(
                                pages: pages,
                                pageWidth: pageWidth,
                                pageHeight: pageHeight,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTurningPageOverlay({
    required List<BookPage> pages,
    required double pageWidth,
    required double pageHeight,
  }) {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, child) {
        // Use curved animation progress instead of linear
        double progress = _isDragging 
            ? _dragProgress.abs() 
            : _flipAnimation.value;
        
        if (progress == 0.0) return const SizedBox.shrink();

        final isForward = _flipDirection == FlipDirection.forward;
        
        // Calculate which page is turning
        int turningPageIndex;
        if (isForward) {
          // When going forward, we're flipping the current right page
          if (_isSinglePageMode) {
            turningPageIndex = _currentPageIndex;
          } else {
            // In spread mode, flip the right page of current spread
            final (_, rightIdx) = _getPagesForSpread(_currentPageIndex);
            turningPageIndex = rightIdx ?? _currentPageIndex;
          }
        } else {
          // When going backward, we're flipping the page before current
          turningPageIndex = _currentPageIndex - 1;
        }
        
        if (turningPageIndex < 0 || turningPageIndex >= pages.length) {
          return const SizedBox.shrink();
        }
        
        final turningPage = pages[turningPageIndex];
        
        debugPrint('📄 Turning page: $turningPageIndex (${isForward ? "forward" : "backward"}) - Progress: ${progress.toStringAsFixed(2)}');

        // Calculate rotation with natural curve
        final rotationAngle = progress * math.pi;
        final rotationY = isForward ? -rotationAngle : rotationAngle;
        
        // Page curl effect - bends more in the middle of flip
        final curlProgress = _isDragging ? progress : _curlAnimation.value;
        final curlIntensity = math.sin(curlProgress * math.pi) * 0.15;
        
        // Shadow intensity - darker in the middle
        final shadowProgress = _isDragging 
            ? (0.2 + 0.5 * math.sin(progress * math.pi))
            : _shadowAnimation.value;
        
        // Calculate perspective and depth
        final perspective = 0.001 + (curlProgress * 0.001);
        
        return Positioned.fill(
          child: Align(
            alignment: isForward ? Alignment.centerRight : Alignment.centerLeft,
            child: SizedBox(
              width: pageWidth,
              height: pageHeight,
              child: Stack(
                children: [
                  // Shadow on the static page beneath
                  if (progress > 0.1)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: isForward ? Alignment.centerRight : Alignment.centerLeft,
                            end: isForward ? Alignment.centerLeft : Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: shadowProgress * 0.5),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4],
                          ),
                        ),
                      ),
                    ),
                  
                  // The turning page with realistic transform
                  Transform(
                    alignment: isForward ? Alignment.centerLeft : Alignment.centerRight,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, perspective) // Perspective
                      ..rotateY(rotationY)
                      ..translate(0.0, 0.0, curlIntensity * 50),
                    child: Container(
                      width: pageWidth,
                      height: pageHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          // Main shadow
                          BoxShadow(
                            color: Colors.black.withValues(alpha: shadowProgress),
                            blurRadius: 20 + (curlProgress * 30),
                            spreadRadius: 5,
                            offset: Offset(
                              isForward ? -10 * progress : 10 * progress,
                              10 * progress,
                            ),
                          ),
                          // Inner shadow for depth
                          BoxShadow(
                            color: Colors.black.withValues(alpha: shadowProgress * 0.3),
                            blurRadius: 10,
                            spreadRadius: -5,
                            offset: Offset(
                              isForward ? 5 * progress : -5 * progress,
                              0,
                            ),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            // The actual page content
                            PageSpreadWidget(
                              leftPage: null,
                              rightPage: turningPage,
                              pageWidth: pageWidth,
                              pageHeight: pageHeight,
                              isSinglePageMode: true,
                              isFirstPage: false,
                              isBackside: false,
                              onRestartBook: () => _goToPage(1),
                            ),
                            
                            // Gradient overlay for lighting effect
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: isForward ? Alignment.centerRight : Alignment.centerLeft,
                                    end: isForward ? Alignment.centerLeft : Alignment.centerRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: curlProgress * 0.3),
                                      Colors.black.withValues(alpha: curlProgress * 0.15),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Page curl highlight edge
                            if (progress > 0.3 && progress < 0.9)
                              Positioned(
                                right: isForward ? 0 : null,
                                left: isForward ? null : 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        Colors.white.withValues(alpha: 0.6 * curlProgress),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArrowButton({required IconData icon, required VoidCallback onPressed}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 32, color: Colors.white.withValues(alpha: 0.9)),
        ),
      ),
    );
  }
}

enum FlipDirection { forward, backward }
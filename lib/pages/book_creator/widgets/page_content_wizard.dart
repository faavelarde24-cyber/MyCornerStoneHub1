import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';

/// Simplified Book Creator Wizard - Two-Step Process
class PageContentWizard extends ConsumerStatefulWidget {
  final String bookId;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onAddText;
  final VoidCallback onAddImage;
  final VoidCallback onAddShape;
  final VoidCallback onAddAudio;
  final VoidCallback onAddVideo;
  final VoidCallback onChangeBackground;
  

  const PageContentWizard({
    super.key,
    required this.bookId,
    required this.onComplete,
    required this.onSkip,
    required this.onAddText,
    required this.onAddImage,
    required this.onAddShape,
    required this.onAddAudio,
    required this.onAddVideo,
    required this.onChangeBackground,
  });
  @override
  ConsumerState<PageContentWizard> createState() => _PageContentWizardState();
}

class _PageContentWizardState extends ConsumerState<PageContentWizard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Wizard state
  int _currentStep = 0; // 0 = question, 1 = editing interface
  String _bookTopic = '';
  final TextEditingController _topicController = TextEditingController();
  
  // Track pending actions to apply when user finishes
  final List<VoidCallback> _pendingActions = [];

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  // Only load once
  if (_topicController.text.isEmpty) {
    final bookAsync = ref.watch(bookProvider(widget.bookId));
    
    bookAsync.whenData((book) {
      if (book != null && mounted) {
        setState(() {
          _topicController.text = book.title;
          _bookTopic = book.title; // ✅ Also set initial topic
        });
      }
    });
  }
}

  @override
  void dispose() {
    _controller.dispose();
    _topicController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

void _goToEditingMode() {
  if (_topicController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please tell us what your book is about!'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final newTitle = _topicController.text.trim();
  
  // ✅ Update book title in database
  _updateBookTitle(newTitle);

  setState(() {
    _bookTopic = newTitle;
    _currentStep = 1;
  });

  // Animate transition
  _controller.forward(from: 0);
}

// ✅ ADD THIS METHOD - Updates book title in real-time
void _updateBookTitle(String newTitle) async {
  if (newTitle.trim().isEmpty) return;
  
  final bookActions = ref.read(bookActionsProvider);
  
  // Update book title in database
  final success = await bookActions.updateBook(
    bookId: widget.bookId,
    title: newTitle.trim(),
  );
  
  if (success) {
    debugPrint('✅ Book title updated to: $newTitle');
    
    // ✅ Invalidate provider to refresh UI everywhere
    ref.invalidate(bookProvider(widget.bookId));
    ref.invalidate(userBooksProvider);
  } else {
    debugPrint('❌ Failed to update book title');
  }
}


// Add this method after _applyPendingChangesAndComplete()

void _goBackToQuestion() {
  setState(() {
    _currentStep = 0; // Go back to the question step
  });
  
  // Animate transition
  _controller.forward(from: 0);
}


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  void _applyPendingChangesAndComplete() {
    // Apply all pending actions
    for (final action in _pendingActions) {
      action();
    }
    _pendingActions.clear();
    
    // Call the completion callback
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: _currentStep == 0
          ? _buildQuestionStep()
          : _buildEditingInterface(),
    );
  }

  // ====================================================================
  // STEP 1: "What is your book about?" Question
  // ====================================================================
Widget _buildQuestionStep() {
  return Material(  // ✅ ADD THIS
    color: Colors.transparent,  // ✅ ADD THIS
    child: Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: widget.onSkip,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Animated emoji
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: const Text(
                        '📚',
                        style: TextStyle(fontSize: 72),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Question title
                const Text(
                  'What is your book about?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  'Tell us in a few words so we can help you create it',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Input field
                TextField(
                  controller: _topicController,
                  autofocus: true,
                  maxLength: 100,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g., My Summer Vacation Adventures',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onSubmitted: (_) => _goToEditingMode(),
                ),
                
                const SizedBox(height: 32),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: widget.onSkip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Skip for Now',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _goToEditingMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
     )
    );
  }

  // ====================================================================
  // STEP 2: Full Editing Interface
  // ====================================================================
Widget _buildEditingInterface() {
  final bookId = ref.watch(currentBookIdProvider);
  if (bookId == null) {
    return Material(  // ✅ ADD THIS
      color: Colors.transparent,  // ✅ ADD THIS
      child: const Center(
        child: Text(
          'No book loaded',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  final pagesAsync = ref.watch(bookPagesProvider(bookId));
  final pageIndex = ref.watch(currentPageIndexProvider);

  return Material(  // ✅ ADD THIS
    color: Colors.transparent,  // ✅ ADD THIS
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Banner - Book Topic
            _buildTopicBanner(),

            // Main Content Area
            Expanded(
              child: pagesAsync.when(
                data: (pages) {
                  if (pages.isEmpty) {
                    return const Center(
                      child: Text('No pages available'),
                    );
                  }

                  return Row(
                    children: [
                      // Canvas Area (Left/Center) - Takes most space
                      Expanded(
                        flex: 3,
                        child: _buildCanvasArea(bookId, pages, pageIndex),
                      ),

                      // Elements Panel (Right)
                      SizedBox(
                        width: 320,
                        child: _buildElementsPanel(pages, pageIndex),
                      ),
                    ],
                  );
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
        ),
      ),
     )
    );
  }

  // ====================================================================
  // Top Banner - Shows book topic
  // ====================================================================
  Widget _buildTopicBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200),
        ),
      ),
      child: Row(
        children: [
          // Book emoji
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text('📚', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your book is about:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _bookTopic,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Edit button
          IconButton(
            onPressed: _goBackToQuestion,
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Change topic',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),

          // Close wizard
          IconButton(
            onPressed: widget.onSkip,
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Exit wizard',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // Canvas Area - Displays the actual page canvas from main editor
  // ====================================================================
  Widget _buildCanvasArea(String bookId, List<BookPage> pages, int pageIndex) {
    if (pages.isEmpty || pageIndex >= pages.length) {
      return const Center(child: Text('No page available'));
    }

    final currentPage = pages[pageIndex];
    final canvasWidth = currentPage.pageSize?.width ?? 800.0;
    final canvasHeight = currentPage.pageSize?.height ?? 600.0;

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          width: canvasWidth * 0.5, // 50% zoom for better fit
          height: canvasHeight * 0.5,
          decoration: BoxDecoration(
            color: currentPage.background.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Background image
                if (currentPage.background.imageUrl != null)
                  Positioned.fill(
                    child: Image.network(
                      currentPage.background.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    ),
                  ),

                // Elements (simplified preview)
                ...currentPage.elements.map((element) =>
                    _buildElementPreview(element, canvasWidth, canvasHeight)),

                // Empty state
                if (currentPage.elements.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Click elements on the right\nto add them to your page',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElementPreview(
    PageElement element,
    double canvasWidth,
    double canvasHeight,
  ) {
    final scale = 0.5; // Match canvas zoom
    final scaledLeft = element.position.dx * scale;
    final scaledTop = element.position.dy * scale;
    final scaledWidth = element.size.width * scale;
    final scaledHeight = element.size.height * scale;

    return Positioned(
      left: scaledLeft,
      top: scaledTop,
      width: scaledWidth,
      height: scaledHeight,
      child: Transform.rotate(
        angle: element.rotation,
        child: _buildElementContent(element),
      ),
    );
  }

  Widget _buildElementContent(PageElement element) {
    switch (element.type) {
      case ElementType.text:
        return Container(
          padding: const EdgeInsets.all(4),
          color: Colors.white.withValues(alpha: 0.8),
          child: Text(
            element.properties['text'] ?? '',
            style: element.textStyle?.copyWith(fontSize: (element.textStyle?.fontSize ?? 18) * 0.5) ?? 
                   const TextStyle(fontSize: 9),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );

      case ElementType.image:
        return Image.network(
          element.properties['imageUrl'] ?? '',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.image, size: 24),
          ),
        );

      case ElementType.shape:
        return Container(
          decoration: BoxDecoration(
            color: _parseColor(element.properties['color']),
            shape: element.properties['shapeType'] == 'circle'
                ? BoxShape.circle
                : BoxShape.rectangle,
          ),
        );

      case ElementType.audio:
        return Container(
          color: const Color(0xFF2C3E50),
          child: const Center(
            child: Icon(Icons.audiotrack, color: Colors.white, size: 24),
          ),
        );

      case ElementType.video:
        return Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
          ),
        );

      default:
        return const SizedBox();
    }
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
      debugPrint('Error parsing color: $colorValue');
    }
    return Colors.blue;
  }

  // ====================================================================
  // Elements Panel - Right side with add buttons
  // ====================================================================
  Widget _buildElementsPanel(List<BookPage> pages, int pageIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'What would you like\nto add?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Page ${pageIndex + 1} of ${pages.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Elements List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
  _buildElementButton(
    emoji: '📝',
    label: 'Add Text',
    description: 'Write titles, paragraphs, or lists',
    color: Colors.blue,
    onTap: () {
      // ✅ Call the parent's add text function WITHOUT closing wizard
      widget.onAddText();
      _showSnackBar('Text element added!');
    },
  ),
  const SizedBox(height: 12),

  _buildElementButton(
    emoji: '🖼️',
    label: 'Add Image',
    description: 'Upload or search for pictures',
    color: Colors.green,
    onTap: () {
      // ✅ Call the parent's add image function WITHOUT closing wizard
      widget.onAddImage();
      _showSnackBar('Adding image...');
    },
  ),
  const SizedBox(height: 12),

  _buildElementButton(
    emoji: '🎨',
    label: 'Add Shape',
    description: 'Circles, squares, and more',
    color: Colors.purple,
    onTap: () {
      // ✅ Call the parent's add shape function WITHOUT closing wizard
      widget.onAddShape();
      _showSnackBar('Choose a shape');
    },
  ),
  const SizedBox(height: 12),

  _buildElementButton(
    emoji: '🎵',
    label: 'Add Audio',
    description: 'Add music or narration',
    color: Colors.orange,
    onTap: () {
      // ✅ Call the parent's add audio function WITHOUT closing wizard
      widget.onAddAudio();
      _showSnackBar('Adding audio...');
    },
  ),
  const SizedBox(height: 12),

  _buildElementButton(
    emoji: '🎬',
    label: 'Add Video',
    description: 'Include video clips',
    color: Colors.red,
    onTap: () {
      // ✅ Call the parent's add video function WITHOUT closing wizard
      widget.onAddVideo();
      _showSnackBar('Adding video...');
    },
  ),

  const SizedBox(height: 24),
  const Divider(),
  const SizedBox(height: 12),

  _buildElementButton(
    emoji: '🎨',
    label: 'Change Background',
    description: 'Set page color or image',
    color: Colors.teal,
    onTap: () {
      // ✅ Call the parent's change background function WITHOUT closing wizard
      widget.onChangeBackground();
      _showSnackBar('Change page background');
    },
  ),
],
            ),
          ),

          // Bottom Navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Page Navigation
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: pageIndex > 0
                            ? () => ref
                                .read(currentPageIndexProvider.notifier)
                                .setPageIndex(pageIndex - 1)
                            : null,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Previous'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: pageIndex < pages.length - 1
                            ? () => ref
                                .read(currentPageIndexProvider.notifier)
                                .setPageIndex(pageIndex + 1)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Next Page'),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Finish Editing Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _applyPendingChangesAndComplete,
                    icon: const Icon(Icons.check_circle, size: 22),
                    label: const Text(
                      'Finish Editing',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementButton({
    required String emoji,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              // Emoji
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
  // lib/pages/book_creator/book_creator_page.dart
  import 'dart:io';
  import 'package:flutter/services.dart';
  import 'package:file_picker/file_picker.dart';
  import 'package:flutter/gestures.dart';  
  import 'dart:async';
  import 'dart:math' as math;
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:image_picker/image_picker.dart';
  import '../../app_theme.dart';
  import '../../models/book_models.dart';
  import '../../providers/book_providers.dart';
  import '../../services/storage_service.dart';
  import '../../services/undo_redo_manager.dart';
  import '../book_creator/widgets/properties_panel.dart';
  import '../book_creator/widgets/editor_toolbar.dart';
  import '../book_creator/widgets/pages_panel.dart';
  import '../book_creator/widgets/advanced_text_editor.dart';
  import '../book_creator/widgets/background_settings_dialog.dart';
  import '../book_creator/widgets/shape_picker_dialog.dart';
  import '../book_creator/widgets/image_search_dialog.dart';
  import 'package:video_player/video_player.dart';
  import 'widgets/audio_player_widget.dart';
  import '../book_view/book_view_page.dart';


  class BookCreatorPage extends ConsumerStatefulWidget {
    final String? bookId;

    const BookCreatorPage({super.key, this.bookId});

    @override
    ConsumerState<BookCreatorPage> createState() => _BookCreatorPageState();
  }

  class _BookCreatorPageState extends ConsumerState<BookCreatorPage> {
    bool _isDarkMode = false;
    bool _isLoading = true;
    bool _isSaving = false;
    String? _selectedElementId;
    String? _errorMessage;
    Timer? _autoSaveTimer;
    Timer? _safetyTimer;

    final Map<String, PageElement> _localElementCache = {};
    Timer? _propertyUpdateDebouncer;

      // 🚀 NEW: Track which element is actively being edited
    String? _activelyEditingElementId;
    Timer? _editingTimeoutTimer;


    
  // 🚀 DRAG STATE: Single source of truth
  Offset? _dragStartGlobalMousePosition; // Mouse position in global space
  Offset? _dragStartElementPosition;     // Element position when drag started
  Offset? _dragMouseOffset;              // Offset from element top-left to mouse click point  
    
    // 🚀 NEW: Track original state for resizing
    Offset? _resizeStartMousePosition;
    Size? _resizeStartElementSize;
    Offset? _resizeStartElementPosition;

  // ✅ Helper to check if user is interacting
  bool get isUserInteracting => 
      _currentlyDraggingId != null || 
      _currentlyResizingId != null || 
      _currentlyRotatingId != null; 


    // Grid settings
    bool _gridEnabled = false;
    double _gridSize = 20.0;
    bool _snapToGrid = true;

    //zoom
    double _zoomLevel = 0.5; // ✅ 50% zoom by default
    static const double _minZoom = 0.25; // 25% minimum
    static const double _maxZoom = 3.0; // 300% maximum
    static const List<double> _zoomPresets = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0];
    ScrollController? _horizontalScrollController;
    ScrollController? _verticalScrollController;
    bool _hasUserScrolled = false;
    
    // Local state for smooth interactions
    final Map<String, Offset> _elementOffsets = {};
    final Map<String, Size> _elementSizes = {};
    final Map<String, double> _elementRotations = {};
    String? _currentlyDraggingId;
    String? _currentlyResizingId;
    String? _currentlyRotatingId;

  final Map<String, Offset> _originalPositions = {};
  final Map<String, Size> _originalSizes = {};
  final Map<String, ValueNotifier<Offset>> _dragPositionNotifiers = {};

  // Track if we should ignore provider updates during interaction

    // 🚀 PERFORMANCE: Debounce database writes
  Timer? _databaseWriteDebouncer;
  final Map<String, ({Offset? position, Size? size, double? rotation})> _pendingUpdates = {};

  List<BookPage>? _localCanvasPageOrder;

    // Undo/Redo
    final UndoRedoManager _undoRedoManager = UndoRedoManager();
    
    final StorageService _storageService = StorageService();
    final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // ✅ INITIALIZE SCROLL CONTROLLERS
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    
    // Track when user manually scrolls
    _horizontalScrollController!.addListener(() {
      if ((_horizontalScrollController!.offset - _horizontalScrollController!.initialScrollOffset).abs() > 100) {
        _hasUserScrolled = true;
      }
    });
    
    _verticalScrollController!.addListener(() {
      if ((_verticalScrollController!.offset - _verticalScrollController!.initialScrollOffset).abs() > 100) {
        _hasUserScrolled = true;
      }
    });

    // Delay provider modification to after widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBook();
    });
    _startAutoSave();
    _startSafetyTimer();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _safetyTimer?.cancel();
    _databaseWriteDebouncer?.cancel();
    _propertyUpdateDebouncer?.cancel();
    _editingTimeoutTimer?.cancel();


    _horizontalScrollController?.dispose();
    _verticalScrollController?.dispose();

    _dragStartGlobalMousePosition = null;
    _dragStartElementPosition = null;
    _dragMouseOffset = null;


    _elementOffsets.clear();
    _elementSizes.clear();
    _elementRotations.clear();
    _originalPositions.clear();
    _originalSizes.clear();

    for (var notifier in _dragPositionNotifiers.values) {
      notifier.dispose();
    }
    _dragPositionNotifiers.clear();

    _dragStartGlobalMousePosition = null;
    _dragStartElementPosition = null;
    _dragMouseOffset = null;
    _dragStartElementPosition = null;

    _resizeStartMousePosition = null;
    _resizeStartElementSize = null;
    _resizeStartElementPosition = null;


    super.dispose();
  }

  void _centerCanvas(double canvasWidth, double canvasHeight) {
    // Wait a bit longer for everything to load properly
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_horizontalScrollController == null || 
          _verticalScrollController == null ||
          !_horizontalScrollController!.hasClients ||
          !_verticalScrollController!.hasClients ||
          !mounted) {
        return;
      }
      
      // Don't re-center if user has manually scrolled
      if (_hasUserScrolled) {
        return;
      }
      
      // Get viewport dimensions (visible area)
      final viewportWidth = _horizontalScrollController!.position.viewportDimension;
      final viewportHeight = _verticalScrollController!.position.viewportDimension;
      
      // Get scaled canvas dimensions
      final scaledCanvasWidth = canvasWidth * _zoomLevel;
      final scaledCanvasHeight = canvasHeight * _zoomLevel;
      
      // Calculate total content size (canvas + padding)
      final totalContentWidth = scaledCanvasWidth + 80;
      final totalContentHeight = scaledCanvasHeight + 80;
      
      // Calculate center positions
      // This formula centers the canvas in the visible viewport
      final horizontalCenter = (totalContentWidth - viewportWidth) / 2;
      final verticalCenter = (totalContentHeight - viewportHeight) / 2;
      
      // Scroll horizontally to center
      if (horizontalCenter > 0) {
        _horizontalScrollController!.jumpTo(
          horizontalCenter.clamp(0.0, _horizontalScrollController!.position.maxScrollExtent)
        );
      }
      
      // Scroll vertically to center
      if (verticalCenter > 0) {
        _verticalScrollController!.jumpTo(
          verticalCenter.clamp(0.0, _verticalScrollController!.position.maxScrollExtent)
        );
      }
    });
  }

    // Snap to grid helpers


  void _zoomIn() {
    setState(() {
      // Increase by 10% increments for smoother control
      _zoomLevel = (_zoomLevel + 0.1).clamp(_minZoom, _maxZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      // Decrease by 10% increments for smoother control
      _zoomLevel = (_zoomLevel - 0.1).clamp(_minZoom, _maxZoom);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 0.5;
    });
  }
  void _setZoom(double zoom) {
    setState(() {
      _zoomLevel = zoom.clamp(_minZoom, _maxZoom);
    });
  }

  String _getZoomPercentage() {
    return '${(_zoomLevel * 100).round()}%';
  }

  Future<void> _initializeBook() async {
    debugPrint('🟢 === BookCreatorPage._initializeBook START ===');
    debugPrint('Widget bookId: ${widget.bookId}');
    
    // ✅ ADD SAFETY CHECKS
    if (widget.bookId == null) {
      debugPrint('❌ ERROR: Book ID is null!');
      setState(() {
        _isLoading = false;
        _errorMessage = 'No book ID provided';
      });
      return;
    }
    
    if (widget.bookId!.isEmpty || widget.bookId == '0') {
      debugPrint('❌ ERROR: Invalid book ID: ${widget.bookId}');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid book ID';
      });
      return;
    }
    
    debugPrint('Widget bookId length: ${widget.bookId!.length}');
    
    try {
      if (widget.bookId != null) {
        debugPrint('✅ Existing book - loading bookId: ${widget.bookId}');
        
        // Set the current book ID in provider
        debugPrint('🔧 Setting currentBookId in provider...');
        ref.read(currentBookIdProvider.notifier).setBookId(widget.bookId);
        
        // Wait for provider to load
        debugPrint('⏳ Waiting for bookProvider to load...');
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Check if book exists
        final bookAsync = ref.read(bookProvider(widget.bookId!));
        await bookAsync.when(
          data: (book) async {
            if (book == null) {
              debugPrint('❌ Book not found in database!');
              setState(() {
                _isLoading = false;
                _errorMessage = 'Book not found';
              });
              return;
            }
            debugPrint('✅ Book loaded: ${book.title}');
            debugPrint('📏 Book page size: ${book.pageSize.width}x${book.pageSize.height}');
          },
          loading: () {
            debugPrint('⏳ Book still loading...');
          },
          error: (error, stack) {
            debugPrint('❌ Error loading book: $error');
            setState(() {
              _isLoading = false;
              _errorMessage = 'Error loading book: $error';
            });
          },
        );
        
        // Load pages
        debugPrint('📄 Loading pages...');
        final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
        await pagesAsync.when(
          data: (pages) {
            debugPrint('✅ Loaded ${pages.length} pages');
            if (pages.isEmpty) {
              debugPrint('⚠️ WARNING: Book has no pages!');
            } else {
              debugPrint('📏 First page size: ${pages[0].pageSize?.width ?? "null"}x${pages[0].pageSize?.height ?? "null"}');
            }
          },
          loading: () {
            debugPrint('⏳ Pages still loading...');
          },
          error: (error, stack) {
            debugPrint('❌ Error loading pages: $error');
          },
        );
        
        debugPrint('✅ Initialization complete, setting loading to false');
        setState(() => _isLoading = false);
        
      } else {
        // New book should be created from dashboard with size already selected
        debugPrint('❌ No bookId provided!');
        setState(() {
          _isLoading = false;
          _errorMessage = 'No book ID provided. Please create book from dashboard.';
        });
        
        // Navigate back after a short delay
        debugPrint('🔙 Navigating back to dashboard...');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e, stack) {
      debugPrint('❌ Exception in _initializeBook: $e');
      debugPrint('Stack trace: $stack');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
    
    debugPrint('🟢 === BookCreatorPage._initializeBook END ===');
  }
  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_currentlyDraggingId != null || 
          _currentlyResizingId != null || 
          _currentlyRotatingId != null) {
        debugPrint('⏸️ Auto-save skipped - user is interacting');
        return;
      }
      
      await _saveCurrentPage();
    });
  }

    void _startSafetyTimer() {
      _safetyTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_currentlyResizingId != null && mounted) {
          debugPrint('Safety: Clearing potentially stuck resize state');
          setState(() {
            _currentlyResizingId = null;
          });
        }
      });
    }

    Future<void> _saveCurrentPage() async {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      setState(() => _isSaving = true);
      
      // Save current state to undo manager
      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);
      
      await pagesAsync.when(
        data: (pages) {
          if (pages.isNotEmpty && pageIndex < pages.length) {
            final currentPage = pages[pageIndex];
            _undoRedoManager.saveState(currentPage.elements, currentPage.background);
          }
        },
        loading: () {},
        error: (_, _) {},
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isSaving = false);
    }

    // Undo/Redo Methods
    void _undo() async {
      final state = _undoRedoManager.undo();
      if (state == null) return;

      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          
          final currentPage = pages[pageIndex];
          final pageActions = ref.read(pageActionsProvider);
          
          for (var element in state.elements) {
            await pageActions.updateElement(currentPage.id, element);
          }
          
      
        },
        loading: () {},
        error: (_, _) {},
      );
    }

    void _redo() async {
      final state = _undoRedoManager.redo();
      if (state == null) return;

      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          
          final currentPage = pages[pageIndex];
          final pageActions = ref.read(pageActionsProvider);
          
          for (var element in state.elements) {
            await pageActions.updateElement(currentPage.id, element);
          }
          
        },
        loading: () {},
        error: (_, _) {},
      );
    }

    void _addTextElement() async {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          
          final currentPage = pages[pageIndex];
          final newElement = PageElement.text(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'Double tap to edit',
            position: const Offset(100, 100),
            size: const Size(200, 50),
            style: const TextStyle(fontSize: 18, color: Colors.black, fontFamily: 'Roboto'),
            textAlign: TextAlign.left,
            lineHeight: 1.2,
          );

          _undoRedoManager.saveState(currentPage.elements, currentPage.background);

          final pageActions = ref.read(pageActionsProvider);
          await pageActions.addElement(currentPage.id, newElement);
          
          setState(() => _selectedElementId = newElement.id);
        },
        loading: () {},
        error: (_, _) {},
      );
    }

  Future<void> _addImageElement() async {
    // Show choice dialog: Upload OR Search
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Image'),
        content: const Text('How would you like to add an image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'upload'),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload from Device'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'search'),
            icon: const Icon(Icons.search),
            label: const Text('Search Online'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel') return;

    String? imageUrl;

    if (choice == 'upload') {
      // ✅ CROSS-PLATFORM UPLOAD FIX
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Optional: compress image to reduce size
      );
      
      if (image == null) return;

      _showSnackBar('Uploading image...');

      try {
        // Read bytes immediately to avoid platform-specific File/XFile issues
        debugPrint('📸 Reading image bytes from picker...');
        final bytes = await image.readAsBytes();
        debugPrint('✅ Image bytes read: ${bytes.length} bytes');
        
        // Upload using Uint8List (works on all platforms)
        imageUrl = await _storageService.uploadFile(
          bytes,
          'book-images',
          'images',
          originalFileName: image.name, // Preserve filename for extension
        );

        if (imageUrl == null) {
          _showSnackBar('Failed to upload image. Please try again.');
          return;
        }
        
        debugPrint('✅ Image uploaded successfully: $imageUrl');
      } catch (e) {
        debugPrint('❌ Error uploading image: $e');
        _showSnackBar('Failed to upload image: $e');
        return;
      }
    } else if (choice == 'search') {
      // Show image search dialog (online search)
      imageUrl = await showDialog<String>(
        context: context,
        builder: (context) => const ImageSearchDialog(),
      );

      if (imageUrl == null) return;
    }

    // Add image element to canvas
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
    final pageIndex = ref.read(currentPageIndexProvider);

    await pagesAsync.when(
      data: (pages) async {
        if (pages.isEmpty || pageIndex >= pages.length) return;
        
        final currentPage = pages[pageIndex];
        
        _undoRedoManager.saveState(currentPage.elements, currentPage.background);
        
        final newElement = PageElement.image(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imageUrl: imageUrl!,
          position: const Offset(100, 100),
          size: const Size(200, 200),
        );

        final pageActions = ref.read(pageActionsProvider);
        await pageActions.addElement(currentPage.id, newElement);
        
        _showSnackBar('Image added successfully');
        setState(() => _selectedElementId = newElement.id);
      },
      loading: () {},
      error: (_, _) {},
    );
  }

    void _addShapeElement() {
      showDialog(
        context: context,
        builder: (context) => ShapePickerDialog(
          onShapeSelected: (shapeType, color, strokeWidth) async {
            final bookId = ref.read(currentBookIdProvider);
            if (bookId == null) return;

            final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
            final pageIndex = ref.read(currentPageIndexProvider);

            await pagesAsync.when(
              data: (pages) async {
                if (pages.isEmpty || pageIndex >= pages.length) return;
                
                final currentPage = pages[pageIndex];
                
                _undoRedoManager.saveState(currentPage.elements, currentPage.background);
                
                final newElement = PageElement.shape(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  shapeType: shapeType,
                  position: const Offset(100, 100),
                  size: const Size(150, 150),
                  color: color,
                  strokeWidth: strokeWidth,
                  filled: true,
                );

                final pageActions = ref.read(pageActionsProvider);
                await pageActions.addElement(currentPage.id, newElement);
                
                setState(() => _selectedElementId = newElement.id);
              },
              loading: () {},
              error: (_, _) {},
            );
          },
        ),
      );
    }

  // ADD THESE TWO NEW METHODS AFTER _addShapeElement()

  void _addAudioElement() async {
    try {
      // Pick audio file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      _showSnackBar('Uploading audio...');

      // Upload to Supabase
      final audioUrl = await _storageService.uploadAudio(
        file.bytes ?? await File(file.path!).readAsBytes(),
        'audio',
        originalFileName: file.name,
      );

      if (audioUrl == null) {
        _showSnackBar('Failed to upload audio');
        return;
      }

      // Add audio element to canvas
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          
          final currentPage = pages[pageIndex];
          _undoRedoManager.saveState(currentPage.elements, currentPage.background);
          
          final newElement = PageElement.audio(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            audioUrl: audioUrl,
            position: const Offset(100, 100),
            size: const Size(350, 120),
            title: file.name,
          );

          final pageActions = ref.read(pageActionsProvider);
          await pageActions.addElement(currentPage.id, newElement);
          
          _showSnackBar('Audio added successfully');
          setState(() => _selectedElementId = newElement.id);
        },
        loading: () {},
        error: (_, _) {},
      );
    } catch (e) {
      debugPrint('Error adding audio: $e');
      _showSnackBar('Failed to add audio: $e');
    }
  }

  void _addVideoElement() async {
    try {
      // Pick video file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      
      // Check file size (50MB limit)
      if (file.size > 50 * 1024 * 1024) {
        _showSnackBar('Video too large! Maximum size is 50MB');
        return;
      }

      _showSnackBar('Uploading video... This may take a while');

      // Upload to Supabase
      final videoUrl = await _storageService.uploadVideo(
        file.bytes ?? await File(file.path!).readAsBytes(),
        'videos',
        originalFileName: file.name,
      );

      if (videoUrl == null) {
        _showSnackBar('Failed to upload video');
        return;
      }

      // ✅ ADD DEBUG HERE
      debugPrint('✅ Video uploaded successfully: $videoUrl');

      // Add video element to canvas
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          
          final currentPage = pages[pageIndex];
          _undoRedoManager.saveState(currentPage.elements, currentPage.background);
          
          final newElement = PageElement.video(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            videoUrl: videoUrl,
            position: const Offset(100, 100),
            size: const Size(400, 300),
          );

          // ✅ ADD DEBUG HERE
          debugPrint('🎬 Creating video element with properties: ${newElement.properties}');

          final pageActions = ref.read(pageActionsProvider);
          await pageActions.addElement(currentPage.id, newElement);
          
          _showSnackBar('Video added successfully');
          setState(() => _selectedElementId = newElement.id);
        },
        loading: () {},
        error: (_, _) {},
      );
    } catch (e) {
      debugPrint('Error adding video: $e');
      _showSnackBar('Failed to add video: $e');
    }
  }

  void _deleteElement(String elementId) async {
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
    final pageIndex = ref.read(currentPageIndexProvider);

    await pagesAsync.when(
      data: (pages) async {
        if (pages.isEmpty || pageIndex >= pages.length) return;
        
        final currentPage = pages[pageIndex];
        
        // Find the element to check if it's locked
        final element = currentPage.elements.firstWhere(
          (e) => e.id == elementId,
          orElse: () => currentPage.elements.first,
        );
        
        if (element.locked) {
          _showSnackBar('Element is locked. Unlock it to delete.');
          return;
        }
        
        _undoRedoManager.saveState(currentPage.elements, currentPage.background);
        
        final pageActions = ref.read(pageActionsProvider);
        await pageActions.removeElement(currentPage.id, elementId);
        
        setState(() {
          _selectedElementId = null;
          _elementOffsets.remove(elementId);
          _elementSizes.remove(elementId);
          _elementRotations.remove(elementId);
        });
      },
      loading: () {},
      error: (_, _) {},
    );
  }

  void _showElementContextMenu(BuildContext context, Offset position, PageElement element, String pageId) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      constraints: const BoxConstraints(
        maxHeight: 500, // ← Add this to allow scrolling
        minWidth: 200,
      ),
      items: [
        // Copy
        const PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 12),
              Text('Copy'),
              Spacer(),
              Text('Ctrl+C', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        
        // Duplicate
        const PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 12),
              Text('Duplicate'),
              Spacer(),
              Text('Ctrl+D', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        
        const PopupMenuDivider(),
        
        // Delete
        PopupMenuItem<String>(
          value: 'delete',
          enabled: !element.locked,
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: element.locked ? Colors.grey : Colors.red),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: element.locked ? Colors.grey : Colors.red)),
              const Spacer(),
              Text('Delete', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        
        const PopupMenuDivider(),
        
        // Lock/Unlock
        PopupMenuItem<String>(
          value: 'toggle_lock',
          child: Row(
            children: [
              Icon(element.locked ? Icons.lock_open : Icons.lock, size: 18),
              const SizedBox(width: 12),
              Text(element.locked ? 'Unlock' : 'Lock'),
              const Spacer(),
              Text('Ctrl+L', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        
        const PopupMenuDivider(),
        
        // Bring to Front
        const PopupMenuItem<String>(
          value: 'bring_to_front',
          child: Row(
            children: [
              Icon(Icons.vertical_align_top, size: 18),
              SizedBox(width: 12),
              Text('Bring to Front'),
              Spacer(),
              Text('Ctrl+]', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        
        // Bring Forward
        const PopupMenuItem<String>(
          value: 'bring_forward',
          child: Row(
            children: [
              Icon(Icons.arrow_upward, size: 18),
              SizedBox(width: 12),
              Text('Bring Forward'),
              Spacer(),
              Text(']', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        
        // Send Backward
        const PopupMenuItem<String>(
          value: 'send_backward',
          child: Row(
            children: [
              Icon(Icons.arrow_downward, size: 18),
              SizedBox(width: 12),
              Text('Send Backward'),
              Spacer(),
              Text('[', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        
        // Send to Back
        const PopupMenuItem<String>(
          value: 'send_to_back',
          child: Row(
            children: [
              Icon(Icons.vertical_align_bottom, size: 18),
              SizedBox(width: 12),
              Text('Send to Back'),
              Spacer(),
              Text('Ctrl+[', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        
        const PopupMenuDivider(),
        
        // Edit (for text elements)
        if (element.type == ElementType.text)
          PopupMenuItem<String>(
            value: 'edit',
            enabled: !element.locked,
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: element.locked ? Colors.grey : null),
                const SizedBox(width: 12),
                Text('Edit Text', style: TextStyle(color: element.locked ? Colors.grey : null)),
                const Spacer(),
                Text('Enter', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
      ],
    );

    // Handle menu actions
    if (result != null) {
      await _handleContextMenuAction(result, element, pageId);
    }
  }

  Future<void> _handleContextMenuAction(String action, PageElement element, String pageId) async {
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
    final pageIndex = ref.read(currentPageIndexProvider);

    switch (action) {
      case 'copy':

        _showSnackBar('Copy - Coming Soon');
        break;

      case 'duplicate':
        await pagesAsync.when(
          data: (pages) async {
            if (pages.isEmpty || pageIndex >= pages.length) return;
            final currentPage = pages[pageIndex];
            
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

            final pageActions = ref.read(pageActionsProvider);
            await pageActions.addElement(currentPage.id, newElement);
            setState(() => _selectedElementId = newElement.id);
            _showSnackBar('Element duplicated');
          },
          loading: () {},
          error: (_, _) {},
        );
        break;

      case 'delete':
        if (!element.locked) {
          _deleteElement(element.id);
        }
        break;

      case 'toggle_lock':
        await pagesAsync.when(
          data: (pages) async {
            if (pages.isEmpty || pageIndex >= pages.length) return;
            final currentPage = pages[pageIndex];
            final pageActions = ref.read(pageActionsProvider);
            await pageActions.toggleElementLock(currentPage.id, element.id);
            _showSnackBar(element.locked ? 'Element unlocked' : 'Element locked');
          },
          loading: () {},
          error: (_, _) {},
        );
        break;

      case 'bring_to_front':
      case 'bring_forward':
      case 'send_backward':
      case 'send_to_back':
        await pagesAsync.when(
          data: (pages) async {
            if (pages.isEmpty || pageIndex >= pages.length) return;
            final currentPage = pages[pageIndex];
            final elements = currentPage.elements;
            final currentIndex = elements.indexWhere((e) => e.id == element.id);

            if (currentIndex == -1) return;

            List<PageElement>? newOrder;

            switch (action) {
              case 'bring_to_front':
                newOrder = List.from(elements);
                newOrder.removeAt(currentIndex);
                newOrder.add(element);
                break;
              case 'bring_forward':
                if (currentIndex < elements.length - 1) {
                  newOrder = List.from(elements);
                  newOrder.removeAt(currentIndex);
                  newOrder.insert(currentIndex + 1, element);
                }
                break;
              case 'send_backward':
                if (currentIndex > 0) {
                  newOrder = List.from(elements);
                  newOrder.removeAt(currentIndex);
                  newOrder.insert(currentIndex - 1, element);
                }
                break;
              case 'send_to_back':
                newOrder = List.from(elements);
                newOrder.removeAt(currentIndex);
                newOrder.insert(0, element);
                break;
            }

            if (newOrder != null) {
              final pageActions = ref.read(pageActionsProvider);
              await pageActions.reorderElements(currentPage.id, newOrder);
              _showSnackBar('Layer order updated');
            }
          },
          loading: () {},
          error: (_, _) {},
        );
        break;

      case 'edit':
        if (element.type == ElementType.text && !element.locked) {
          _editTextElement(element);
        }
        break;
    }
  }

  void _showBackgroundSettings() async {
    debugPrint('🎨 === BACKGROUND SETTINGS CLICKED ===');
    
    final bookId = ref.read(currentBookIdProvider);
    debugPrint('📚 Current Book ID: $bookId');
    
    if (bookId == null) {
      debugPrint('❌ No book ID found!');
      return;
    }

    final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
    final pageIndex = ref.read(currentPageIndexProvider);
    debugPrint('📄 Current Page Index: $pageIndex');

    await pagesAsync.when(
      data: (pages) async {
        debugPrint('📋 Total Pages: ${pages.length}');
        
        if (pages.isEmpty || pageIndex >= pages.length) {
          debugPrint('❌ No valid page found!');
          return;
        }
        
        final currentPage = pages[pageIndex];
        debugPrint('✅ Current Page ID: ${currentPage.id}');
        debugPrint('🎨 Current Background Color: ${currentPage.background.color}');
        debugPrint('🖼️ Current Background Image: ${currentPage.background.imageUrl}');
        
        showDialog(
          context: context,
          builder: (context) => BackgroundSettingsDialog(
            currentBackground: currentPage.background,
            onBackgroundChange: (updatedBackground) async {
              debugPrint('🎨 === BACKGROUND CHANGE CALLBACK ===');
              debugPrint('New Color: ${updatedBackground.color}');
              debugPrint('New Image: ${updatedBackground.imageUrl}');
              
              _undoRedoManager.saveState(currentPage.elements, currentPage.background);
              
              final pageActions = ref.read(pageActionsProvider);
              debugPrint('🔧 Calling pageActions.updatePageBackground...');
              
              final success = await pageActions.updatePageBackground(currentPage.id, updatedBackground);
              debugPrint('✅ Update Result: $success');
              
              // ✅ CRITICAL FIX: Force refresh the provider
              if (success) {
                debugPrint('🔄 Invalidating bookPagesProvider...');
                ref.invalidate(bookPagesProvider(bookId));
                
                // ✅ ALSO REFRESH THE BOOK LIST (for dashboard preview)
                ref.invalidate(userBooksProvider);
                
                debugPrint('✅ Providers invalidated - UI should refresh');
              }
              
              _showSnackBar('Background updated');
            },
          ),
        );
      },
      loading: () {
        debugPrint('⏳ Pages still loading...');
      },
      error: (error, stack) {
        debugPrint('❌ Error loading pages: $error');
      },
    );
  }

  

  Future<void> _updateElementPosition(String elementId, Offset newPosition) async {
    // 🚀 CRITICAL: Don't write to database during active drag
    if (_currentlyDraggingId == elementId) {
      debugPrint('⏸️ Skipping database write - element is being dragged');
      return;
    }
      debugPrint('🎯 Scheduling position update for $elementId');

    // Keep debouncing for drag
    _databaseWriteDebouncer?.cancel();
    
    final existing = _pendingUpdates[elementId];
    _pendingUpdates[elementId] = (
      position: newPosition,
      size: existing?.size,
      rotation: existing?.rotation,
    );
    
    _databaseWriteDebouncer = Timer(const Duration(milliseconds: 800), () {
      debugPrint('✅ Flushing position update to database');
      _flushPendingUpdate(elementId);
    });
  }


  Future<void> _updateElementSize(String elementId, Size newSize) async {
    debugPrint('🎯 Scheduling size update for $elementId');
    
    // Keep debouncing but shorter delay for resize
    _databaseWriteDebouncer?.cancel();
    
    final existing = _pendingUpdates[elementId];
    _pendingUpdates[elementId] = (
      position: existing?.position,
      size: newSize,
      rotation: existing?.rotation,
    );
    
    _databaseWriteDebouncer = Timer(const Duration(milliseconds: 300), () {
      debugPrint('✅ Flushing size update to database');
      _flushPendingUpdate(elementId);
    });
  }

  Future<void> _flushPendingUpdate(String elementId) async {
    debugPrint('🚀 === FLUSH PENDING UPDATE START ===');
    final update = _pendingUpdates[elementId];
    if (update == null) {
      debugPrint('⚠️ No pending update for $elementId');
      return;
    }
    
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) {
      debugPrint('❌ No bookId found');
      return;
    }

    debugPrint('💾 Writing to database: position=${update.position}, size=${update.size}, rotation=${update.rotation}');

    try {
      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) {
            debugPrint('❌ No valid pages found');
            return;
          }
          
          final currentPage = pages[pageIndex];
          final element = currentPage.elements.firstWhere((e) => e.id == elementId);
          
          debugPrint('📊 Before Update - DB Element: size=${element.size}, position=${element.position}');
          
          final updatedElement = PageElement(
            id: element.id,
            type: element.type,
            position: update.position ?? element.position,
            size: update.size ?? element.size,
            rotation: update.rotation ?? element.rotation,
            properties: element.properties,
            textStyle: element.textStyle,
            textAlign: element.textAlign,
            lineHeight: element.lineHeight,
            shadows: element.shadows,
            locked: element.locked,
          );

          debugPrint('📊 After Update - New Element: size=${updatedElement.size}, position=${updatedElement.position}');

          final pageActions = ref.read(pageActionsProvider);
          final success = await pageActions.updateElement(currentPage.id, updatedElement);
          
          if (success) {
            debugPrint('✅ Database write complete for $elementId');
            // 🚀 Force provider refresh on success
            ref.invalidate(bookPagesProvider(bookId));
          } else {
            debugPrint('❌ Database write failed for $elementId');
          }
        },
        loading: () {
          debugPrint('⏳ Pages still loading...');
        },
        error: (error, stack) {
          debugPrint('❌ Error in flush: $error');
        },
      );
    } catch (e) {
      debugPrint('❌ Error flushing update: $e');
    } finally {
      // Only remove from pending updates if we're not currently interacting
      if (_currentlyResizingId != elementId && _currentlyDraggingId != elementId) {
        _pendingUpdates.remove(elementId);
        debugPrint('🧹 Removed $elementId from pending updates');
      }
    }
    
    debugPrint('🚀 === FLUSH PENDING UPDATE END ===');
  }


  Future<void> _updateElementPositionAndSize(String elementId, Offset newPosition, Size newSize) async {
    debugPrint('🎯 Scheduling position+size update for $elementId');
    
    _databaseWriteDebouncer?.cancel();
    
    // 🚀 CRITICAL: Store the update immediately in pending updates
    _pendingUpdates[elementId] = (
      position: newPosition,
      size: newSize,
      rotation: _pendingUpdates[elementId]?.rotation,
    );
    
    _databaseWriteDebouncer = Timer(const Duration(milliseconds: 300), () async {
      debugPrint('✅ Flushing position+size update to database');
      await _flushPendingUpdate(elementId);
      
      // 🚀 Force provider refresh after database write
      final bookId = ref.read(currentBookIdProvider);
      if (bookId != null) {
        ref.invalidate(bookPagesProvider(bookId));
      }
    });
  }

  void _updateTextStyle(PageElement element, TextStyle newStyle) async {
    debugPrint('🎨 ============================================');
    debugPrint('🎨 _updateTextStyle CALLED');
    debugPrint('🎨 Element ID: ${element.id}');
    debugPrint('🎨 Old fontSize: ${element.textStyle?.fontSize}');
    debugPrint('🎨 New fontSize: ${newStyle.fontSize}');
    debugPrint('🎨 ============================================');
    
    // ✅ STEP 1: Update local cache IMMEDIATELY for instant UI feedback
    final updatedElement = PageElement(
      id: element.id,
      type: element.type,
      position: element.position,
      size: element.size,
      rotation: element.rotation,
      properties: element.properties,
      textStyle: newStyle,
      textAlign: element.textAlign,
      lineHeight: element.lineHeight,
      shadows: element.shadows,
      locked: element.locked,
    );
    
    debugPrint('🎨 ✅ Step 1: Updating local cache...');
    setState(() {
      _localElementCache[element.id] = updatedElement;
      
      // 🚀 NEW: Mark this element as actively being edited
      _activelyEditingElementId = element.id;
    });
    debugPrint('🎨 ✅ Local cache updated. Cache size: ${_localElementCache.length}');
    debugPrint('🎨 ✅ Element marked as actively editing');
    
    // 🚀 NEW: Reset the "editing timeout" timer (2 seconds of no changes = done editing)
    _editingTimeoutTimer?.cancel();
    _editingTimeoutTimer = Timer(const Duration(seconds: 2), () {
      debugPrint('🎨 ⏰ Editing timeout - user stopped editing');
      if (mounted) {
        setState(() {
          _activelyEditingElementId = null;
        });
      }
    });
    
    // ✅ STEP 2: Debounce database write (500ms)
    _propertyUpdateDebouncer?.cancel();
    debugPrint('🎨 ⏱️ Starting 500ms debounce timer...');
    
    _propertyUpdateDebouncer = Timer(const Duration(milliseconds: 500), () async {
      debugPrint('🎨 💾 ============================================');
      debugPrint('🎨 💾 DEBOUNCE TIMER FIRED - Writing to database');
      debugPrint('🎨 💾 ============================================');
      
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) {
        debugPrint('🎨 ❌ No bookId found, aborting');
        return;
      }
      debugPrint('🎨 📚 Book ID: $bookId');

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);
      debugPrint('🎨 📄 Page Index: $pageIndex');

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) {
            debugPrint('🎨 ❌ Invalid page index');
            return;
          }
          
          final currentPage = pages[pageIndex];
          debugPrint('🎨 📄 Current Page ID: ${currentPage.id}');
          
          final pageActions = ref.read(pageActionsProvider);
          final elementToSave = _localElementCache[element.id] ?? updatedElement;
          
          debugPrint('🎨 💾 Element to save:');
          debugPrint('🎨    - ID: ${elementToSave.id}');
          debugPrint('🎨    - fontSize: ${elementToSave.textStyle?.fontSize}');
          
          debugPrint('🎨 💾 Calling pageActions.updateElement...');
          final success = await pageActions.updateElement(currentPage.id, elementToSave);
          
          if (success) {
            debugPrint('🎨 ✅ Database write successful!');
            debugPrint('🎨 🔄 Invalidating provider to fetch updated data...');
            ref.invalidate(bookPagesProvider(bookId));
            
            debugPrint('🎨 ⏳ Waiting for provider rebuild...');
            await Future.delayed(const Duration(milliseconds: 600));
            
            final freshPages = await ref.read(bookPagesProvider(bookId).future);
            final freshElement = freshPages[pageIndex].elements.firstWhere(
              (e) => e.id == element.id,
              orElse: () => element,
            );

            debugPrint('🎨 🔍 Verification:');
            debugPrint('   Provider fontSize: ${freshElement.textStyle?.fontSize}');
            debugPrint('   Cache fontSize: ${elementToSave.textStyle?.fontSize}');

            // 🚀 CRITICAL FIX: Only clear cache if user is NOT actively editing
            if (_activelyEditingElementId != element.id) {
              if (freshElement.textStyle?.fontSize == elementToSave.textStyle?.fontSize) {
                debugPrint('🎨 ✅ Provider data matches cache - safe to clear');
                if (mounted) {
                  setState(() {
                    _localElementCache.remove(element.id);
                  });
                }
                debugPrint('🎨 ✅ Cache cleared. Remaining cache size: ${_localElementCache.length}');
              } else {
                debugPrint('🎨 ⚠️ Provider data MISMATCH - keeping cache for safety');
              }
            } else {
              debugPrint('🎨 🚫 User still actively editing - KEEPING cache');
            }
          } else {
            debugPrint('🎨 ❌ Database write failed!');
          }
          
          debugPrint('🎨 💾 ============================================');
          debugPrint('🎨 💾 DATABASE WRITE COMPLETE');
          debugPrint('🎨 💾 ============================================');
        },
        loading: () {
          debugPrint('🎨 ⏳ Pages still loading...');
        },
        error: (error, stack) {
          debugPrint('🎨 ❌ Error: $error');
        },
      );
    });
    
    debugPrint('🎨 ✅ Debounce timer scheduled');
    debugPrint('🎨 ============================================\n');
  }

  void _updateTextAlign(PageElement element, TextAlign newAlign) async {
    debugPrint('📐 ============================================');
    debugPrint('📐 _updateTextAlign CALLED');
    debugPrint('📐 Element ID: ${element.id}');
    debugPrint('📐 Old align: ${element.textAlign}');
    debugPrint('📐 New align: $newAlign');
    debugPrint('📐 ============================================');
    
    final updatedElement = PageElement(
      id: element.id,
      type: element.type,
      position: element.position,
      size: element.size,
      rotation: element.rotation,
      properties: element.properties,
      textStyle: element.textStyle,
      textAlign: newAlign,
      lineHeight: element.lineHeight,
      shadows: element.shadows,
      locked: element.locked,
    );
    
    debugPrint('📐 ✅ Updating local cache...');
    setState(() {
      _localElementCache[element.id] = updatedElement;
      
      // 🚀 NEW: Mark this element as actively being edited
      _activelyEditingElementId = element.id;
    });
    debugPrint('📐 ✅ Local cache updated');
    debugPrint('📐 ✅ Element marked as actively editing');
    
    // 🚀 NEW: Reset the "editing timeout" timer
    _editingTimeoutTimer?.cancel();
    _editingTimeoutTimer = Timer(const Duration(seconds: 2), () {
      debugPrint('📐 ⏰ Editing timeout - user stopped editing');
      if (mounted) {
        setState(() {
          _activelyEditingElementId = null;
        });
      }
    });
    
    _propertyUpdateDebouncer?.cancel();
    debugPrint('📐 ⏱️ Starting 500ms debounce timer...');
    
    _propertyUpdateDebouncer = Timer(const Duration(milliseconds: 500), () async {
      debugPrint('📐 💾 Debounce fired - writing to database...');
      
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          final currentPage = pages[pageIndex];
          final pageActions = ref.read(pageActionsProvider);
          
          debugPrint('📐 💾 Writing alignment to database...');
          final elementToSave = _localElementCache[element.id] ?? updatedElement;
          final success = await pageActions.updateElement(currentPage.id, elementToSave);
          
          if (success) {
            debugPrint('📐 ✅ Database write successful!');
            debugPrint('📐 🔄 Invalidating provider...');
            ref.invalidate(bookPagesProvider(bookId));
            
            debugPrint('📐 ⏳ Waiting for provider rebuild...');
            await Future.delayed(const Duration(milliseconds: 600));
            
            final freshPages = await ref.read(bookPagesProvider(bookId).future);
            final freshElement = freshPages[pageIndex].elements.firstWhere(
              (e) => e.id == element.id,
              orElse: () => element,
            );
            
            debugPrint('📐 🔍 Verification:');
            debugPrint('   Provider textAlign: ${freshElement.textAlign}');
            debugPrint('   Cache textAlign: ${elementToSave.textAlign}');
            
            // 🚀 CRITICAL FIX: Only clear cache if user is NOT actively editing
            if (_activelyEditingElementId != element.id) {
              if (freshElement.textAlign == elementToSave.textAlign) {
                debugPrint('📐 ✅ Provider data matches cache - safe to clear');
                if (mounted) {
                  setState(() {
                    _localElementCache.remove(element.id);
                  });
                }
                debugPrint('📐 ✅ Cache cleared');
              } else {
                debugPrint('📐 ⚠️ Provider data MISMATCH - keeping cache');
              }
            } else {
              debugPrint('📐 🚫 User still actively editing - KEEPING cache');
            }
          } else {
            debugPrint('📐 ❌ Database write failed');
          }
          
          debugPrint('📐 ✅ Alignment update complete');
        },
        loading: () {},
        error: (_, _) {},
      );
    });
    
    debugPrint('📐 ============================================\n');
  }


  void _updateLineHeight(PageElement element, double newLineHeight) async {
    debugPrint('📏 ============================================');
    debugPrint('📏 _updateLineHeight CALLED');
    debugPrint('📏 Element ID: ${element.id}');
    debugPrint('📏 Old lineHeight: ${element.lineHeight}');
    debugPrint('📏 New lineHeight: $newLineHeight');
    debugPrint('📏 ============================================');
    
    final updatedElement = PageElement(
      id: element.id,
      type: element.type,
      position: element.position,
      size: element.size,
      rotation: element.rotation,
      properties: element.properties,
      textStyle: element.textStyle,
      textAlign: element.textAlign,
      lineHeight: newLineHeight,
      shadows: element.shadows,
      locked: element.locked,
    );
    
    debugPrint('📏 ✅ Updating local cache...');
    setState(() {
      _localElementCache[element.id] = updatedElement;
      
      // 🚀 NEW: Mark this element as actively being edited
      _activelyEditingElementId = element.id;
    });
    debugPrint('📏 ✅ Local cache updated');
    debugPrint('📏 ✅ Element marked as actively editing');
    
    // 🚀 NEW: Reset the "editing timeout" timer
    _editingTimeoutTimer?.cancel();
    _editingTimeoutTimer = Timer(const Duration(seconds: 2), () {
      debugPrint('📏 ⏰ Editing timeout - user stopped editing');
      if (mounted) {
        setState(() {
          _activelyEditingElementId = null;
        });
      }
    });
    
    _propertyUpdateDebouncer?.cancel();
    debugPrint('📏 ⏱️ Starting 500ms debounce timer...');
    
    _propertyUpdateDebouncer = Timer(const Duration(milliseconds: 500), () async {
      debugPrint('📏 💾 Debounce fired - writing to database...');
      
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          final currentPage = pages[pageIndex];
          final pageActions = ref.read(pageActionsProvider);
          
          debugPrint('📏 💾 Writing line height to database...');
          final elementToSave = _localElementCache[element.id] ?? updatedElement;
          final success = await pageActions.updateElement(currentPage.id, elementToSave);
          
          if (success) {
            debugPrint('📏 ✅ Database write successful!');
            debugPrint('📏 🔄 Invalidating provider...');
            ref.invalidate(bookPagesProvider(bookId));
            
            debugPrint('📏 ⏳ Waiting for provider rebuild...');
            await Future.delayed(const Duration(milliseconds: 600));
            
            final freshPages = await ref.read(bookPagesProvider(bookId).future);
            final freshElement = freshPages[pageIndex].elements.firstWhere(
              (e) => e.id == element.id,
              orElse: () => element,
            );
            
            debugPrint('📏 🔍 Verification:');
            debugPrint('   Provider lineHeight: ${freshElement.lineHeight}');
            debugPrint('   Cache lineHeight: ${elementToSave.lineHeight}');
            
            // 🚀 CRITICAL FIX: Only clear cache if user is NOT actively editing
            if (_activelyEditingElementId != element.id) {
              if ((freshElement.lineHeight ?? 1.2) == (elementToSave.lineHeight ?? 1.2)) {
                debugPrint('📏 ✅ Provider data matches cache - safe to clear');
                if (mounted) {
                  setState(() {
                    _localElementCache.remove(element.id);
                  });
                }
                debugPrint('📏 ✅ Cache cleared');
              } else {
                debugPrint('📏 ⚠️ Provider data MISMATCH - keeping cache');
              }
            } else {
              debugPrint('📏 🚫 User still actively editing - KEEPING cache');
            }
          } else {
            debugPrint('📏 ❌ Database write failed');
          }
          
          debugPrint('📏 ✅ Line height update complete');
        },
        loading: () {},
        error: (_, _) {},
      );
    });
    
    debugPrint('📏 ============================================\n');
  }

  void _updateShadows(PageElement element, List<Shadow> newShadows) async {
    debugPrint('🌑 ============================================');
    debugPrint('🌑 _updateShadows CALLED');
    debugPrint('🌑 Element ID: ${element.id}');
    debugPrint('🌑 Old shadows: ${element.shadows?.length ?? 0}');
    debugPrint('🌑 New shadows: ${newShadows.length}');
    debugPrint('🌑 ============================================');
    
    final updatedElement = PageElement(
      id: element.id,
      type: element.type,
      position: element.position,
      size: element.size,
      rotation: element.rotation,
      properties: element.properties,
      textStyle: element.textStyle,
      textAlign: element.textAlign,
      lineHeight: element.lineHeight,
      shadows: newShadows,
      locked: element.locked,
    );
    
    debugPrint('🌑 ✅ Updating local cache...');
    setState(() {
      _localElementCache[element.id] = updatedElement;
      
      // 🚀 NEW: Mark this element as actively being edited
      _activelyEditingElementId = element.id;
    });
    debugPrint('🌑 ✅ Local cache updated');
    debugPrint('🌑 ✅ Element marked as actively editing');
    
    // 🚀 NEW: Reset the "editing timeout" timer
    _editingTimeoutTimer?.cancel();
    _editingTimeoutTimer = Timer(const Duration(seconds: 2), () {
      debugPrint('🌑 ⏰ Editing timeout - user stopped editing');
      if (mounted) {
        setState(() {
          _activelyEditingElementId = null;
        });
      }
    });
    
    _propertyUpdateDebouncer?.cancel();
    debugPrint('🌑 ⏱️ Starting 500ms debounce timer...');
    
    _propertyUpdateDebouncer = Timer(const Duration(milliseconds: 500), () async {
      debugPrint('🌑 💾 Debounce fired - writing to database...');
      
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          final currentPage = pages[pageIndex];
          final pageActions = ref.read(pageActionsProvider);
          
          debugPrint('🌑 💾 Writing shadows to database...');
          final elementToSave = _localElementCache[element.id] ?? updatedElement;
          final success = await pageActions.updateElement(currentPage.id, elementToSave);
          
          if (success) {
            debugPrint('🌑 ✅ Database write successful!');
            debugPrint('🌑 🔄 Invalidating provider...');
            ref.invalidate(bookPagesProvider(bookId));
            
            debugPrint('🌑 ⏳ Waiting for provider rebuild...');
            await Future.delayed(const Duration(milliseconds: 600));
            
            final freshPages = await ref.read(bookPagesProvider(bookId).future);
            final freshElement = freshPages[pageIndex].elements.firstWhere(
              (e) => e.id == element.id,
              orElse: () => element,
            );
            
            debugPrint('🌑 🔍 Verification:');
            debugPrint('   Provider shadows count: ${freshElement.shadows?.length ?? 0}');
            debugPrint('   Cache shadows count: ${elementToSave.shadows?.length ?? 0}');
            
            // 🚀 CRITICAL FIX: Only clear cache if user is NOT actively editing
            if (_activelyEditingElementId != element.id) {
              final providerShadowCount = freshElement.shadows?.length ?? 0;
              final cacheShadowCount = elementToSave.shadows?.length ?? 0;
              
              if (providerShadowCount == cacheShadowCount) {
                // Also verify shadow properties if shadows exist
                bool shadowsMatch = true;
                if (cacheShadowCount > 0 && providerShadowCount > 0) {
                  final cacheShadow = elementToSave.shadows!.first;
                  final providerShadow = freshElement.shadows!.first;
                  
                  shadowsMatch = (cacheShadow.blurRadius - providerShadow.blurRadius).abs() < 0.1 &&
                                cacheShadow.color == providerShadow.color &&
                                cacheShadow.offset == providerShadow.offset;
                }
                
                if (shadowsMatch) {
                  debugPrint('🌑 ✅ Provider data matches cache - safe to clear');
                  if (mounted) {
                    setState(() {
                      _localElementCache.remove(element.id);
                    });
                  }
                  debugPrint('🌑 ✅ Cache cleared');
                } else {
                  debugPrint('🌑 ⚠️ Shadow properties MISMATCH - keeping cache');
                }
              } else {
                debugPrint('🌑 ⚠️ Provider data MISMATCH - keeping cache');
              }
            } else {
              debugPrint('🌑 🚫 User still actively editing - KEEPING cache');
            }
          } else {
            debugPrint('🌑 ❌ Database write failed');
          }
          
          debugPrint('🌑 ✅ Shadows update complete');
        },
        loading: () {},
        error: (_, _) {},
      );
    });
    
    debugPrint('🌑 ============================================\n');
  }


  void _clearResizeStateOptimized(String elementId) async {
    debugPrint('🧹 === OPTIMIZED RESIZE STATE CLEAR ===');
    debugPrint('Element: $elementId');
    
    final finalSize = _elementSizes[elementId];
    final finalPosition = _elementOffsets[elementId];
    
    // 🚀 Store the final values before clearing state
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) {
      debugPrint('❌ No bookId found');
      return;
    }

    // 🚀 Clear UI state immediately for instant visual feedback
    setState(() {
      _currentlyResizingId = null;
      _resizeStartMousePosition = null;
      _resizeStartElementSize = null;
      _resizeStartElementPosition = null;
    });

    if (finalSize == null && finalPosition == null) {
      debugPrint('⚠️ No changes detected');
      return;
    }

    final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
    await pagesAsync.when(
      data: (pages) async {
        final pageIndex = ref.read(currentPageIndexProvider);
        if (pages.isEmpty || pageIndex >= pages.length) return;
        
        final currentPage = pages[pageIndex];
        final element = currentPage.elements.firstWhere(
          (e) => e.id == elementId,
          orElse: () => currentPage.elements.first,
        );
        
        final sizeChanged = finalSize != null && 
            ((finalSize.width - element.size.width).abs() > 1.0 || 
            (finalSize.height - element.size.height).abs() > 1.0);
        
        final positionChanged = finalPosition != null && 
            (finalPosition - element.position).distance > 1.0;
        
        if (sizeChanged || positionChanged) {
          _undoRedoManager.saveState(currentPage.elements, currentPage.background);
          
          // 🚀 CRITICAL FIX: Update database FIRST before clearing local state
          debugPrint('💾 Writing resize changes to database...');
          if (finalSize != null && finalPosition != null) {
            await _updateElementPositionAndSize(elementId, finalPosition, finalSize);
          } else if (finalSize != null) {
            await _updateElementSize(elementId, finalSize);
          } else if (finalPosition != null) {
            await _updateElementPosition(elementId, finalPosition);
          }
          
          // 🚀 Wait a bit for the database write to complete
          await Future.delayed(const Duration(milliseconds: 300));
          
          // 🚀 Force refresh the provider to get updated data
          ref.invalidate(bookPagesProvider(bookId));
          
          // 🚀 Wait for provider to update
          await Future.delayed(const Duration(milliseconds: 200));
          
          // 🚀 Verify the update was successful before clearing local state
          final updatedPages = ref.read(bookPagesProvider(bookId));
          updatedPages.when(
            data: (pages) {
              if (pages.isEmpty || pageIndex >= pages.length) return;
              final updatedPage = pages[pageIndex];
              final updatedElement = updatedPage.elements.firstWhere(
                (e) => e.id == elementId,
                orElse: () => updatedPage.elements.first,
              );
              
              // Only clear local state if database has the new values
              if (finalSize != null && updatedElement.size == finalSize) {
                setState(() => _elementSizes.remove(elementId));
              }
              if (finalPosition != null && updatedElement.position == finalPosition) {
                setState(() => _elementOffsets.remove(elementId));
              }
              
              debugPrint('✅ Resize complete and verified');
            },
            loading: () {},
            error: (error, stack) {},
          );
        } else {
          // No significant changes, clear immediately
          setState(() {
            _elementOffsets.remove(elementId);
            _elementSizes.remove(elementId);
          });
        }
      },
      loading: () {},
      error: (_, _) {},
    );
  }

  void _handleResizeEnd(String elementId, PageElement element) {
    debugPrint('🧹 === RESIZE END ===');
    debugPrint('Element: $elementId');
    
    final finalSize = _elementSizes[elementId];
    final finalPosition = _elementOffsets[elementId];
    final originalSize = element.size;
    final originalPosition = element.position;
    
    // ✅ STEP 1: Clear resize state IMMEDIATELY for instant UI response
    setState(() {
      _currentlyResizingId = null;
      _resizeStartMousePosition = null;
      _resizeStartElementSize = null;
      _resizeStartElementPosition = null;
    });
    
    // ✅ STEP 2: Check if anything actually changed
    final sizeChanged = finalSize != null && 
        ((finalSize.width - originalSize.width).abs() > 1.0 || 
        (finalSize.height - originalSize.height).abs() > 1.0);
    
    final positionChanged = finalPosition != null && 
        (finalPosition - originalPosition).distance > 1.0;
    
    if (!sizeChanged && !positionChanged) {
      debugPrint('⚠️ No significant changes detected');
      _elementSizes.remove(elementId);
      _elementOffsets.remove(elementId);
      if (mounted) setState(() {});
      return;
    }

    debugPrint('💾 Resize end - saving changes (size: $sizeChanged, position: $positionChanged)');

    // ✅ STEP 3: Write to database in background (non-blocking)
    _saveElementResizeToDatabase(
      elementId: elementId,
      element: element,
      finalSize: finalSize ?? originalSize,
      finalPosition: finalPosition ?? originalPosition,
    );
  }

  /// Save element resize to database in background
  void _saveElementResizeToDatabase({
    required String elementId,
    required PageElement element,
    required Size finalSize,
    required Offset finalPosition,
  }) async {
    try {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) {
        debugPrint('❌ No bookId for background resize save');
        _elementSizes.remove(elementId);
        _elementOffsets.remove(elementId);
        return;
      }

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      await pagesAsync.when(
        data: (pages) async {
          final pageIndex = ref.read(currentPageIndexProvider);
          if (pages.isEmpty || pageIndex >= pages.length) {
            debugPrint('❌ Invalid page for background resize save');
            _elementSizes.remove(elementId);
            _elementOffsets.remove(elementId);
            return;
          }

          final currentPage = pages[pageIndex];
          
          // Save to undo manager
          _undoRedoManager.saveState(currentPage.elements, currentPage.background);

          // Create updated element
          final updatedElement = PageElement(
            id: element.id,
            type: element.type,
            position: finalPosition,
            size: finalSize,
            rotation: element.rotation,
            properties: element.properties,
            textStyle: element.textStyle,
            textAlign: element.textAlign,
            lineHeight: element.lineHeight,
            shadows: element.shadows,
            locked: element.locked,
          );

          // Write to database
          final pageActions = ref.read(pageActionsProvider);
          final success = await pageActions.updateElement(currentPage.id, updatedElement);

          if (success) {
            debugPrint('✅ Background resize write successful');
            
            // Invalidate provider
            ref.invalidate(bookPagesProvider(bookId));
            
            // Wait for provider to refresh
            await Future.delayed(const Duration(milliseconds: 300));
            
            // Verify and clear cache
            final freshPages = await ref.read(bookPagesProvider(bookId).future);
            if (freshPages.isEmpty || pageIndex >= freshPages.length) {
              debugPrint('⚠️ Fresh pages invalid - keeping cache');
              return;
            }
            
            final freshElement = freshPages[pageIndex].elements.firstWhere(
              (e) => e.id == elementId,
              orElse: () => element,
            );
            
            final sizeMatches = (freshElement.size.width - finalSize.width).abs() < 2.0 &&
                                (freshElement.size.height - finalSize.height).abs() < 2.0;
            final positionMatches = (freshElement.position - finalPosition).distance < 2.0;
            
            if (sizeMatches && positionMatches) {
              debugPrint('✅ Provider confirmed resize - clearing cache');
              if (mounted) {
                setState(() {
                  _elementSizes.remove(elementId);
                  _elementOffsets.remove(elementId);
                });
              }
            } else {
              debugPrint('⚠️ Provider data mismatch - keeping cache');
              debugPrint('   Provider size: ${freshElement.size} vs $finalSize');
              debugPrint('   Provider pos: ${freshElement.position} vs $finalPosition');
              
              // Retry after delay
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                setState(() {
                  _elementSizes.remove(elementId);
                  _elementOffsets.remove(elementId);
                });
                debugPrint('🧹 Cache cleared after retry delay');
              }
            }
          } else {
            debugPrint('❌ Background resize write failed');
            _elementSizes.remove(elementId);
            _elementOffsets.remove(elementId);
          }
        },
        loading: () {
          debugPrint('⏳ Pages loading during resize save');
          _elementSizes.remove(elementId);
          _elementOffsets.remove(elementId);
        },
        error: (error, stack) {
          debugPrint('❌ Error during resize save: $error');
          _elementSizes.remove(elementId);
          _elementOffsets.remove(elementId);
        },
      );
    } catch (e) {
      debugPrint('❌ Exception in resize save: $e');
      if (mounted) {
        setState(() {
          _elementSizes.remove(elementId);
          _elementOffsets.remove(elementId);
        });
      }
    }
  }

  void _handleRotationEnd(String elementId, PageElement element) {
    debugPrint('🔄 === ROTATION END ===');
    debugPrint('Element: $elementId');
    
    final finalRotation = _elementRotations[elementId] ?? element.rotation;
    final originalRotation = element.rotation;
    
    // ✅ STEP 1: Clear rotation state IMMEDIATELY
    setState(() {
      _currentlyRotatingId = null;
    });
    
    // ✅ STEP 2: Check if rotation actually changed
    final rotationChanged = (finalRotation - originalRotation).abs() > 0.01; // ~0.5 degrees
    
    if (!rotationChanged) {
      debugPrint('⚠️ No significant rotation change');
      _elementRotations.remove(elementId);
      if (mounted) setState(() {});
      return;
    }

    final rotationDegrees = (finalRotation * 180 / math.pi).toStringAsFixed(1);
    debugPrint('💾 Rotation end - saving $rotationDegrees° rotation');

    // ✅ STEP 3: Write to database in background (non-blocking)
    _saveElementRotationToDatabase(
      elementId: elementId,
      element: element,
      finalRotation: finalRotation,
    );
  }

  /// Save element rotation to database in background
  void _saveElementRotationToDatabase({
    required String elementId,
    required PageElement element,
    required double finalRotation,
  }) async {
    try {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) {
        debugPrint('❌ No bookId for background rotation save');
        _elementRotations.remove(elementId);
        return;
      }

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      await pagesAsync.when(
        data: (pages) async {
          final pageIndex = ref.read(currentPageIndexProvider);
          if (pages.isEmpty || pageIndex >= pages.length) {
            debugPrint('❌ Invalid page for background rotation save');
            _elementRotations.remove(elementId);
            return;
          }

          final currentPage = pages[pageIndex];
          
          // Save to undo manager
          _undoRedoManager.saveState(currentPage.elements, currentPage.background);

          // Create updated element
          final updatedElement = PageElement(
            id: element.id,
            type: element.type,
            position: element.position,
            size: element.size,
            rotation: finalRotation,
            properties: element.properties,
            textStyle: element.textStyle,
            textAlign: element.textAlign,
            lineHeight: element.lineHeight,
            shadows: element.shadows,
            locked: element.locked,
          );

          // Write to database
          final pageActions = ref.read(pageActionsProvider);
          final success = await pageActions.updateElement(currentPage.id, updatedElement);

          if (success) {
            debugPrint('✅ Background rotation write successful');
            
            // Invalidate provider
            ref.invalidate(bookPagesProvider(bookId));
            
            // Wait for provider to refresh
            await Future.delayed(const Duration(milliseconds: 300));
            
            // Verify and clear cache
            final freshPages = await ref.read(bookPagesProvider(bookId).future);
            if (freshPages.isEmpty || pageIndex >= freshPages.length) {
              debugPrint('⚠️ Fresh pages invalid - keeping cache');
              return;
            }
            
            final freshElement = freshPages[pageIndex].elements.firstWhere(
              (e) => e.id == elementId,
              orElse: () => element,
            );
            
            final rotationMatches = (freshElement.rotation - finalRotation).abs() < 0.01;
            
            if (rotationMatches) {
              debugPrint('✅ Provider confirmed rotation - clearing cache');
              if (mounted) {
                setState(() {
                  _elementRotations.remove(elementId);
                });
              }
            } else {
              debugPrint('⚠️ Provider rotation mismatch - keeping cache');
              debugPrint('   Provider: ${freshElement.rotation} vs $finalRotation');
              
              // Retry after delay
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                setState(() {
                  _elementRotations.remove(elementId);
                });
                debugPrint('🧹 Rotation cache cleared after retry delay');
              }
            }
          } else {
            debugPrint('❌ Background rotation write failed');
            _elementRotations.remove(elementId);
          }
        },
        loading: () {
          debugPrint('⏳ Pages loading during rotation save');
          _elementRotations.remove(elementId);
        },
        error: (error, stack) {
          debugPrint('❌ Error during rotation save: $error');
          _elementRotations.remove(elementId);
        },
      );
    } catch (e) {
      debugPrint('❌ Exception in rotation save: $e');
      if (mounted) {
        setState(() {
          _elementRotations.remove(elementId);
        });
      }
    }
  }

  void _handleElementTap(String elementId) {
    debugPrint('🔵 ELEMENT TAPPED: $elementId');
    setState(() {
      _selectedElementId = _selectedElementId == elementId ? null : elementId;
    });
  }

    void _handleKeyPress(KeyEvent event) {
    // Only handle key down events
    if (event is! KeyDownEvent) return;

    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final key = event.logicalKey;

    // Ctrl+C - Copy (placeholder)
    if (isControlPressed && key == LogicalKeyboardKey.keyC && _selectedElementId != null) {
      _showSnackBar('Copy - Coming Soon');
      return;
    }

    // Ctrl+V - Paste (placeholder)
    if (isControlPressed && key == LogicalKeyboardKey.keyV) {
      _showSnackBar('Paste - Coming Soon');
      return;
    }

    // Ctrl+D - Duplicate
    if (isControlPressed && key == LogicalKeyboardKey.keyD && _selectedElementId != null) {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      pagesAsync.whenData((pages) async {
        if (pages.isEmpty || pageIndex >= pages.length) return;
        final currentPage = pages[pageIndex];
        
        final element = currentPage.elements.firstWhere(
          (e) => e.id == _selectedElementId,
          orElse: () => currentPage.elements.first,
        );

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

        final pageActions = ref.read(pageActionsProvider);
        await pageActions.addElement(currentPage.id, newElement);
        setState(() => _selectedElementId = newElement.id);
        _showSnackBar('Element duplicated');
      });
      return;
    }

    // Delete - Delete element
    if (key == LogicalKeyboardKey.delete && _selectedElementId != null) {
      _deleteElement(_selectedElementId!);
      return;
    }

    // Ctrl+L - Lock/Unlock
    if (isControlPressed && key == LogicalKeyboardKey.keyL && _selectedElementId != null) {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      pagesAsync.whenData((pages) async {
        if (pages.isEmpty || pageIndex >= pages.length) return;
        final currentPage = pages[pageIndex];
        final pageActions = ref.read(pageActionsProvider);
        await pageActions.toggleElementLock(currentPage.id, _selectedElementId!);
        
        final element = currentPage.elements.firstWhere((e) => e.id == _selectedElementId);
        _showSnackBar(element.locked ? 'Element unlocked' : 'Element locked');
      });
      return;
    }

    // Ctrl+] - Bring to Front
    if (isControlPressed && key == LogicalKeyboardKey.bracketRight && _selectedElementId != null) {
      _handleContextMenuAction('bring_to_front', 
        ref.read(bookPagesProvider(widget.bookId!)).value![ref.read(currentPageIndexProvider)].elements
          .firstWhere((e) => e.id == _selectedElementId), 
        ref.read(bookPagesProvider(widget.bookId!)).value![ref.read(currentPageIndexProvider)].id
      );
      return;
    }

    // ] - Bring Forward
    if (!isControlPressed && key == LogicalKeyboardKey.bracketRight && _selectedElementId != null) {
      _handleContextMenuAction('bring_forward', 
        ref.read(bookPagesProvider(widget.bookId!)).value![ref.read(currentPageIndexProvider)].elements
          .firstWhere((e) => e.id == _selectedElementId), 
        ref.read(bookPagesProvider(widget.bookId!)).value![ref.read(currentPageIndexProvider)].id
      );
      return;
    }

    // Ctrl+[ - Send to Back
    if (isControlPressed && key == LogicalKeyboardKey.bracketLeft && _selectedElementId != null) {
      _handleContextMenuAction('send_to_back', 
        ref.read(bookPagesProvider(widget.bookId!)).value![ref.read(currentPageIndexProvider)].elements
          .firstWhere((e) => e.id == _selectedElementId), 
        ref.read(bookPagesProvider(widget.bookId!)).value![ref.read(currentPageIndexProvider)].id
      );
      return;
    }

    // [ - Send Backward
    if (!isControlPressed && key == LogicalKeyboardKey.bracketLeft && _selectedElementId != null) {
      _handleContextMenuAction('send_backward', 
        ref.read(bookPagesProvider(widget.bookId!)).value![ref.read(currentPageIndexProvider)].elements
          .firstWhere((e) => e.id == _selectedElementId), 
        ref.read(bookPagesProvider(widget.bookId!)).value![ref.read(currentPageIndexProvider)].id
      );
      return;
    }

    // Ctrl+Z - Undo
    if (isControlPressed && key == LogicalKeyboardKey.keyZ && !isShiftPressed) {
      if (_undoRedoManager.canUndo) _undo();
      return;
    }

    // Ctrl+Shift+Z or Ctrl+Y - Redo
    if ((isControlPressed && isShiftPressed && key == LogicalKeyboardKey.keyZ) ||
        (isControlPressed && key == LogicalKeyboardKey.keyY)) {
      if (_undoRedoManager.canRedo) _redo();
      return;
    }

    // Enter - Edit text element
    if (key == LogicalKeyboardKey.enter && _selectedElementId != null) {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) return;

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      final pageIndex = ref.read(currentPageIndexProvider);

      pagesAsync.whenData((pages) {
        if (pages.isEmpty || pageIndex >= pages.length) return;
        final currentPage = pages[pageIndex];
        
        final element = currentPage.elements.firstWhere(
          (e) => e.id == _selectedElementId,
          orElse: () => currentPage.elements.first,
        );

        if (element.type == ElementType.text && !element.locked) {
          _editTextElement(element);
        }
      });
      return;
    }
  }

  void _editTextElement(PageElement element) {
    debugPrint('🎯 === EDIT TEXT ELEMENT CALLED ===');
    debugPrint('🎯 Element ID: ${element.id}');
    debugPrint('🎯 Element Type: ${element.type}');
    debugPrint('🎯 Current Text: ${element.properties['text']}');
    debugPrint('🎯 Is Locked: ${element.locked}');
    
    showDialog(
      context: context,
      builder: (context) => AdvancedTextEditorDialog(
        element: element,
        onSave: (String newText, bool isList) async {
          debugPrint('💾 === ADVANCED TEXT EDITOR ON SAVE ===');
          debugPrint('💾 New Text: $newText');
          debugPrint('💾 Is List: $isList');
          debugPrint('💾 Original Text: ${element.properties['text']}');

          final bookId = ref.read(currentBookIdProvider);
          if (bookId == null) {
            debugPrint('❌ No book ID found in onSave!');
            return;
          }

          final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
          final pageIndex = ref.read(currentPageIndexProvider);

          await pagesAsync.when(
            data: (pages) async {
              debugPrint('📄 === PAGES DATA LOADED FOR SAVE ===');
              debugPrint('📄 Total pages: ${pages.length}');
              debugPrint('📄 Current page index: $pageIndex');

              if (pages.isEmpty || pageIndex >= pages.length) {
                debugPrint('❌ Invalid page index or empty pages!');
                return;
              }

              final currentPage = pages[pageIndex];
              debugPrint('📄 Current Page ID: ${currentPage.id}');
                
              _undoRedoManager.saveState(currentPage.elements, currentPage.background);
              debugPrint('✅ Undo state saved');
                
              final updatedProperties = Map<String, dynamic>.from(element.properties);
              updatedProperties['text'] = newText;
              updatedProperties['isList'] = isList;
              
              debugPrint('🔄 Creating updated element...');
              final updatedElement = PageElement(
                id: element.id,
                type: element.type,
                position: element.position,
                size: element.size,
                rotation: element.rotation,
                properties: updatedProperties,
                textStyle: element.textStyle,
                textAlign: element.textAlign,
                lineHeight: element.lineHeight,
                shadows: element.shadows,
                locked: element.locked,
              );

              debugPrint('🔄 Updated element properties: ${updatedElement.properties}');

              // 🚀 CRITICAL FIX: Update local cache for instant UI feedback
              debugPrint('🎯 Updating local cache for instant UI update...');
              setState(() {
                _localElementCache[element.id] = updatedElement;
                _activelyEditingElementId = element.id;
              });

              final pageActions = ref.read(pageActionsProvider);
              debugPrint('💾 Writing to database...');
              final success = await pageActions.updateElement(currentPage.id, updatedElement);
              
              if (success) {
                debugPrint('✅ Database write successful!');
                debugPrint('🔄 Invalidating provider to refresh data...');
                ref.invalidate(bookPagesProvider(bookId));
                
                // Wait for provider to update
                await Future.delayed(const Duration(milliseconds: 300));
                
                // Verify the update
                final freshPages = await ref.read(bookPagesProvider(bookId).future);
                final freshElement = freshPages[pageIndex].elements.firstWhere(
                  (e) => e.id == element.id,
                  orElse: () => element,
                );
                
                debugPrint('🔍 Verification:');
                debugPrint('   Provider text: ${freshElement.properties['text']}');
                debugPrint('   Cache text: ${updatedElement.properties['text']}');
                
                // Only clear cache if user is not actively editing
                if (_activelyEditingElementId != element.id) {
                  if (freshElement.properties['text'] == updatedElement.properties['text']) {
                    debugPrint('✅ Provider data matches cache - safe to clear');
                    if (mounted) {
                      setState(() {
                        _localElementCache.remove(element.id);
                      });
                    }
                  } else {
                    debugPrint('⚠️ Provider data MISMATCH - keeping cache');
                  }
                } else {
                  debugPrint('🚫 User still actively editing - KEEPING cache');
                }
              } else {
                debugPrint('❌ Database write failed!');
              }
            },
            loading: () {
              debugPrint('⏳ Pages loading...');
            },
            error: (error, stack) {
              debugPrint('❌ Error in text save: $error');
            },
          );
        },
      ),
    );
  }



    void _showSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    Alignment _getAlignment(TextAlign textAlign) {
      switch (textAlign) {
        case TextAlign.left:
          return Alignment.centerLeft;
        case TextAlign.center:
          return Alignment.center;
        case TextAlign.right:
          return Alignment.centerRight;
        case TextAlign.justify:
          return Alignment.centerLeft;
        default:
          return Alignment.centerLeft;
      }
    }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    final bookId = ref.watch(currentBookIdProvider);
    if (bookId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Failed to create book'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final backgroundColor = _isDarkMode ? AppTheme.nearlyBlack : AppTheme.nearlyWhite;
    final appBarColor = _isDarkMode ? AppTheme.dark_grey : AppTheme.white;
    final textColor = _isDarkMode ? AppTheme.white : AppTheme.darkerText;

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(appBarColor, textColor, bookId),
        body: Column(
          children: [
            EditorToolbar(
              appBarColor: appBarColor,
              textColor: textColor,
              bookId: bookId,
              onAddText: _addTextElement,
              onAddImage: _addImageElement,
              onAddShape: _addShapeElement,
              onAddAudio: _addAudioElement,
              onAddVideo: _addVideoElement,
              onDelete: _selectedElementId != null ? () => _deleteElement(_selectedElementId!) : null,
              onUndo: _undoRedoManager.canUndo ? _undo : null,
              onRedo: _undoRedoManager.canRedo ? _redo : null,
              hasSelectedElement: _selectedElementId != null,
              canUndo: _undoRedoManager.canUndo,
              canRedo: _undoRedoManager.canRedo,
              onToggleGrid: () => setState(() => _gridEnabled = !_gridEnabled),
              gridEnabled: _gridEnabled,
              onBackgroundSettings: _showBackgroundSettings,
            ),
            Expanded(
              child: Row(
                children: [
                  PagesPanel(
                    panelColor: appBarColor,
                    textColor: textColor,
                    bookId: bookId,
                  ),
                  Expanded(
                    child: _buildEditorArea(bookId),
                  ),
                  RepaintBoundary(
          child: PropertiesPanel(
            bookId: bookId,
            selectedElementId: _selectedElementId,
            panelColor: appBarColor,
            textColor: textColor,
            localElementCache: _localElementCache,
            onUpdateTextStyle: _updateTextStyle,
            onUpdateTextAlign: _updateTextAlign,
            onUpdateLineHeight: _updateLineHeight,
            onUpdateShadows: _updateShadows,
            onEditText: _editTextElement,
            onElementSelected: (id) => setState(() => _selectedElementId = id),
            onLayerOrderChanged: (newOrder) {
              _showSnackBar('Layer order updated');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color appBarColor, Color textColor, String bookId) {
    final bookAsync = ref.watch(bookProvider(bookId));

    return AppBar(
      backgroundColor: appBarColor,
      foregroundColor: textColor,
      elevation: 2,
      // ✅ UPDATED TITLE WITH CANVAS SIZE INFO
      title: bookAsync.when(
        data: (book) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              book?.title ?? 'Untitled',
              style: AppTheme.headline.copyWith(color: textColor, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
            if (book?.pageSize != null)
              Text(
                '${book!.pageSize.width.toInt()}×${book.pageSize.height.toInt()}px • ${book.pageSize.orientation}',
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        loading: () => const Text('Loading...', style: TextStyle(fontSize: 18)),
        error: (_, _) => const Text('Error', style: TextStyle(fontSize: 18)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _saveCurrentPage();
              _showSnackBar('Book saved!');
            },
            tooltip: 'Save',
          ),
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: () => _handlePreview(),
            tooltip: 'Preview Book',
          ),
        IconButton(
          icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          tooltip: 'Toggle Theme',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'export':
                _showSnackBar('Export - Coming Soon');
                break;
              case 'settings':
                _showBookSettings(bookId);
                break;
              case 'grid_settings':
                _showGridSettings();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'export', child: Text('Export as PDF')),
            const PopupMenuItem(value: 'settings', child: Text('Book Settings')),
            const PopupMenuItem(value: 'grid_settings', child: Text('Grid Settings')),
          ],
        ),
      ],
    );
  }

    void _showGridSettings() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Grid Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Enable Grid'),
                value: _gridEnabled,
                onChanged: (value) {
                  setState(() => _gridEnabled = value);
                  Navigator.pop(context);
                },
              ),
              SwitchListTile(
                title: const Text('Snap to Grid'),
                value: _snapToGrid,
                onChanged: (value) {
                  setState(() => _snapToGrid = value);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Text('Grid Size: ${_gridSize.round()}px'),
              Slider(
                value: _gridSize,
                min: 10,
                max: 50,
                divisions: 8,
                label: _gridSize.round().toString(),
                onChanged: (value) {
                  setState(() => _gridSize = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }


Widget _buildEditorArea(String bookId) {
  final pagesAsync = ref.watch(bookPagesProvider(widget.bookId!));
  final pageIndex = ref.watch(currentPageIndexProvider);

  // 🚀 NEW: Set up listener for canvas (same as pages panel)
  ref.listen<AsyncValue<List<BookPage>>>(
    bookPagesProvider(widget.bookId!),
    (previous, next) {
      next.whenData((newPages) {
        if (!mounted) return;
        
        // Only update local state if not during user interaction
        if (!isUserInteracting) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _localCanvasPageOrder = List<BookPage>.from(newPages);
              });
            }
          });
        }
      });
    },
  );

  // 🚀 NEW: Initialize local state from provider (first load only)
  pagesAsync.whenData((providerPages) {
    if (_localCanvasPageOrder == null && providerPages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _localCanvasPageOrder == null) {
          setState(() {
            _localCanvasPageOrder = List<BookPage>.from(providerPages);
          });
        }
      });
    }
  });

  return pagesAsync.when(
    data: (pages) {
      // 🚀 USE LOCAL STATE if available, otherwise use provider
      final displayPages = _localCanvasPageOrder ?? pages;
      
      debugPrint('🔄 _buildEditorArea REBUILT with ${displayPages.length} pages');
      if (displayPages.isEmpty || pageIndex >= displayPages.length) {
        return const Center(child: Text('No page available'));
      }

      final currentPage = displayPages[pageIndex]; 
        if (pages.isEmpty || pageIndex >= pages.length) {
          return const Center(child: Text('No page available'));
        }
        
        // ✅ Get actual canvas dimensions
        final canvasWidth = currentPage.pageSize?.width ?? 800;
        final canvasHeight = currentPage.pageSize?.height ?? 600;

        // ✅ CENTER CANVAS ON BUILD
        _centerCanvas(canvasWidth, canvasHeight);

        return Stack(
          children: [
            // ✅ MAIN SCROLLABLE CANVAS AREA - WITH CONTROLLERS
            Container(
              color: _isDarkMode ? AppTheme.nearlyBlack : AppTheme.nearlyWhite,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                scrollDirection: Axis.vertical,
                child: Center(  // ✅ ADDED CENTER FOR VERTICAL
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Center(  // ✅ ADDED CENTER FOR HORIZONTAL
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Transform.scale(
                          scale: _zoomLevel,
                          alignment: Alignment.center,  // ✅ CHANGED FROM topLeft TO center
                          child: Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) {
      debugPrint('🎯 Canvas Listener - onPointerDown');
      debugPrint('   Local Position: ${event.localPosition}');
      debugPrint('   Selected element: $_selectedElementId');
      
      if (event.buttons == kSecondaryButton) {
        return;
      }
      
      if (event.buttons == kPrimaryButton) {
        // ✅ CRITICAL FIX: Account for zoom level when calculating positions
        // The event.localPosition is in the scaled (zoomed) coordinate space
        // We need to convert it to canvas coordinate space
        final scaledClickX = event.localPosition.dx;
        final scaledClickY = event.localPosition.dy;
        
        // Convert to canvas coordinates (divide by zoom)
        final canvasClickX = scaledClickX / _zoomLevel;
        final canvasClickY = scaledClickY / _zoomLevel;
        
        debugPrint('   Canvas Position (zoom-adjusted): ($canvasClickX, $canvasClickY)');
        
        if (_selectedElementId != null) {
          final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
          final pageIndex = ref.read(currentPageIndexProvider);
          
          pagesAsync.whenData((pages) {
            if (pages.isEmpty || pageIndex >= pages.length) return;
            
            final currentPage = pages[pageIndex];
            final selectedElement = currentPage.elements.firstWhere(
              (e) => e.id == _selectedElementId,
              orElse: () => currentPage.elements.first,
            );
            
            // Calculate rotation handle position in canvas coordinates
            final elementPos = _elementOffsets[selectedElement.id] ?? selectedElement.position;
            final elementSize = _elementSizes[selectedElement.id] ?? selectedElement.size;
            
            final handleCenterX = elementPos.dx + elementSize.width / 2;
            final handleCenterY = elementPos.dy - 50;
            
            debugPrint('   Handle position: ($handleCenterX, $handleCenterY)');
            
            final distanceToHandle = math.sqrt(
              math.pow(canvasClickX - handleCenterX, 2) + 
              math.pow(canvasClickY - handleCenterY, 2)
            );
            
            debugPrint('   Distance to rotation handle: ${distanceToHandle.toStringAsFixed(1)}px');
            
            // If click is within 40px of rotation handle, don't deselect
            if (distanceToHandle < 40) {
              debugPrint('   🚫 Click is near rotation handle - NOT deselecting');
              return;
            }
            
            debugPrint('   ✅ Click is on canvas - deselecting element');
            setState(() => _selectedElementId = null);
          });
        } else {
          setState(() => _selectedElementId = null);
        }
      }
    },
                            child: Container(
                              width: canvasWidth,
                              height: canvasHeight,
                              decoration: BoxDecoration(
                                color: currentPage.background.color,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    if (currentPage.background.imageUrl != null)
                                      Positioned.fill(
                                        child: Image.network(
                                          currentPage.background.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                        ),
                                      ),
                                    
                                    if (_gridEnabled) _buildGridOverlay(),
                                    
                                    ...currentPage.elements.map((element) {
                                      return _buildDraggableElement(element, currentPage.id);
                                    }),
                                    
                                    if (currentPage.elements.isEmpty) _buildEmptyState(),
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
            ),
            
            // ✅ ZOOM CONTROLS OVERLAY (Bottom Right)
            Positioned(
              bottom: 20,
              right: 20,
              child: _buildZoomControls(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom Out Button
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: _zoomLevel > _minZoom ? _zoomOut : null,
            tooltip: 'Zoom Out (10%)',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(
              backgroundColor: _zoomLevel > _minZoom 
                  ? Colors.grey.shade100 
                  : Colors.grey.shade200,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Slider with draggable circle
          SizedBox(
            width: 180,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: Colors.blue,
                overlayColor: Colors.blue.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _zoomLevel,
                min: _minZoom,
                max: _maxZoom,
                onChanged: (value) {
                  setState(() {
                    _zoomLevel = value;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Zoom In Button
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: _zoomLevel < _maxZoom ? _zoomIn : null,
            tooltip: 'Zoom In (10%)',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(
              backgroundColor: _zoomLevel < _maxZoom 
                  ? Colors.grey.shade100 
                  : Colors.grey.shade200,
            ),
          ),
          
          const SizedBox(width: 8),
          const VerticalDivider(width: 1, thickness: 1),
          const SizedBox(width: 8),
          
          // Zoom Percentage Dropdown
          PopupMenuButton<double>(
            onSelected: _setZoom,
            tooltip: 'Zoom presets',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getZoomPercentage(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
            itemBuilder: (context) => [
              ..._zoomPresets.map((zoom) => PopupMenuItem(
                value: zoom,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(zoom * 100).round()}%'),
                    if (zoom == _zoomLevel)
                      const Icon(Icons.check, size: 16, color: Colors.blue),
                  ],
                ),
              )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 0.5,
                child: Row(
                  children: [
                    Icon(Icons.fit_screen, size: 16),
                    SizedBox(width: 8),
                    Text('Fit to Window (50%)'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 1.0,
                child: Row(
                  children: [
                    Icon(Icons.aspect_ratio, size: 16),
                    SizedBox(width: 8),
                    Text('Actual Size (100%)'),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 8),
          const VerticalDivider(width: 1, thickness: 1),
          const SizedBox(width: 8),
          
          // Reset Zoom Button
          IconButton(
            icon: const Icon(Icons.restart_alt, size: 18),
            onPressed: _zoomLevel != 0.5 ? _resetZoom : null,
            tooltip: 'Reset Zoom (50%)',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(
              backgroundColor: _zoomLevel != 0.5 
                  ? Colors.blue.shade50 
                  : Colors.grey.shade200,
              foregroundColor: _zoomLevel != 0.5 
                  ? Colors.blue 
                  : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildGridOverlay() {
      return CustomPaint(
        painter: GridPainter(
          gridSize: _gridSize,
          gridColor: Colors.grey.withValues(alpha: 0.3),
        ),
        child: const SizedBox.expand(),
      );
    }

  Widget _buildDraggableElement(PageElement element, String pageId) {
    final isSelected = _selectedElementId == element.id;
    final isDragging = _currentlyDraggingId == element.id;
    final isResizing = _currentlyResizingId == element.id;
    final isRotating = _currentlyRotatingId == element.id;


    
    // 🚀 ENHANCED: Use cache with fallback to element data
    // During interaction, prefer cache. After interaction, use provider data.
    final currentSize = _elementSizes[element.id] ?? element.size;
    final currentRotation = _elementRotations[element.id] ?? element.rotation;

    final isInteractiveElement = element.type == ElementType.video || 
                                  element.type == ElementType.audio;

    // 🚀 OPTIMIZED: Wrap with ValueListenableBuilder for smooth dragging without rebuilds
  return ValueListenableBuilder<Offset>(
    valueListenable: _dragPositionNotifiers[element.id] ?? ValueNotifier(element.position),
    builder: (context, dragPosition, child) {
      // ✅ Priority order for position:
      // 1. If actively dragging: use ValueNotifier position (smooth, no rebuilds)
      // 2. If cache exists: use cached position (waiting for database confirmation)
      // 3. Fallback: use provider position (database confirmed)
      final displayPosition = isDragging 
          ? dragPosition 
          : (_elementOffsets[element.id] ?? element.position);
        
      return Positioned(
        left: displayPosition.dx,
        top: displayPosition.dy,
        child: Transform.rotate(
          angle: currentRotation,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ========== INNER STACK: Main content + resize handles ==========
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // ========== MAIN DRAGGABLE CONTENT ==========
                  MouseRegion(
                    cursor: element.locked 
                        ? SystemMouseCursors.forbidden 
                        : (isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab),
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (event) {
                        if (event.buttons == kSecondaryButton) {
                          // Right-click handled by GestureDetector
                        }
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: (isResizing || isRotating || _currentlyRotatingId != null) 
                            ? null 
                            : () {
                                if (isInteractiveElement) {
                                  _selectedElementId = element.id;
                                  if (mounted) setState(() {});
                                } else {
                                  _handleElementTap(element.id);
                                }
                              },
                        onSecondaryTapDown: isResizing || isRotating ? null : (details) {
                          _showElementContextMenu(context, details.globalPosition, element, pageId);
                        },
                        onDoubleTap: isResizing || isRotating ? null : () {
                          if (element.type == ElementType.text) {
                            if (element.locked) {
                              _showSnackBar('Element is locked. Unlock it to edit.');
                              return;
                            }
                            _editTextElement(element);
                          }
                        },
                        
                        onPanStart: isResizing || isRotating || element.locked ? null : (details) {
                          // ✅ Block drag if rotation is active
                          if (_currentlyRotatingId != null) {
                            debugPrint('⏸️ Drag blocked - rotation in progress');
                            return;
                          }
                          
                          if (element.locked) {
                            _showSnackBar('Element is locked. Unlock it to move.');
                            return;
                          }

                          // ✅ Check if click is in rotation handle area (top center, 50px above element)
                          final currentSize = _elementSizes[element.id] ?? element.size;
                          final handleCenterX = currentSize.width / 2;
                          final handleCenterY = -50;
                          final clickX = details.localPosition.dx;
                          final clickY = details.localPosition.dy;
                          
                          // If click is within 30px of rotation handle center, ignore drag
                          final distanceToHandle = math.sqrt(
                            math.pow(clickX - handleCenterX, 2) + math.pow(clickY - handleCenterY, 2)
                          );
                          
                          if (distanceToHandle < 30) {
                            debugPrint('🚫 Ignoring drag - click is in rotation handle area');
                            return;
                          }
                          
                          // ✅ Initialize ValueNotifier if needed
                          if (!_dragPositionNotifiers.containsKey(element.id)) {
                            _dragPositionNotifiers[element.id] = ValueNotifier<Offset>(element.position);
                          }
                          
                          // ✅ Calculate mouse offset from element's top-left corner
                          final currentElementPos = _elementOffsets[element.id] ?? element.position;
                          _dragMouseOffset = details.localPosition;
                          
                          // ✅ Store initial state
                          _selectedElementId = element.id;
                          _currentlyDraggingId = element.id;
                          _dragStartGlobalMousePosition = details.globalPosition;
                          _dragStartElementPosition = currentElementPos;
                          _originalPositions[element.id] = element.position;
                          
                          // ✅ Initialize working state
                          _elementOffsets[element.id] = currentElementPos;
                          _dragPositionNotifiers[element.id]!.value = currentElementPos;
                          
                          debugPrint('🎯 DRAG START | Element: ${element.id.substring(0, 8)} | Offset from top-left: $_dragMouseOffset');
                        },

                        onPanUpdate: isResizing || isRotating || element.locked ? null : (details) {
                          if (_dragStartGlobalMousePosition == null || 
                              _dragStartElementPosition == null ||
                              _dragMouseOffset == null) {
                            return;
                          }
                          
                          // ✅ Calculate total movement in global space
                          final currentGlobalMouse = details.globalPosition;
                          final globalDelta = currentGlobalMouse - _dragStartGlobalMousePosition!;
                          
                          // ✅ Scale delta by zoom
                          final canvasDelta = Offset(
                            globalDelta.dx / _zoomLevel,
                            globalDelta.dy / _zoomLevel,
                          );
                          
                          // ✅ Calculate new position
                          final newPosition = _dragStartElementPosition! + canvasDelta;
                          
                          // ✅ UPDATE ONLY ValueNotifier
                          _dragPositionNotifiers[element.id]?.value = newPosition;
                          _elementOffsets[element.id] = newPosition;
                        },

                        onPanEnd: isResizing || isRotating || element.locked ? null : (details) {
                          final elementId = element.id;
                          final finalPosition = _elementOffsets[elementId] ?? element.position;
                          final originalPosition = _originalPositions[elementId] ?? element.position;

                          // ✅ Clear input state immediately
                          _dragStartGlobalMousePosition = null;
                          _dragStartElementPosition = null;
                          _dragMouseOffset = null;
                          
                          // ✅ Check if position actually changed
                          final distanceMoved = (finalPosition - originalPosition).distance;
                          
                          if (distanceMoved < 1.0) {
                            _currentlyDraggingId = null;
                            _elementOffsets.remove(elementId);
                            _originalPositions.remove(elementId);
                            if (mounted) setState(() {});
                            debugPrint('⚡ Drag end - no movement');
                            return;
                          }

                          debugPrint('💾 Drag end - saving ${distanceMoved.toStringAsFixed(1)}px movement');

                          // ✅ Clear drag state IMMEDIATELY
                          _currentlyDraggingId = null;
                          _originalPositions.remove(elementId);
                          
                          if (mounted) setState(() {});
                          
                          debugPrint('✅ UI updated instantly - starting background save');

                          // ✅ Write to database in background
                          _saveElementPositionToDatabase(
                            elementId: elementId,
                            element: element,
                            finalPosition: finalPosition,
                          );
                        },

                        onPanCancel: isResizing || isRotating || element.locked ? null : () {
                          debugPrint('❌ Drag cancelled');
                          
                          final elementId = element.id;
                          final originalPos = _originalPositions[elementId] ?? element.position;
                          
                          _dragPositionNotifiers[elementId]?.value = originalPos;
                          
                          _currentlyDraggingId = null;
                          _dragStartGlobalMousePosition = null;
                          _dragStartElementPosition = null;
                          _dragMouseOffset = null;
                          _elementOffsets.remove(elementId);
                          _originalPositions.remove(elementId);
                          
                          if (mounted) setState(() {});
                        },
                        
                        child: _SelectionBorder(
                          isSelected: isSelected,
                          isLocked: element.locked,
                          child: RepaintBoundary(
                            child: Container(
                              width: currentSize.width,
                              height: currentSize.height,
                              clipBehavior: Clip.hardEdge,
                              decoration: const BoxDecoration(),
                              child: IgnorePointer(
                                ignoring: isResizing || isRotating,
                                child: _buildElementContent(
                                  element, 
                                  allowInteraction: !isDragging && !isResizing && !isRotating
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // ========== RESIZE HANDLES ==========
                  if (isSelected && !isDragging && !element.locked) ...[
                    _buildResizeHandle(element: element, currentSize: currentSize, alignment: Alignment.topLeft, icon: Icons.north_west),
                    _buildResizeHandle(element: element, currentSize: currentSize, alignment: Alignment.topCenter, icon: Icons.north),
                    _buildResizeHandle(element: element, currentSize: currentSize, alignment: Alignment.topRight, icon: Icons.north_east),
                    _buildResizeHandle(element: element, currentSize: currentSize, alignment: Alignment.centerRight, icon: Icons.east),
                    _buildResizeHandle(element: element, currentSize: currentSize, alignment: Alignment.bottomRight, icon: Icons.south_east),
                    _buildResizeHandle(element: element, currentSize: currentSize, alignment: Alignment.bottomCenter, icon: Icons.south),
                    _buildResizeHandle(element: element, currentSize: currentSize, alignment: Alignment.bottomLeft, icon: Icons.south_west),
                    _buildResizeHandle(element: element, currentSize: currentSize, alignment: Alignment.centerLeft, icon: Icons.west),
                  ],
                ],
              ),
              
              // ========== ROTATION HANDLE (OUTSIDE MAIN GESTURE DETECTOR) ==========
              if (isSelected && !isDragging && !element.locked)
                _buildRotationHandle(element, currentRotation),
            ],
          ),
        ),
      );
    },
    child: const SizedBox.shrink(), // ✅ Required by ValueListenableBuilder but not used
  );
    }

  /// Save element position to database in background
  void _saveElementPositionToDatabase({
    required String elementId,
    required PageElement element,
    required Offset finalPosition,
  }) async {
    try {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) {
        debugPrint('❌ No bookId for background save');
        _elementOffsets.remove(elementId);
        return;
      }

      final pagesAsync = ref.read(bookPagesProvider(widget.bookId!));
      await pagesAsync.when(
        data: (pages) async {
          final pageIndex = ref.read(currentPageIndexProvider);
          if (pages.isEmpty || pageIndex >= pages.length) {
            debugPrint('❌ Invalid page for background save');
            _elementOffsets.remove(elementId);
            return;
          }

          final currentPage = pages[pageIndex];
          
          // Save to undo manager
          _undoRedoManager.saveState(currentPage.elements, currentPage.background);

          // Create updated element
          final updatedElement = PageElement(
            id: element.id,
            type: element.type,
            position: finalPosition,
            size: element.size,
            rotation: element.rotation,
            properties: element.properties,
            textStyle: element.textStyle,
            textAlign: element.textAlign,
            lineHeight: element.lineHeight,
            shadows: element.shadows,
            locked: element.locked,
          );

          // Write to database
          final pageActions = ref.read(pageActionsProvider);
          final success = await pageActions.updateElement(currentPage.id, updatedElement);

          if (success) {
            debugPrint('✅ Background database write successful');
            
            // Invalidate provider to fetch fresh data
            ref.invalidate(bookPagesProvider(bookId));
            
            // Wait for provider to refresh
            await Future.delayed(const Duration(milliseconds: 300));
            
            // Verify provider has new data before clearing cache
            final freshPages = await ref.read(bookPagesProvider(bookId).future);
            if (freshPages.isEmpty || pageIndex >= freshPages.length) {
              debugPrint('⚠️ Fresh pages invalid - keeping cache');
              return;
            }
            
            final freshElement = freshPages[pageIndex].elements.firstWhere(
              (e) => e.id == elementId,
              orElse: () => element,
            );
            
            final providerHasNewPosition = (freshElement.position - finalPosition).distance < 2.0;
            
            if (providerHasNewPosition) {
              debugPrint('✅ Provider confirmed new position - clearing cache');
              if (mounted) {
                setState(() {
                  _elementOffsets.remove(elementId);
                });
              }
            } else {
              debugPrint('⚠️ Provider still has old position: ${freshElement.position} vs $finalPosition');
              debugPrint('⚠️ Keeping cache for 2 more seconds');
              
              // Retry clearing cache after delay
              await Future.delayed(const Duration(seconds: 2));
              if (mounted && _elementOffsets.containsKey(elementId)) {
                setState(() {
                  _elementOffsets.remove(elementId);
                });
                debugPrint('🧹 Cache cleared after retry delay');
              }
            }
          } else {
            debugPrint('❌ Background database write failed');
            _elementOffsets.remove(elementId);
          }
        },
        loading: () {
          debugPrint('⏳ Pages loading during background save');
          _elementOffsets.remove(elementId);
        },
        error: (error, stack) {
          debugPrint('❌ Error during background save: $error');
          _elementOffsets.remove(elementId);
        },
      );
    } catch (e) {
      debugPrint('❌ Exception in background save: $e');
      if (mounted) {
        setState(() {
          _elementOffsets.remove(elementId);
        });
      }
    }
  }

  SystemMouseCursor _getResizeCursor(Alignment alignment) {
    if (alignment == Alignment.topLeft || alignment == Alignment.bottomRight) {
      return SystemMouseCursors.resizeUpLeftDownRight;
    } else if (alignment == Alignment.topRight || alignment == Alignment.bottomLeft) {
      return SystemMouseCursors.resizeUpRightDownLeft;
    } else if (alignment == Alignment.topCenter || alignment == Alignment.bottomCenter) {
      return SystemMouseCursors.resizeUpDown;
    } else if (alignment == Alignment.centerLeft || alignment == Alignment.centerRight) {
      return SystemMouseCursors.resizeLeftRight;
    }
    return SystemMouseCursors.grab;
  }


  Widget _buildResizeHandle({
    required PageElement element,
    required Size currentSize,
    required Alignment alignment,
    required IconData icon,
  }) {
    double? left, top, right, bottom;
    const double handleSize = 26;
    const double handleHitArea = 44;
    
  switch (alignment) {
      case Alignment.topLeft:
        left = -handleHitArea / 2;
        top = -handleHitArea / 2;
        break;
      case Alignment.topCenter:
        left = (currentSize.width / 2) - (handleHitArea / 2);
        top = -handleHitArea / 2;
        break;
      case Alignment.topRight:
        right = -handleHitArea / 2;
        top = -handleHitArea / 2;
        break;
      case Alignment.centerRight:
        right = -handleHitArea / 2;
        top = (currentSize.height / 2) - (handleHitArea / 2);
        break;
      case Alignment.bottomRight:
        right = -handleHitArea / 2;
        bottom = -handleHitArea / 2;
        break;
      case Alignment.bottomCenter:
        left = (currentSize.width / 2) - (handleHitArea / 2);
        bottom = -handleHitArea / 2;
        break;
      case Alignment.bottomLeft:
        left = -handleHitArea / 2;
        bottom = -handleHitArea / 2;
        break;
      case Alignment.centerLeft:
        left = -handleHitArea / 2;
        top = (currentSize.height / 2) - (handleHitArea / 2);
        break;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: MouseRegion(
        cursor: _getResizeCursor(alignment),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                if (element.locked) {
                  _showSnackBar('Element is locked. Unlock it to resize.');
                  return;
                }
                debugPrint('=== RESIZE START ===');
                debugPrint('Element: ${element.id}');
                debugPrint('Handle: $alignment');
                
                setState(() {
                  _selectedElementId = element.id; 
                  _currentlyResizingId = element.id;
                  
                  // 🚀 Store original state
                  _resizeStartMousePosition = details.globalPosition;
                  _resizeStartElementSize = _elementSizes[element.id] ?? element.size;
                  _resizeStartElementPosition = _elementOffsets[element.id] ?? element.position;
                  
                  _elementSizes[element.id] = _resizeStartElementSize!;
                  _elementOffsets[element.id] = _resizeStartElementPosition!;
                  
                  // Reset frame throttling
                });
              },

            onPanUpdate: (details) {
              if (element.locked) return;
              if (_resizeStartMousePosition == null || 
                  _resizeStartElementSize == null || 
                  _resizeStartElementPosition == null) {
                return;
              }



              // 🚀 ABSOLUTE RESIZE: Calculate total change from start
              final totalDelta = details.globalPosition - _resizeStartMousePosition!;
              
              // Scale by zoom level
              final scaledDelta = Offset(
                totalDelta.dx / _zoomLevel,
                totalDelta.dy / _zoomLevel,
              );
              
              // Calculate new dimensions based on handle
              double newWidth = _resizeStartElementSize!.width;
              double newHeight = _resizeStartElementSize!.height;
              double newX = _resizeStartElementPosition!.dx;
              double newY = _resizeStartElementPosition!.dy;
              
              // Apply changes based on handle position
              if (alignment.x == -1) {
                newWidth = _resizeStartElementSize!.width - scaledDelta.dx;
                newX = _resizeStartElementPosition!.dx + scaledDelta.dx;
              } else if (alignment.x == 1) {
                newWidth = _resizeStartElementSize!.width + scaledDelta.dx;
              }
              
              if (alignment.y == -1) {
                newHeight = _resizeStartElementSize!.height - scaledDelta.dy;
                newY = _resizeStartElementPosition!.dy + scaledDelta.dy;
              } else if (alignment.y == 1) {
                newHeight = _resizeStartElementSize!.height + scaledDelta.dy;
              }
              
              // Minimum sizes
              double minWidth = 30;
              double minHeight = 30;

              if (element.type == ElementType.audio) {
                minWidth = 280;
                minHeight = 90;
              } else if (element.type == ElementType.video) {
                minWidth = 200;
                minHeight = 150;
              }

              if (newWidth < minWidth) {
                newWidth = minWidth;
                if (alignment.x == -1) {
                  newX = _resizeStartElementPosition!.dx + (_resizeStartElementSize!.width - minWidth);
                }
              }
              if (newHeight < minHeight) {
                newHeight = minHeight;
                if (alignment.y == -1) {
                  newY = _resizeStartElementPosition!.dy + (_resizeStartElementSize!.height - minHeight);
                }
              }
              
              const double maxWidth = 20000;
              const double maxHeight = 20000;
              if (newWidth > maxWidth) newWidth = maxWidth;
              if (newHeight > maxHeight) newHeight = maxHeight;
              
              // 🚀 Single update
              _elementSizes[element.id] = Size(newWidth, newHeight);
              _elementOffsets[element.id] = Offset(newX, newY);
              setState(() {});
            },

          onPanEnd: (details) {
            debugPrint('=== RESIZE END ===');
            _handleResizeEnd(element.id, element);
          },

            onPanCancel: () {
              debugPrint('=== RESIZE CANCEL ===');
              _clearResizeStateOptimized(element.id);
            },
            child: Container(
              width: handleHitArea,
              height: handleHitArea,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: handleSize,
                height: handleSize,
                decoration: BoxDecoration(
                  color: _currentlyResizingId == element.id ? Colors.orange : Colors.blue,
                  shape: alignment.x != 0 && alignment.y != 0 
                      ? BoxShape.circle 
                      : BoxShape.rectangle,
                  border: Border.all(
                    color: Colors.white, 
                    width: _currentlyResizingId == element.id ? 3 : 2
                  ),
                  borderRadius: alignment.x == 0 || alignment.y == 0 
                      ? BorderRadius.circular(6) 
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: _currentlyResizingId == element.id 
                          ? Colors.orange.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: _currentlyResizingId == element.id ? 12 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRotationHandle(PageElement element, double currentRotation) {
    final currentSize = _elementSizes[element.id] ?? element.size;
    const double handleSize = 36;
    const double handleHitArea = 60;
    
    final topPosition = -50 - (handleHitArea - handleSize) / 2;
    final leftPosition = (currentSize.width / 2) - (handleHitArea / 2);
    
    debugPrint('🎯 Building rotation handle for ${element.id.substring(0, 8)}');
    debugPrint('   Position - top: $topPosition, left: $leftPosition');
    
    return Positioned(
      top: topPosition,
      left: leftPosition,
      // ✅ CRITICAL: Absorb pointer to prevent canvas from getting the event
      child: AbsorbPointer(
        absorbing: false, // Don't absorb for this widget
        child: Listener(
          behavior: HitTestBehavior.opaque, // Changed from translucent to opaque
          onPointerDown: (event) {
            debugPrint('');
            debugPrint('🔵 =============================================');
            debugPrint('🔵 ROTATION HANDLE - POINTER DOWN!');
            debugPrint('🔵 Element: ${element.id.substring(0, 8)}');
            debugPrint('🔵 Button: ${event.buttons}');
            debugPrint('🔵 Local: ${event.localPosition}');
            debugPrint('🔵 Global: ${event.position}');
            debugPrint('🔵 =============================================');
            debugPrint('');
            
            // ✅ CRITICAL: Stop event propagation to canvas
            // (Event is marked as handled, won't reach canvas Listener)
          },
        onPointerMove: (event) {
          debugPrint('🟢 LISTENER - POINTER MOVE');
        },
        onPointerUp: (event) {
          debugPrint('🔴 LISTENER - POINTER UP');
        },
        child: MouseRegion(
          onEnter: (event) {
            debugPrint('🖱️  MOUSE ENTERED rotation handle for ${element.id.substring(0, 8)}');
          },
          onExit: (event) {
            debugPrint('🖱️  MOUSE EXITED rotation handle for ${element.id.substring(0, 8)}');
          },
          onHover: (event) {
            // Uncomment to see constant hover updates (can be spammy)
            // debugPrint('🖱️  MOUSE HOVERING at ${event.localPosition}');
          },
          cursor: _currentlyRotatingId == element.id 
              ? SystemMouseCursors.grabbing 
              : SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) {
              debugPrint('');
              debugPrint('🔵 ─────────────────────────────────────────');
              debugPrint('🔵 GESTURE - onPanDown triggered!');
              debugPrint('🔵 Element: ${element.id.substring(0, 8)}');
              debugPrint('🔵 Local position: ${details.localPosition}');
              debugPrint('🔵 Global position: ${details.globalPosition}');
              debugPrint('🔵 ─────────────────────────────────────────');
              debugPrint('');
            },
            onPanStart: (details) {
              debugPrint('');
              debugPrint('🟢 ═════════════════════════════════════════');
              debugPrint('🟢 GESTURE - onPanStart triggered!');
              debugPrint('🟢 Element: ${element.id.substring(0, 8)}');
              debugPrint('🟢 Element locked: ${element.locked}');
              debugPrint('🟢 Local position: ${details.localPosition}');
              debugPrint('🟢 Global position: ${details.globalPosition}');
              
              if (element.locked) {
                debugPrint('❌ Element is locked - aborting rotation');
                debugPrint('🟢 ═════════════════════════════════════════');
                debugPrint('');
                _showSnackBar('Element is locked. Unlock it to rotate.');
                return;
              }
              
              debugPrint('✅ Starting rotation...');
              debugPrint('   Current rotation: ${element.rotation}');
              debugPrint('   Current _currentlyRotatingId: $_currentlyRotatingId');
              
              setState(() {
                _selectedElementId = element.id;
                _currentlyRotatingId = element.id;
                _elementRotations[element.id] = element.rotation;
              });
              
              debugPrint('   NEW _currentlyRotatingId: $_currentlyRotatingId');
              debugPrint('   setState called - UI should update');
              debugPrint('🟢 ═════════════════════════════════════════');
              debugPrint('');
            },
            onPanUpdate: (details) {
              if (element.locked) {
                debugPrint('⏸️  Rotation update skipped - element locked');
                return;
              }
              
              if (_currentlyRotatingId != element.id) {
                debugPrint('⏸️  Rotation update skipped - not current rotating element');
                return;
              }

              debugPrint('🔄 ─────────────────────────────────────────');
              debugPrint('🔄 ROTATION UPDATE');
              
              final currentPos = _elementOffsets[element.id] ?? element.position;
              final currentSize = _elementSizes[element.id] ?? element.size;
              
              final center = Offset(
                currentPos.dx + currentSize.width / 2,
                currentPos.dy + currentSize.height / 2,
              );
              
              debugPrint('   Element center: $center');
              debugPrint('   Mouse position: ${details.globalPosition}');
              
              final angle = math.atan2(
                details.globalPosition.dy - center.dy,
                details.globalPosition.dx - center.dx,
              );
              
              final degrees = (angle * 180 / math.pi).toStringAsFixed(1);
              debugPrint('   New angle: $degrees°');
              
              setState(() {
                _elementRotations[element.id] = angle;
              });
              
              debugPrint('🔄 ─────────────────────────────────────────');
            },
            onPanEnd: (details) {
              debugPrint('');
              debugPrint('🔴 ═════════════════════════════════════════');
              debugPrint('🔴 ROTATION END');
              debugPrint('🔴 Element: ${element.id.substring(0, 8)}');
              debugPrint('🔴 Final rotation: ${_elementRotations[element.id]}');
              debugPrint('🔴 ═════════════════════════════════════════');
              debugPrint('');
              _handleRotationEnd(element.id, element);
            },
            onPanCancel: () {
              debugPrint('');
              debugPrint('❌ ═════════════════════════════════════════');
              debugPrint('❌ ROTATION CANCELLED');
              debugPrint('❌ Element: ${element.id.substring(0, 8)}');
              debugPrint('❌ Reverting to original rotation: ${element.rotation}');
              
              setState(() {
                _elementRotations[element.id] = element.rotation;
                _currentlyRotatingId = null;
              });
              
              debugPrint('❌ State cleared');
              debugPrint('❌ ═════════════════════════════════════════');
              debugPrint('');
            },
            child: Container(
              width: handleHitArea,
              height: handleHitArea,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // Debug visualization - make it VERY visible
                color: Colors.red.withValues(alpha: 0.5),  // More opaque
                border: Border.all(color: Colors.red, width: 3),  // Thicker border
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: handleSize,
                height: handleSize,
                decoration: BoxDecoration(
                  color: _currentlyRotatingId == element.id ? Colors.green : Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white, 
                    width: _currentlyRotatingId == element.id ? 3 : 2
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _currentlyRotatingId == element.id
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: _currentlyRotatingId == element.id ? 12 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _currentlyRotatingId == element.id
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rotate_right, size: 16, color: Colors.white),
                          const SizedBox(height: 2),
                          Text(
                            '${(currentRotation * 180 / math.pi).round()}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Icon(Icons.refresh, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      )
    );
  }

  Widget _buildElementContent(PageElement element, {bool allowInteraction = true}) {
    // ✅ USE CACHED ELEMENT IF AVAILABLE for instant visual updates
    final displayElement = _localElementCache[element.id] ?? element;
    
    if (_localElementCache[element.id] != null) {
      debugPrint('🎯 [Canvas] USING CACHED ELEMENT: ${element.id}');
      debugPrint('   Cache fontSize: ${displayElement.textStyle?.fontSize}');
    }
    
    switch (displayElement.type) {
      case ElementType.text:
        return Container(
          padding: const EdgeInsets.all(8),
          alignment: _getAlignment(displayElement.textAlign ?? TextAlign.left),
          child: Text(
            displayElement.properties['text'] ?? '',
            style: (displayElement.textStyle ?? const TextStyle(fontSize: 18, color: Colors.black))
                .copyWith(
                  height: displayElement.lineHeight,
                  shadows: displayElement.shadows,
                ),
            textAlign: displayElement.textAlign ?? TextAlign.left,
          ),
        );
      
      case ElementType.image:
        return Image.network(
          displayElement.properties['imageUrl'] ?? '',
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.broken_image, size: 48),
              ),
            );
          },
        );
      
      case ElementType.shape:
        return CustomPaint(
          painter: ShapePainter(
            shapeType: _parseShapeType(displayElement.properties['shapeType']),
            color: _parseColor(displayElement.properties['color']),
            strokeWidth: (displayElement.properties['strokeWidth'] ?? 2.0).toDouble(),
            filled: displayElement.properties['filled'] ?? true,
          ),
          child: const SizedBox.expand(),
        );

      case ElementType.audio:
        return AbsorbPointer(
          absorbing: !allowInteraction,
          child: AudioPlayerWidget(
            audioUrl: displayElement.properties['audioUrl'] ?? '',
            title: displayElement.properties['title'],
            backgroundColor: const Color(0xFF2C3E50),
            accentColor: const Color(0xFF3498DB),
          ),
        );

      case ElementType.video:
        // ✅ ADD DEBUG LOGGING
        debugPrint('🎬 === VIDEO ELEMENT DEBUG ===');
        debugPrint('Element ID: ${displayElement.id}');
        debugPrint('All Properties: ${displayElement.properties}');
        debugPrint('Video URL: ${displayElement.properties['videoUrl']}');
        debugPrint('Thumbnail URL: ${displayElement.properties['thumbnailUrl']}');
        
        return AbsorbPointer(
          absorbing: !allowInteraction,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey, width: 2),
            ),
            child: Stack(
              children: [
                // Video thumbnail or placeholder
                if (displayElement.properties['thumbnailUrl'] != null)
                  Image.network(
                    displayElement.properties['thumbnailUrl'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                else
                  const Center(
                    child: Icon(Icons.videocam, size: 64, color: Colors.white70),
                  ),
                
                // Play button overlay
                Center(
                  child: GestureDetector(
                    onTap: allowInteraction ? () {
                      debugPrint('🎬 VIDEO PLAY BUTTON TAPPED!');
                      debugPrint('Allow Interaction: $allowInteraction');
                      final videoUrl = displayElement.properties['videoUrl'];
                      debugPrint('Video URL from properties: $videoUrl');
                      
                      if (videoUrl != null && videoUrl.toString().isNotEmpty) {
                        debugPrint('✅ Opening video player with URL: $videoUrl');
                        _showVideoPlayer(videoUrl.toString());
                      } else {
                        debugPrint('❌ No video URL found!');
                        _showSnackBar('Video URL is missing. Please re-upload the video.');
                      }
                    } : null,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow, 
                        size: 40, 
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }


  void _showVideoPlayer(String videoUrl) {
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: FutureBuilder(
            future: controller.initialize(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                controller.play();
                return VideoPlayer(controller);
              }
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
          ),
        ),
      ),
    ).then((_) => controller.dispose());
  }

    ShapeType _parseShapeType(dynamic type) {
      if (type == null) return ShapeType.rectangle;
      if (type is ShapeType) return type;
      if (type is String) {
        return ShapeType.values.firstWhere(
          (e) => e.name == type,
          orElse: () => ShapeType.rectangle,
        );
      }
      return ShapeType.rectangle;
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

    Widget _buildEmptyState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Add content to your page', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Use the toolbar above to add text, images, shapes and more',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }


    void _showBookSettings(String bookId) {
      final bookAsync = ref.read(bookProvider(bookId));
      
      bookAsync.when(
        data: (book) {
          if (book == null) return;
          
          final titleController = TextEditingController(text: book.title);
          final descController = TextEditingController(text: book.description ?? '');
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Book Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final bookActions = ref.read(bookActionsProvider);
                    await bookActions.updateBook(
                      bookId: bookId,
                      title: titleController.text,
                      description: descController.text,
                    );
                    if (mounted) Navigator.pop(context);
                    _showSnackBar('Book updated');
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
        loading: () {},
        error: (_, _) {},
      );
    }

    Future<void> _handlePreview() async {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId == null) {
        _showSnackBar('No book loaded');
        return;
      }

      // Optional: Auto-save before previewing
      setState(() => _isSaving = true);
      await _saveCurrentPage();
      setState(() => _isSaving = false);

      if (!mounted) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );

      // Small delay to ensure data is saved
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to preview
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookViewPage(bookId: bookId),
        ),
      );
    }
  }

  // Custom Painter for Grid
  class GridPainter extends CustomPainter {
    final double gridSize;
    final Color gridColor;

    GridPainter({
      required this.gridSize,
      required this.gridColor,
    });

    @override
    void paint(Canvas canvas, Size size) {
      final paint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;

      // Draw vertical lines
      for (double x = 0; x < size.width; x += gridSize) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          paint,
        );
      }

      // Draw horizontal lines
      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          paint,
        );
      }
    }

    @override
    bool shouldRepaint(GridPainter oldDelegate) {
      return oldDelegate.gridSize != gridSize || oldDelegate.gridColor != gridColor;
    }
  }

  // Custom Painter for Shapes
  class ShapePainter extends CustomPainter {
    final ShapeType shapeType;
    final Color color;
    final double strokeWidth;
    final bool filled;

    ShapePainter({
      required this.shapeType,
      required this.color,
      required this.strokeWidth,
      required this.filled,
    });

    @override
    void paint(Canvas canvas, Size size) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke;

      switch (shapeType) {
        case ShapeType.rectangle:
          canvas.drawRect(
            Rect.fromLTWH(0, 0, size.width, size.height),
            paint,
          );
          break;

        case ShapeType.circle:
          canvas.drawCircle(
            Offset(size.width / 2, size.height / 2),
            math.min(size.width, size.height) / 2,
            paint,
          );
          break;

        case ShapeType.triangle:
          final path = Path()
            ..moveTo(size.width / 2, 0)
            ..lineTo(size.width, size.height)
            ..lineTo(0, size.height)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case ShapeType.star:
          final path = _createStarPath(size);
          canvas.drawPath(path, paint);
          break;

        case ShapeType.line:
          canvas.drawLine(
            Offset(0, size.height / 2),
            Offset(size.width, size.height / 2),
            paint,
          );
          break;

        case ShapeType.arrow:
          final path = Path()
            ..moveTo(0, size.height / 2)
            ..lineTo(size.width * 0.7, size.height / 2)
            ..lineTo(size.width * 0.7, 0)
            ..lineTo(size.width, size.height / 2)
            ..lineTo(size.width * 0.7, size.height)
            ..lineTo(size.width * 0.7, size.height / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }
    }

    Path _createStarPath(Size size) {
      final path = Path();
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      final outerRadius = math.min(size.width, size.height) / 2;
      final innerRadius = outerRadius * 0.4;
      const points = 5;

      for (int i = 0; i < points * 2; i++) {
        final radius = i.isEven ? outerRadius : innerRadius;
        final angle = (i * math.pi / points) - math.pi / 2;
        final x = centerX + radius * math.cos(angle);
        final y = centerY + radius * math.sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      return path;
    }

    @override
    bool shouldRepaint(ShapePainter oldDelegate) {
      return oldDelegate.shapeType != shapeType ||
          oldDelegate.color != color ||
          oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.filled != filled;
    }
  }


  // Custom Scrollable Context Menu
  class ScrollableContextMenu extends StatelessWidget {
    final PageElement element;
    final Function(String) onSelected;

    const ScrollableContextMenu({
      super.key,
      required this.element,
      required this.onSelected,
    });

    @override
    Widget build(BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  class _SelectionBorder extends StatelessWidget {
    final bool isSelected;
    final bool isLocked;
    final Widget child;

    const _SelectionBorder({
      required this.isSelected,
      required this.isLocked,
      required this.child,
    });

    @override
    Widget build(BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(
                  color: isLocked ? Colors.orange : Colors.blue,
                  width: 2,
                )
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: child,
      );
    }
  }


  class RotationLinePainter extends CustomPainter {
    final Offset start;
    final Offset end;
    final Color color;

    RotationLinePainter({
      required this.start,
      required this.end,
      required this.color,
    });

    @override
    void paint(Canvas canvas, Size size) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start, end, paint);
    }

    @override
    bool shouldRepaint(RotationLinePainter oldDelegate) {
      return oldDelegate.start != start || 
            oldDelegate.end != end || 
            oldDelegate.color != color;
    }
  }
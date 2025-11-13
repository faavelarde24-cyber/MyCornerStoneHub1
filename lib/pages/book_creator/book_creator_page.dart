// lib/pages/book_creator/book_creator_page.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';  
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
import '../../widgets/search_bar_widget.dart';
import '../book_creator/widgets/image_search_dialog.dart';
import 'package:video_player/video_player.dart';
import 'widgets/audio_player_widget.dart'; 

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
  
  // Grid settings
  bool _gridEnabled = false;
  double _gridSize = 20.0;
  bool _snapToGrid = true;
  
  // Local state for smooth interactions
  final Map<String, Offset> _elementOffsets = {};
  final Map<String, Size> _elementSizes = {};
  final Map<String, double> _elementRotations = {};
  String? _currentlyDraggingId;
  String? _currentlyResizingId;
  String? _currentlyRotatingId;

  // Undo/Redo
  final UndoRedoManager _undoRedoManager = UndoRedoManager();
  
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

@override
void initState() {
  super.initState();
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
    super.dispose();
  }

  // Snap to grid helpers
  Offset _snapToGridIfEnabled(Offset position) {
    if (!_snapToGrid || !_gridEnabled) return position;
    
    return Offset(
      (position.dx / _gridSize).round() * _gridSize,
      (position.dy / _gridSize).round() * _gridSize,
    );
  }

  Size _snapSizeToGridIfEnabled(Size size) {
    if (!_snapToGrid || !_gridEnabled) return size;
    
    return Size(
      (size.width / _gridSize).round() * _gridSize,
      (size.height / _gridSize).round() * _gridSize,
    );
  }

  Future<void> _initializeBook() async {
    try {
      if (widget.bookId != null) {
        ref.read(currentBookIdProvider.notifier).setBookId(widget.bookId);
        setState(() => _isLoading = false);
      } else {
        final bookActions = ref.read(bookActionsProvider);
        final newBook = await bookActions.createBook(
          title: 'Untitled Book',
          description: 'A new book',
        );

        if (newBook != null) {
          ref.read(currentBookIdProvider.notifier).setBookId(newBook.id);
          
          final pageActions = ref.read(pageActionsProvider);
          await pageActions.addPage(newBook.id);
          
          setState(() => _isLoading = false);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to create book. Please check logs.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
      debugPrint('Error initializing book: $e');
    }
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _saveCurrentPage();
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
    final pagesAsync = ref.read(bookPagesProvider);
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

    final pagesAsync = ref.read(bookPagesProvider);
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

    final pagesAsync = ref.read(bookPagesProvider);
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

    final pagesAsync = ref.read(bookPagesProvider);
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

  final pagesAsync = ref.read(bookPagesProvider);
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

          final pagesAsync = ref.read(bookPagesProvider);
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

    final pagesAsync = ref.read(bookPagesProvider);
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

    // Add video element to canvas
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final pagesAsync = ref.read(bookPagesProvider);
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

    final pagesAsync = ref.read(bookPagesProvider);
    final pageIndex = ref.read(currentPageIndexProvider);

    await pagesAsync.when(
      data: (pages) async {
        if (pages.isEmpty || pageIndex >= pages.length) return;
        
        final currentPage = pages[pageIndex];
        
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

 void _showBackgroundSettings() async {
  debugPrint('🎨 === BACKGROUND SETTINGS CLICKED ===');
  
  final bookId = ref.read(currentBookIdProvider);
  debugPrint('📚 Current Book ID: $bookId');
  
  if (bookId == null) {
    debugPrint('❌ No book ID found!');
    return;
  }

  final pagesAsync = ref.read(bookPagesProvider);
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
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final snappedPosition = _snapToGridIfEnabled(newPosition);

    try {
      final pagesAsync = ref.read(bookPagesProvider);
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          
          final currentPage = pages[pageIndex];
          final element = currentPage.elements.firstWhere((e) => e.id == elementId);
          
          final updatedElement = PageElement(
            id: element.id,
            type: element.type,
            position: snappedPosition,
            size: element.size,
            rotation: element.rotation,
            properties: element.properties,
            textStyle: element.textStyle,
            textAlign: element.textAlign,
            lineHeight: element.lineHeight,
            shadows: element.shadows,
          );

          final pageActions = ref.read(pageActionsProvider);
          await pageActions.updateElement(currentPage.id, updatedElement);
        },
        loading: () {},
        error: (_, _) {},
      );
    } catch (e) {
      debugPrint('Error updating element position: $e');
    }
  }

  Future<void> _updateElementSize(String elementId, Size newSize) async {
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final snappedSize = _snapSizeToGridIfEnabled(newSize);

    try {
      final pagesAsync = ref.read(bookPagesProvider);
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          
          final currentPage = pages[pageIndex];
          final element = currentPage.elements.firstWhere((e) => e.id == elementId);
          
          final updatedElement = PageElement(
            id: element.id,
            type: element.type,
            position: element.position,
            size: snappedSize,
            rotation: element.rotation,
            properties: element.properties,
            textStyle: element.textStyle,
            textAlign: element.textAlign,
            lineHeight: element.lineHeight,
            shadows: element.shadows,
          );

          final pageActions = ref.read(pageActionsProvider);
          await pageActions.updateElement(currentPage.id, updatedElement);
          
          if (mounted) {
            setState(() {
              _elementSizes.remove(elementId);
            });
          }
        },
        loading: () {},
        error: (_, _) {},
      );
    } catch (e) {
      debugPrint('Error updating element size: $e');
      if (mounted) {
        setState(() {
          _elementSizes.remove(elementId);
        });
      }
    }
  }

  Future<void> _updateElementRotation(String elementId, double newRotation) async {
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    try {
      final pagesAsync = ref.read(bookPagesProvider);
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          
          final currentPage = pages[pageIndex];
          final element = currentPage.elements.firstWhere((e) => e.id == elementId);
          
          final updatedElement = PageElement(
            id: element.id,
            type: element.type,
            position: element.position,
            size: element.size,
            rotation: newRotation,
            properties: element.properties,
            textStyle: element.textStyle,
            textAlign: element.textAlign,
            lineHeight: element.lineHeight,
            shadows: element.shadows,
          );

          final pageActions = ref.read(pageActionsProvider);
          await pageActions.updateElement(currentPage.id, updatedElement);
          
          if (mounted) {
            setState(() {
              _elementRotations.remove(elementId);
            });
          }
        },
        loading: () {},
        error: (_, _) {},
      );
    } catch (e) {
      debugPrint('Error updating element rotation: $e');
      if (mounted) {
        setState(() {
          _elementRotations.remove(elementId);
        });
      }
    }
  }

  Future<void> _updateElementPositionAndSize(String elementId, Offset newPosition, Size newSize) async {
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final snappedPosition = _snapToGridIfEnabled(newPosition);
    final snappedSize = _snapSizeToGridIfEnabled(newSize);

    try {
      final pagesAsync = ref.read(bookPagesProvider);
      final pageIndex = ref.read(currentPageIndexProvider);

      await pagesAsync.when(
        data: (pages) async {
          if (pages.isEmpty || pageIndex >= pages.length) return;
          
          final currentPage = pages[pageIndex];
          final element = currentPage.elements.firstWhere((e) => e.id == elementId);
          
          final updatedElement = PageElement(
            id: element.id,
            type: element.type,
            position: snappedPosition,
            size: snappedSize,
            rotation: element.rotation,
            properties: element.properties,
            textStyle: element.textStyle,
            textAlign: element.textAlign,
            lineHeight: element.lineHeight,
            shadows: element.shadows,
          );

          final pageActions = ref.read(pageActionsProvider);
          await pageActions.updateElement(currentPage.id, updatedElement);
          
          if (mounted) {
            setState(() {
              _elementOffsets.remove(elementId);
              _elementSizes.remove(elementId);
            });
          }
        },
        loading: () {},
        error: (_, _) {},
      );
    } catch (e) {
      debugPrint('Error updating element position and size: $e');
      if (mounted) {
        setState(() {
          _elementOffsets.remove(elementId);
          _elementSizes.remove(elementId);
        });
      }
    }
  }

  void _updateTextStyle(PageElement element, TextStyle newStyle) async {
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final pagesAsync = ref.read(bookPagesProvider);
    final pageIndex = ref.read(currentPageIndexProvider);

    await pagesAsync.when(
      data: (pages) async {
        if (pages.isEmpty || pageIndex >= pages.length) return;
        
        final currentPage = pages[pageIndex];
        
        _undoRedoManager.saveState(currentPage.elements, currentPage.background);
        
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
        );

        final pageActions = ref.read(pageActionsProvider);
        await pageActions.updateElement(currentPage.id, updatedElement);
      },
      loading: () {},
      error: (_, _) {},
    );
  }

  void _updateTextAlign(PageElement element, TextAlign newAlign) async {
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final pagesAsync = ref.read(bookPagesProvider);
    final pageIndex = ref.read(currentPageIndexProvider);

    await pagesAsync.when(
      data: (pages) async {
        if (pages.isEmpty || pageIndex >= pages.length) return;
        
        final currentPage = pages[pageIndex];
        
        _undoRedoManager.saveState(currentPage.elements, currentPage.background);
        
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
        );

        final pageActions = ref.read(pageActionsProvider);
        await pageActions.updateElement(currentPage.id, updatedElement);
      },
      loading: () {},
      error: (_, _) {},
    );
  }

  void _updateLineHeight(PageElement element, double newLineHeight) async {
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final pagesAsync = ref.read(bookPagesProvider);
    final pageIndex = ref.read(currentPageIndexProvider);

    await pagesAsync.when(
      data: (pages) async {
        if (pages.isEmpty || pageIndex >= pages.length) return;
        
        final currentPage = pages[pageIndex];
        
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
        );

        final pageActions = ref.read(pageActionsProvider);
        await pageActions.updateElement(currentPage.id, updatedElement);
      },
      loading: () {},
      error: (_, _) {},
    );
  }

  void _updateShadows(PageElement element, List<Shadow> newShadows) async {
    final bookId = ref.read(currentBookIdProvider);
    if (bookId == null) return;

    final pagesAsync = ref.read(bookPagesProvider);
    final pageIndex = ref.read(currentPageIndexProvider);

    await pagesAsync.when(
      data: (pages) async {
        if (pages.isEmpty || pageIndex >= pages.length) return;
        
        final currentPage = pages[pageIndex];
        
        _undoRedoManager.saveState(currentPage.elements, currentPage.background);
        
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
        );

        final pageActions = ref.read(pageActionsProvider);
        await pageActions.updateElement(currentPage.id, updatedElement);
      },
      loading: () {},
      error: (_, _) {},
    );
  }

  void _clearResizeState(String elementId) {
    debugPrint('=== CLEARING RESIZE STATE ===');
    debugPrint('Element: $elementId');
    
    final finalSize = _elementSizes[elementId];
    final finalPosition = _elementOffsets[elementId];
    
    setState(() {
      _currentlyResizingId = null;
    });

    if (finalSize != null || finalPosition != null) {
      final bookId = ref.read(currentBookIdProvider);
      if (bookId != null) {
        final pagesAsync = ref.read(bookPagesProvider);
        pagesAsync.whenData((pages) {
          final pageIndex = ref.read(currentPageIndexProvider);
          if (pages.isNotEmpty && pageIndex < pages.length) {
            final currentPage = pages[pageIndex];
            final element = currentPage.elements.firstWhere(
              (e) => e.id == elementId,
              orElse: () => currentPage.elements.first,
            );
            
            _undoRedoManager.saveState(currentPage.elements, currentPage.background);
            
            final sizeChanged = finalSize != null && finalSize != element.size;
            final positionChanged = finalPosition != null && finalPosition != element.position;
            
            if (sizeChanged || positionChanged) {
              if (finalSize != null && finalPosition != null) {
                _updateElementPositionAndSize(elementId, finalPosition, finalSize);
              } else if (finalSize != null) {
                _updateElementSize(elementId, finalSize);
              } else if (finalPosition != null) {
                _updateElementPosition(elementId, finalPosition);
              }
            }
          }
        });
      }
    }
    
    if (mounted) {
      setState(() {
        _elementOffsets.remove(elementId);
        _elementSizes.remove(elementId);
      });
    }
    
    debugPrint('Resize state cleared successfully');
  }

  void _handleElementTap(String elementId) {
    setState(() {
      _selectedElementId = _selectedElementId == elementId ? null : elementId;
    });
  }

  void _editTextElement(PageElement element) {
    showDialog(
      context: context,
      builder: (context) => AdvancedTextEditorDialog(
        element: element,
        onSave: (String newText, bool isList) async {
          final bookId = ref.read(currentBookIdProvider);
          if (bookId == null) return;

          final pagesAsync = ref.read(bookPagesProvider);
          final pageIndex = ref.read(currentPageIndexProvider);

          await pagesAsync.when(
            data: (pages) async {
              if (pages.isEmpty || pageIndex >= pages.length) return;
              
              final currentPage = pages[pageIndex];
              
              _undoRedoManager.saveState(currentPage.elements, currentPage.background);
              
              final updatedProperties = Map<String, dynamic>.from(element.properties);
              updatedProperties['text'] = newText;
              updatedProperties['isList'] = isList;
              
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
              );

              final pageActions = ref.read(pageActionsProvider);
              await pageActions.updateElement(currentPage.id, updatedElement);
            },
            loading: () {},
            error: (_, _) {},
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

    return Scaffold(
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
          onAddAudio: _addAudioElement,      // ← ADD THIS
          onAddVideo: _addVideoElement,      // ← ADD THIS
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
              PropertiesPanel(
                bookId: bookId,
                selectedElementId: _selectedElementId,
                panelColor: appBarColor,
                textColor: textColor,
                onUpdateTextStyle: _updateTextStyle,
                onUpdateTextAlign: _updateTextAlign,
                onUpdateLineHeight: _updateLineHeight,
                onUpdateShadows: _updateShadows,
                onEditText: _editTextElement,
                onClearSliderState: () {},
                onElementSelected: (id) => setState(() => _selectedElementId = id),
                onLayerOrderChanged: (newOrder) {
                  // Layer reordering now handled inside PropertiesPanel
                  _showSnackBar('Layer order updated');
                },
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

 PreferredSizeWidget _buildAppBar(Color appBarColor, Color textColor, String bookId) {
  final bookAsync = ref.watch(bookProvider(bookId));

  return AppBar(
    backgroundColor: appBarColor,
    foregroundColor: textColor,
    elevation: 2,
    toolbarHeight: 90 , // Make taller for search bar
    title: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Title
        bookAsync.when(
          data: (book) => Text(
            book?.title ?? 'Untitled',
            style: AppTheme.headline.copyWith(color: textColor, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          loading: () => const Text('Loading...', style: TextStyle(fontSize: 16)),
          error: (_, _) => const Text('Error', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 8),
        // Row 2: Search Bar
        SizedBox(
          height: 40,
          width: 400,
          child: SmartSearchBar(
            backgroundColor: _isDarkMode ? Colors.grey.shade800 : Colors.white,
            textColor: textColor,
            compact: true,
            hintText: 'Search books from the internet...',
          ),
        ),
      ],
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
        onPressed: () => _showSnackBar('Preview - Coming Soon'),
        tooltip: 'Preview',
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
    final pagesAsync = ref.watch(bookPagesProvider);
    final pageIndex = ref.watch(currentPageIndexProvider);

    return pagesAsync.when(
      data: (pages) {
        if (pages.isEmpty || pageIndex >= pages.length) {
          return const Center(child: Text('No page available'));
        }

        final currentPage = pages[pageIndex];
        
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: currentPage.background.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Background image if exists
                if (currentPage.background.imageUrl != null)
                  Positioned.fill(
                    child: Image.network(
                      currentPage.background.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),
                
                // Grid overlay
                if (_gridEnabled) _buildGridOverlay(),
                
                // Elements
                ...currentPage.elements.map((element) {
                  return _buildDraggableElement(element, currentPage.id);
                }),
                
                if (currentPage.elements.isEmpty) _buildEmptyState(),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
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
    
    final currentPosition = _elementOffsets[element.id] ?? element.position;
    final currentSize = _elementSizes[element.id] ?? element.size;
    final currentRotation = _elementRotations[element.id] ?? element.rotation;

    return Positioned(
      left: currentPosition.dx,
      top: currentPosition.dy,
      child: Transform.rotate(
        angle: currentRotation,
        child: GestureDetector(
          onTap: isResizing || isRotating ? null : () => _handleElementTap(element.id),
          onDoubleTap: isResizing || isRotating ? null : () {
            if (element.type == ElementType.text) {
              _editTextElement(element);
            }
          },
          onPanStart: isResizing || isRotating ? null : (details) {
            setState(() {
              _currentlyDraggingId = element.id;
              _elementOffsets[element.id] = element.position;
            });
          },
          onPanUpdate: isResizing || isRotating ? null : (details) {
            setState(() {
              final currentPos = _elementOffsets[element.id] ?? element.position;
              _elementOffsets[element.id] = Offset(
                currentPos.dx + details.delta.dx,
                currentPos.dy + details.delta.dy,
              );
            });
          },
          onPanEnd: isResizing || isRotating ? null : (details) async {
            final finalPosition = _elementOffsets[element.id] ?? element.position;
            
            setState(() {
              _currentlyDraggingId = null;
            });

            if (finalPosition != element.position) {
              await _updateElementPosition(element.id, finalPosition);
            } else {
              setState(() {
                _elementOffsets.remove(element.id);
              });
            }
          },
          onPanCancel: isResizing || isRotating ? null : () {
            setState(() {
              _currentlyDraggingId = null;
              _elementOffsets.remove(element.id);
            });
          },
          child: Container(
            width: currentSize.width,
            height: currentSize.height,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: isResizing ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                IgnorePointer(
                  ignoring: isResizing || isRotating,
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: _buildElementContent(element),
                  ),
                ),
                if (isSelected && !isDragging) ...[
                  // Resize handles
                  _buildResizeHandle(element: element, alignment: Alignment.topLeft, icon: Icons.north_west),
                  _buildResizeHandle(element: element, alignment: Alignment.topCenter, icon: Icons.north),
                  _buildResizeHandle(element: element, alignment: Alignment.topRight, icon: Icons.north_east),
                  _buildResizeHandle(element: element, alignment: Alignment.centerRight, icon: Icons.east),
                  _buildResizeHandle(element: element, alignment: Alignment.bottomRight, icon: Icons.south_east),
                  _buildResizeHandle(element: element, alignment: Alignment.bottomCenter, icon: Icons.south),
                  _buildResizeHandle(element: element, alignment: Alignment.bottomLeft, icon: Icons.south_west),
                  _buildResizeHandle(element: element, alignment: Alignment.centerLeft, icon: Icons.west),
                  
                  // Rotation handle
                  _buildRotationHandle(element),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRotationHandle(PageElement element) {
    return Positioned(
      top: -40,
      left: (element.size.width / 2) - 15,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _currentlyRotatingId = element.id;
            _elementRotations[element.id] = element.rotation;
          });
        },
        onPanUpdate: (details) {
          final center = Offset(
            element.position.dx + element.size.width / 2,
            element.position.dy + element.size.height / 2,
          );
          
          final angle = math.atan2(
            details.globalPosition.dy - center.dy,
            details.globalPosition.dx - center.dx,
          );
          
          setState(() {
            _elementRotations[element.id] = angle;
          });
        },
        onPanEnd: (details) async {
          final finalRotation = _elementRotations[element.id] ?? element.rotation;
          
          setState(() {
            _currentlyRotatingId = null;
          });

          if (finalRotation != element.rotation) {
            await _updateElementRotation(element.id, finalRotation);
          } else {
            setState(() {
              _elementRotations.remove(element.id);
            });
          }
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.refresh,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildResizeHandle({
    required PageElement element,
    required Alignment alignment,
    required IconData icon,
  }) {
    double? left, top, right, bottom;
    const double handleSize = 20;
    const double handleHitArea = 32;
    
    switch (alignment) {
      case Alignment.topLeft:
        left = -handleHitArea / 2;
        top = -handleHitArea / 2;
        break;
      case Alignment.topCenter:
        left = (element.size.width / 2) - (handleHitArea / 2);
        top = -handleHitArea / 2;
        break;
      case Alignment.topRight:
        right = -handleHitArea / 2;
        top = -handleHitArea / 2;
        break;
      case Alignment.centerRight:
        right = -handleHitArea / 2;
        top = (element.size.height / 2) - (handleHitArea / 2);
        break;
      case Alignment.bottomRight:
        right = -handleHitArea / 2;
        bottom = -handleHitArea / 2;
        break;
      case Alignment.bottomCenter:
        left = (element.size.width / 2) - (handleHitArea / 2);
        bottom = -handleHitArea / 2;
        break;
      case Alignment.bottomLeft:
        left = -handleHitArea / 2;
        bottom = -handleHitArea / 2;
        break;
      case Alignment.centerLeft:
        left = -handleHitArea / 2;
        top = (element.size.height / 2) - (handleHitArea / 2);
        break;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          debugPrint('=== RESIZE START ===');
          debugPrint('Element: ${element.id}');
          debugPrint('Handle: $alignment');
          
          setState(() {
            _currentlyResizingId = element.id;
            _elementSizes[element.id] = element.size;
            _elementOffsets[element.id] = element.position;
          });
        },
        onPanUpdate: (details) {
          final currentResizeSize = _elementSizes[element.id] ?? element.size;
          final currentResizePosition = _elementOffsets[element.id] ?? element.position;
          
          double newWidth = currentResizeSize.width;
          double newHeight = currentResizeSize.height;
          double newX = currentResizePosition.dx;
          double newY = currentResizePosition.dy;
          
          if (alignment.x == -1) {
            newWidth = currentResizeSize.width - details.delta.dx;
            newX = currentResizePosition.dx + details.delta.dx;
          } else if (alignment.x == 1) {
            newWidth = currentResizeSize.width + details.delta.dx;
          }
          
          if (alignment.y == -1) {
            newHeight = currentResizeSize.height - details.delta.dy;
            newY = currentResizePosition.dy + details.delta.dy;
          } else if (alignment.y == 1) {
            newHeight = currentResizeSize.height + details.delta.dy;
          }
          
// Minimum sizes based on element type
double minWidth = 20;
double minHeight = 20;

if (element.type == ElementType.audio) {
  minWidth = 280;  // Audio needs space for controls
  minHeight = 90;  // Audio needs vertical space
} else if (element.type == ElementType.video) {
  minWidth = 200;
  minHeight = 150;
}

if (newWidth < minWidth) newWidth = minWidth;
if (newHeight < minHeight) newHeight = minHeight;
          
          const double maxWidth = 20000;
          const double maxHeight = 20000;
          if (newWidth > maxWidth) newWidth = maxWidth;
          if (newHeight > maxHeight) newHeight = maxHeight;
          
          setState(() {
            _elementSizes[element.id] = Size(newWidth, newHeight);
            _elementOffsets[element.id] = Offset(newX, newY);
          });
        },
        onPanEnd: (details) {
          debugPrint('=== RESIZE END ===');
          _clearResizeState(element.id);
        },
        onPanCancel: () {
          debugPrint('=== RESIZE CANCEL ===');
          _clearResizeState(element.id);
        },
        child: Container(
          width: handleHitArea,
          height: handleHitArea,
          alignment: Alignment.center,
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: alignment.x != 0 && alignment.y != 0 
                  ? BoxShape.circle 
                  : BoxShape.rectangle,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: alignment.x == 0 || alignment.y == 0 
                  ? BorderRadius.circular(4) 
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElementContent(PageElement element) {
    switch (element.type) {
      case ElementType.text:
        return Container(
          padding: const EdgeInsets.all(8),
          alignment: _getAlignment(element.textAlign ?? TextAlign.left),
          child: Text(
            element.properties['text'] ?? '',
            style: (element.textStyle ?? const TextStyle(fontSize: 18, color: Colors.black))
                .copyWith(
                  height: element.lineHeight,
                  shadows: element.shadows,
                ),
            textAlign: element.textAlign ?? TextAlign.left,
          ),
        );
      
      case ElementType.image:
        return Image.network(
          element.properties['imageUrl'] ?? '',
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
            shapeType: _parseShapeType(element.properties['shapeType']),
            color: _parseColor(element.properties['color']),
            strokeWidth: (element.properties['strokeWidth'] ?? 2.0).toDouble(),
            filled: element.properties['filled'] ?? true,
          ),
          child: const SizedBox.expand(),
        );

case ElementType.audio:
  return AudioPlayerWidget(
    audioUrl: element.properties['audioUrl'] ?? '',
    title: element.properties['title'],
    backgroundColor: const Color(0xFF2C3E50),
    accentColor: const Color(0xFF3498DB),
  );

case ElementType.video:
  return Container(
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey, width: 2),
    ),
    child: Stack(
      children: [
        // Video thumbnail or placeholder
        if (element.properties['thumbnailUrl'] != null)
          Image.network(
            element.properties['thumbnailUrl'],
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
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.play_arrow, size: 40, color: Colors.white),
              onPressed: () {
                // Show video player dialog
                final videoUrl = element.properties['videoUrl'];
                if (videoUrl != null) {
                  _showVideoPlayer(videoUrl);
                }
              },
            ),
          ),
        ),
      ],
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
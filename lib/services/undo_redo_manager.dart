// lib/services/undo_redo_manager.dart
// COMPLETE FILE - Ready to Copy & Paste
import 'dart:collection';
import '../models/book_models.dart';

class UndoRedoManager {
  final int maxHistorySize;
  final Queue<PageState> _undoStack = Queue();
  final Queue<PageState> _redoStack = Queue();

  UndoRedoManager({this.maxHistorySize = 50});

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void saveState(List<PageElement> elements, PageBackground background) {
    _undoStack.addLast(PageState(
      elements: List.from(elements),
      background: background,
      timestamp: DateTime.now(),
    ));

    // Limit stack size
    while (_undoStack.length > maxHistorySize) {
      _undoStack.removeFirst();
    }

    // Clear redo stack when new action is performed
    _redoStack.clear();
  }

  PageState? undo() {
    if (!canUndo) return null;
    
    final currentState = _undoStack.removeLast();
    _redoStack.addLast(currentState);
    
    return _undoStack.isNotEmpty ? _undoStack.last : null;
  }

  PageState? redo() {
    if (!canRedo) return null;
    
    final state = _redoStack.removeLast();
    _undoStack.addLast(state);
    
    return state;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}

class PageState {
  final List<PageElement> elements;
  final PageBackground background;
  final DateTime timestamp;

  PageState({
    required this.elements,
    required this.background,
    required this.timestamp,
  });
}
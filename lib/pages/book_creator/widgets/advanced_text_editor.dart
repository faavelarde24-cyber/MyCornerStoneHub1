// lib/pages/book_creator/widgets/advanced_text_editor.dart

import 'package:flutter/material.dart';
import '../../../models/book_models.dart';

class AdvancedTextEditorDialog extends StatefulWidget {
  final PageElement element;
  final Function(String text, bool isBulletList) onSave;

  const AdvancedTextEditorDialog({
    super.key,
    required this.element,
    required this.onSave,
  });

  @override
  State<AdvancedTextEditorDialog> createState() => _AdvancedTextEditorDialogState();
}

class _AdvancedTextEditorDialogState extends State<AdvancedTextEditorDialog> {
  late TextEditingController _textController;
  bool _isBulletList = false;
  bool _isNumberedList = false;

  @override
  void initState() {
    super.initState();
    String text = widget.element.properties['text'] ?? '';
    
    // Check if text is already a bullet list
    if (text.contains('• ')) {
      _isBulletList = true;
      text = text.replaceAll('• ', '');
    } else if (RegExp(r'^\d+\.\s').hasMatch(text)) {
      _isNumberedList = true;
      // Remove numbering for editing
      text = text.split('\n').map((line) {
        return line.replaceFirst(RegExp(r'^\d+\.\s'), '');
      }).join('\n');
    }
    
    _textController = TextEditingController(text: text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _formatText() {
    String text = _textController.text;
    
    if (_isBulletList) {
      // Add bullets to each line
      return text.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => '• ${line.trim()}')
          .join('\n');
    } else if (_isNumberedList) {
      // Add numbering to each line
      final lines = text.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      return lines.asMap().entries
          .map((entry) => '${entry.key + 1}. ${entry.value.trim()}')
          .join('\n');
    }
    
    return text;
  }

  void _insertBulletPoint() {
    final currentText = _textController.text;
    final selection = _textController.selection;
    
    if (selection.baseOffset == -1) {
      _textController.text = '$currentText\n• ';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    } else {
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        '\n• ',
      );
      _textController.text = newText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: selection.start + 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Edit Text',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Formatting Toolbar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildToolbarButton(
                    icon: Icons.format_list_bulleted,
                    label: 'Bullets',
                    isActive: _isBulletList,
                    onPressed: () {
                      setState(() {
                        _isBulletList = !_isBulletList;
                        if (_isBulletList) _isNumberedList = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    icon: Icons.format_list_numbered,
                    label: 'Numbers',
                    isActive: _isNumberedList,
                    onPressed: () {
                      setState(() {
                        _isNumberedList = !_isNumberedList;
                        if (_isNumberedList) _isBulletList = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildToolbarButton(
                    icon: Icons.add_circle_outline,
                    label: 'Add Bullet',
                    isActive: false,
                    onPressed: _insertBulletPoint,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Text Input Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Enter your text here...\n\nTip: Press Enter for new lines',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Preview Section
            if (_isBulletList || _isNumberedList) ...[
              const Text(
                'Preview:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _formatText(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final formattedText = _formatText();
                    widget.onSave(formattedText, _isBulletList || _isNumberedList);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withValues(alpha:0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.blue : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
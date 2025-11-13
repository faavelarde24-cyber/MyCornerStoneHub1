// lib/pages/book_creator/widgets/background_settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../models/book_models.dart';

class BackgroundSettingsDialog extends StatefulWidget {
  final PageBackground currentBackground;
  final Function(PageBackground) onBackgroundChange;

  const BackgroundSettingsDialog({
    super.key,
    required this.currentBackground,
    required this.onBackgroundChange,
  });

  @override
  State<BackgroundSettingsDialog> createState() => _BackgroundSettingsDialogState();
}

class _BackgroundSettingsDialogState extends State<BackgroundSettingsDialog> {
  late Color _selectedColor;
  String? _selectedImageUrl;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentBackground.color;
    _selectedImageUrl = widget.currentBackground.imageUrl;
  }

  Future<void> _pickBackgroundImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImageUrl = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Background Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

            // Color Section
            const Text(
              'Background Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildColorGrid(),
            const SizedBox(height: 24),

            // Image Section
            Row(
              children: [
                const Text(
                  'Background Image',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_selectedImageUrl != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImageUrl = null;
                      });
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Remove'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_selectedImageUrl != null)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  image: DecorationImage(
                    image: _selectedImageUrl!.startsWith('http')
                        ? NetworkImage(_selectedImageUrl!) as ImageProvider
                        : FileImage(File(_selectedImageUrl!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              InkWell(
                onTap: _pickBackgroundImage,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Click to add background image',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    debugPrint('🟡 === BackgroundSettingsDialog Apply Button ===');
                    debugPrint('Selected Color: $_selectedColor');
                    debugPrint('Selected Image: $_selectedImageUrl');
                    
                    final updatedBackground = PageBackground(
                      color: _selectedColor,
                      imageUrl: _selectedImageUrl,
                    );
                    
                    debugPrint('🔧 Calling onBackgroundChange callback...');
                    widget.onBackgroundChange(updatedBackground);
                    
                    debugPrint('🟡 Closing dialog...');
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorGrid() {
    final colors = [
      Colors.white,
      Colors.grey.shade100,
      Colors.grey.shade300,
      Colors.black,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = _selectedColor == color;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade400,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    size: 20,
                  )
                : null,
          ),
        );
      },
    );
  }
}
//lib/pages/book_creator/choose_book_size_page.dart
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../models/book_size_type.dart';
import 'widgets/book_size_card.dart';
class ChooseBookSizePage extends StatefulWidget {
  final String? title;
  final String? description;

  const ChooseBookSizePage({
    super.key,
    this.title,
    this.description,
  });

  @override
  State<ChooseBookSizePage> createState() => _ChooseBookSizePageState();
}

class _ChooseBookSizePageState extends State<ChooseBookSizePage> {
  BookSizeType? _selectedSize;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 === ChooseBookSizePage.initState ===');
    debugPrint('Book title: ${widget.title}');
    debugPrint('Book description: ${widget.description ?? "none"}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Title
                  Text(
                    'Choose Your Book Size',
                    style: AppTheme.headline.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkerText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'Select a page layout to start creating your book.',
                    style: AppTheme.body1.copyWith(
                      fontSize: 16,
                      color: AppTheme.lightText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Size Cards Grid
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    alignment: WrapAlignment.center,
                    children: BookSizeType.values.map((sizeType) {
                      return SizedBox(
                        width: 280,
                        child: BookSizeCard(
                          sizeType: sizeType,
                          isSelected: _selectedSize == sizeType,
                          onTap: () {
                            debugPrint('📐 Size card tapped: ${sizeType.label}');
                            debugPrint('   Dimensions: ${sizeType.width}x${sizeType.height}');
                            debugPrint('   Orientation: ${sizeType.name}');
                            
                            setState(() {
                              _selectedSize = sizeType;
                            });
                            
                            debugPrint('✅ Selected size updated to: ${_selectedSize?.label}');
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back to Dashboard Button
                  OutlinedButton(
                    onPressed: () {
                      debugPrint('🔙 Back to Dashboard pressed');
                      debugPrint('Selected size before cancel: ${_selectedSize?.label ?? "none"}');
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'Back to Dashboard',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightText,
                      ),
                    ),
                  ),

// Continue Button
ElevatedButton(
  onPressed: (_selectedSize == null || _isProcessing)
      ? null
      : () async {
          debugPrint('✅ Continue button pressed');
          debugPrint('Selected size: ${_selectedSize!.label}');
          
          setState(() => _isProcessing = true);
          
          try {
            
            
            
            if (!mounted) return;
            
            debugPrint('🔙 Popping back with ONLY size (not wizard status)');
            
            // ✅ CRITICAL FIX: Return only the BookSizeType
            Navigator.pop(context, _selectedSize);
            
          } catch (e, stackTrace) {
            debugPrint('❌ Error in Continue button: $e');
            debugPrint('Stack trace: $stackTrace');
            
            if (!mounted) return;
            
            // ✅ Still return only the size
            Navigator.pop(context, _selectedSize);
          } finally {
            if (mounted) {
              setState(() => _isProcessing = false);
            }
          }
        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: (_selectedSize == null || _isProcessing) ? 0 : 2,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Continue',
                              style: AppTheme.body1.copyWith(
                                fontWeight: FontWeight.bold,
                                color: (_selectedSize == null || _isProcessing)
                                    ? const Color(0xFF9CA3AF)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: (_selectedSize == null || _isProcessing)
                                  ? const Color(0xFF9CA3AF)
                                  : Colors.white,
                            ),
                          ],
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

  @override
  void dispose() {
    debugPrint('🔴 ChooseBookSizePage disposed');
    debugPrint('Final selected size: ${_selectedSize?.label ?? "none"}');
    super.dispose();
  }
}
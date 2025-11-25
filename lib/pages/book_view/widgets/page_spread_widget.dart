// lib/pages/book_view/widgets/page_spread_widget.dart
import 'package:flutter/material.dart';
import '../../../models/book_models.dart';
import 'page_content_widget.dart';

class PageSpreadWidget extends StatelessWidget {
  final BookPage? leftPage;
  final BookPage? rightPage;
  final double pageWidth;
  final double pageHeight;
  final bool isSinglePageMode;
  final bool isFirstPage;
  final bool isBackside;
  final bool isEndPage;
  final VoidCallback? onRestartBook;


  const PageSpreadWidget({
    super.key,
    required this.leftPage,
    required this.rightPage,
    required this.pageWidth,
    required this.pageHeight,
    this.isSinglePageMode = false,
    this.isFirstPage = false,
    this.isBackside = false,
    this.isEndPage = false,
    this.onRestartBook,

  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 === PageSpreadWidget build ===');
    debugPrint('Single Page Mode: $isSinglePageMode');
    debugPrint('Is First Page: $isFirstPage');
    debugPrint('Is End Page: $isEndPage');
    debugPrint('Left Page: ${leftPage != null ? "exists" : "null"}');
    debugPrint('Right Page: ${rightPage != null ? "exists" : "null"}');
    debugPrint('Page Size: $pageWidth x $pageHeight');

    // ✅ Handle end of book page
    if (isEndPage) {
      return _buildEndOfBookPage();
    }

    if (isSinglePageMode) {
      return _buildSinglePage();
    }

    return _buildTwoPageSpread();
  }

  Widget _buildSinglePage() {
    return Container(
      width: pageWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isBackside ? 0.5 : 0.45),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: rightPage != null
          ? PageContentWidget(
              page: rightPage!,
              isBackside: isBackside,
            )
          : const Center(child: Text('No page')),
    );
  }

  Widget _buildTwoPageSpread() {
    // For the first page (cover), we only show the right page
    if (isFirstPage) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Just show the right page for cover
          _buildRightPage(),
        ],
      );
    }
    
    // Normal two-page spread
    return SizedBox(
      width: (pageWidth * 2) + 24,
      height: pageHeight,
      child: Stack(
        children: [
          // Left page
          Positioned(
            left: 0,
            top: 0,
            child: _buildLeftPage(),
          ),
          
          // Gutter
          Positioned(
            left: pageWidth,
            top: 0,
            child: _buildGutter(),
          ),
          
          // Right page
          Positioned(
            left: pageWidth + 24,
            top: 0,
            child: _buildRightPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOfBookPage() {
    return Builder(
      builder: (context) => Container(
        width: pageWidth,
        height: pageHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Book icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFA500),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  "You've reached the end",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  "of this book",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    color: Color(0xFF666666),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Read again button
                ElevatedButton.icon(
                  onPressed: () {
                    debugPrint('📚 Read again button tapped - restarting book');
                    onRestartBook?.call(); // ✅ Use the callback
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.replay),
                  label: const Text(
                    'Read again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 16),
                
                // Close button
                TextButton.icon(
                  onPressed: () {
                    debugPrint('📚 Close book button tapped');
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Close book'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF666666),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Footer
                const Text(
                  'Made with MyCornerStoneHub',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPage() {
    return Container(
      width: pageWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        color: isFirstPage ? Colors.transparent : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: isFirstPage
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 15,
                  offset: const Offset(-2, 4),
                ),
              ],
      ),
      child: leftPage != null && !isFirstPage
          ? PageContentWidget(page: leftPage!)
          : const SizedBox(),
    );
  }

  Widget _buildGutter() {
    return Container(
      width: 24,
      height: pageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPage() {
    return Container(
      width: pageWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 15,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: rightPage != null
          ? PageContentWidget(page: rightPage!)
          : const SizedBox(),
    );
  }
}
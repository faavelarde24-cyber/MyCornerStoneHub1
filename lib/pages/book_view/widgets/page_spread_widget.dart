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

  const PageSpreadWidget({
    super.key,
    required this.leftPage,
    required this.rightPage,
    required this.pageWidth,
    required this.pageHeight,
    this.isSinglePageMode = false,
    this.isFirstPage = false,
    this.isBackside = false,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 === PageSpreadWidget build ===');
    debugPrint('Single Page Mode: $isSinglePageMode');
    debugPrint('Is First Page: $isFirstPage');
    debugPrint('Left Page: ${leftPage != null ? "exists" : "null"}');
    debugPrint('Right Page: ${rightPage != null ? "exists" : "null"}');
    debugPrint('Page Size: $pageWidth x $pageHeight');

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
          : _buildEndOfBookMessage(),
    );
  }

  Widget _buildEndOfBookMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "You've reached the end of\nthe book",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              debugPrint('📚 Read again button tapped');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA500),
              foregroundColor: Colors.white,
            ),
            child: const Text('Read again'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Made with MyCornerStoneHub',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
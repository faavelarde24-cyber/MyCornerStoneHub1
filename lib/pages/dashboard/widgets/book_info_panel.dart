// lib/pages/dashboard/widgets/book_info_panel.dart
import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../models/book_models.dart';
import 'package:cornerstone_hub/pages/book_view/book_view_page.dart';
import 'book_actions_dialog.dart';
import 'share_options_dialog.dart';

class BookInfoPanel extends StatelessWidget {
  final Book? selectedBook;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onPlay;

  const BookInfoPanel({
    super.key,
    required this.selectedBook,
    this.onPrevious,
    this.onNext,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedBook == null) {
      return Container(
        height: 129,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 100,
          maxHeight: 160,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              children: [
                // Book Title and Author
                Text(
                  selectedBook!.title,
                  style: AppTheme.headline.copyWith(
                    color: AppTheme.white,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${_getAuthorName()}',
                  style: AppTheme.subtitle.copyWith(
                    color: AppTheme.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    _ActionButton(
                      icon: Icons.chevron_left,
                      onTap: onPrevious,
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // ✅ Book Options (Delete, Export, Move)
                    _ActionButton(
                      icon: Icons.menu_book,
                      onTap: () {
                        if (selectedBook != null) {
                          showDialog(
                            context: context,
                            builder: (context) => BookActionsDialog(book: selectedBook!),
                          );
                        }
                      },
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // ✅ Share Options (Download, Publish)
                    _ActionButton(
                      icon: Icons.share_outlined,
                      onTap: () {
                        if (selectedBook != null) {
                          showDialog(
                            context: context,
                            builder: (context) => ShareOptionsDialog(book: selectedBook!),
                          );
                        }
                      },
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Play/Open
                    _ActionButton(
                      icon: Icons.play_arrow_rounded,
                      onTap: () {
                        if (selectedBook != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookViewPage(bookId: selectedBook!.id),
                            ),
                          );
                        }
                      },
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Next Button
                    _ActionButton(
                      icon: Icons.chevron_right,
                      onTap: onNext,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAuthorName() {
    // You can extend this to fetch actual author name from user profile
    return 'Author'; // Placeholder
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
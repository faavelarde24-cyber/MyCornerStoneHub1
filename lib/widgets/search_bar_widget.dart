// lib/widgets/search_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/book_search_providers.dart';
import 'package:cornerstone_hub/widgets/internet_search_results_modal.dart'; // NEW

class SmartSearchBar extends ConsumerStatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final String hintText;
  final bool compact;

  const SmartSearchBar({
    super.key,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.hintText = 'Search books from the internet...',
    this.compact = false,
  });

  @override
  ConsumerState<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends ConsumerState<SmartSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_controller.text.trim().isEmpty) return;
    
    final query = _controller.text.trim();
    ref.read(searchQueryProvider.notifier).setQuery(query);
    
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
    
    _showSearchResults();
  }

  void _showSearchResults() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => InternetSearchResultsModal(
        query: _controller.text.trim(),
      ),
    );
  }

  void _handleSuggestionTap(String suggestion) {
    _controller.text = suggestion;
    setState(() => _showSuggestions = false);
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    // Use internet search suggestions
    final suggestionsAsync = _controller.text.length >= 2
        ? ref.watch(internetSearchSuggestionsProvider(_controller.text))
        : const AsyncValue<List<String>>.data([]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.compact ? 40 : 48,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: TextStyle(
              color: widget.textColor,
              fontSize: widget.compact ? 14 : 16,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: widget.textColor.withValues(alpha: 0.5),
                fontSize: widget.compact ? 14 : 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: widget.textColor.withValues(alpha: 0.5),
                size: widget.compact ? 20 : 24,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: widget.compact ? 18 : 20,
                            color: widget.textColor.withValues(alpha: 0.5),
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _showSuggestions = false);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.search_rounded,
                            size: widget.compact ? 20 : 24,
                            color: Colors.blue,
                          ),
                          onPressed: _performSearch,
                        ),
                      ],
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: widget.compact ? 8 : 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _showSuggestions = value.length >= 2;
              });
            },
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        
        if (_showSuggestions && suggestionsAsync.hasValue)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: suggestionsAsync.when(
              data: (suggestions) {
                if (suggestions.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () => _handleSuggestionTap(suggestions[index]),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 18,
                              color: widget.textColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                suggestions[index],
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.north_west,
                              size: 14,
                              color: widget.textColor.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}
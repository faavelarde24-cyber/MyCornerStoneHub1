// lib/pages/library/widgets/libraries_list_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/library_models.dart';
import '../../../providers/library_providers.dart';
import 'library_details_page.dart';
import '../../../models/app_theme_mode.dart';
import '../../../app_theme.dart';

class LibrariesListDialog extends ConsumerStatefulWidget {
  final bool isStudentView;
  final AppThemeMode themeMode;
  final bool isDarkMode;
  
  const LibrariesListDialog({
    super.key,
    this.isStudentView = false,
    required this.themeMode,
    required this.isDarkMode,
  });

  @override
  ConsumerState<LibrariesListDialog> createState() => _LibrariesListDialogState();
}

class _LibrariesListDialogState extends ConsumerState<LibrariesListDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Library> _filterLibraries(List<Library> libraries) {
    if (_searchQuery.isEmpty) return libraries;
    
    return libraries.where((library) {
      return library.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (library.subject?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
             (library.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  Color _getDialogColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.dark:
        return AppTheme.dark_grey;
      case AppThemeMode.gradient:
        return Colors.white.withValues(alpha: 0.95);
    }
  }

  Color _getTextColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return AppTheme.darkerText;
      case AppThemeMode.dark:
      case AppThemeMode.gradient:
        return widget.themeMode == AppThemeMode.dark ? AppTheme.white : AppTheme.darkerText;
    }
  }

  Color _getSubtitleColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return Colors.grey.shade600;
      case AppThemeMode.dark:
        return AppTheme.white.withValues(alpha: 0.7);
      case AppThemeMode.gradient:
        return Colors.grey.shade700;
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return Colors.purple.shade50;
      case AppThemeMode.dark:
        return Colors.purple.withValues(alpha: 0.2);
      case AppThemeMode.gradient:
        return Colors.purple.shade50;
    }
  }

  Color _getSearchFieldColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return Colors.grey.shade100;
      case AppThemeMode.dark:
        return AppTheme.nearlyBlack;
      case AppThemeMode.gradient:
        return Colors.grey.shade50;
    }
  }

  Color _getCardColor() {
    switch (widget.themeMode) {
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.dark:
        return AppTheme.nearlyBlack;
      case AppThemeMode.gradient:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final librariesAsync = widget.isStudentView 
        ? ref.watch(joinedLibrariesProvider)
        : ref.watch(userLibrariesProvider);

    return Dialog(
      backgroundColor: _getDialogColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.library_books,
                    color: Colors.purple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isStudentView ? 'My Classes' : 'My Libraries',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: _getTextColor()),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: _getSubtitleColor().withValues(alpha: 0.3)),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              style: TextStyle(color: _getTextColor()),
              decoration: InputDecoration(
                hintText: 'Search libraries...',
                hintStyle: TextStyle(color: _getSubtitleColor()),
                prefixIcon: Icon(Icons.search, color: _getTextColor()),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: _getTextColor()),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: _getSearchFieldColor(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 16),

            // Libraries List
            Expanded(
              child: librariesAsync.when(
                data: (libraries) {
                  final filteredLibraries = _filterLibraries(libraries);
                  
                  if (libraries.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  if (filteredLibraries.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return ListView.builder(
                    itemCount: filteredLibraries.length,
                    itemBuilder: (context, index) {
                      return _buildLibraryCard(filteredLibraries[index]);
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: widget.themeMode == AppThemeMode.dark 
                        ? Colors.purple 
                        : const Color(0xFF6C5CE7),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading libraries: $error',
                        style: TextStyle(color: _getTextColor()),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(widget.isStudentView 
                              ? joinedLibrariesProvider 
                              : userLibrariesProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: _getSubtitleColor(),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isStudentView 
                ? 'No classes joined yet' 
                : 'No libraries created yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isStudentView
                ? 'Use an invite code to join a class'
                : 'Create your first library to get started',
            style: TextStyle(
              fontSize: 14,
              color: _getSubtitleColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: _getSubtitleColor(),
          ),
          const SizedBox(height: 16),
          Text(
            'No libraries found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: _getSubtitleColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard(Library library) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.pink,
      Colors.green,
    ];
    final colorIndex = int.parse(library.id) % colors.length;
    final color = colors[colorIndex];

    return Card(
      color: _getCardColor(),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LibraryDetailsPage(library: library),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Library Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.library_books,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Library Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      library.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (library.subject != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        library.subject!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getSubtitleColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.book, size: 14, color: _getSubtitleColor()),
                        const SizedBox(width: 4),
                        Text(
                          '${library.bookCount} books',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getSubtitleColor(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.people, size: 14, color: _getSubtitleColor()),
                        const SizedBox(width: 4),
                        Text(
                          '${library.memberCount} members',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getSubtitleColor(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              if (!widget.isStudentView)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: _getTextColor()),
                  color: _getCardColor(),
                  onSelected: (value) async {
                    if (value == 'share') {
                      _showShareDialog(library);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(library);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 18, color: _getTextColor()),
                          const SizedBox(width: 8),
                          Text('Share Invite Code', style: TextStyle(color: _getTextColor())),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Icon(Icons.chevron_right, color: _getSubtitleColor()),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareDialog(Library library) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getDialogColor(),
        title: Text('Share Invite Code', style: TextStyle(color: _getTextColor())),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this code with students to join "${library.name}":',
              style: TextStyle(color: _getTextColor()),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    library.inviteCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: library.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _getTextColor())),
          ),
        ],
      ),
    );
  }

Future<void> _showDeleteConfirmation(Library library) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: _getDialogColor(),
      title: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 12),
          Text('Delete Library', style: TextStyle(color: _getTextColor())),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${library.name}"?',
            style: TextStyle(
              color: _getTextColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• All members will be removed\n'
                  '• All books will be unlinked\n'
                  '• The invite code will be deleted',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('Cancel', style: TextStyle(color: _getTextColor())),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  // Show loading dialog
  if (!mounted) return;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: _getDialogColor(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Deleting library...',
              style: TextStyle(color: _getTextColor()),
            ),
          ],
        ),
      ),
    ),
  );

  try {
    final actions = ref.read(libraryActionsProvider);
    final success = await actions.deleteLibrary(library.id);

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    if (success) {
      // Invalidate providers to refresh the list
      ref.invalidate(userLibrariesProvider);
      ref.invalidate(joinedLibrariesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Library "${library.name}" deleted successfully'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Failed to delete library')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  } catch (e) {
    // Close loading dialog if still open
    if (mounted) {
      Navigator.pop(context);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
}
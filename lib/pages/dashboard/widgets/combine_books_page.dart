// lib/pages/dashboard/widgets/combine_books_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/book_models.dart';
import '../../../providers/book_providers.dart';
import '../../../widgets/book_preview_3d.dart';

class CombineBooksPage extends ConsumerStatefulWidget {
  final Book initialBook;

  const CombineBooksPage({
    super.key,
    required this.initialBook,
  });

  @override
  ConsumerState<CombineBooksPage> createState() => _CombineBooksPageState();
}

class _CombineBooksPageState extends ConsumerState<CombineBooksPage> {
  final _titleController = TextEditingController();
  final PageController _pageController = PageController();
  
  List<Book> _selectedBooks = [];
  int _currentStep = 0;
  bool _deleteOriginalBooks = false;

  @override
  void initState() {
    super.initState();
    _selectedBooks = [widget.initialBook];
    _titleController.text = '${widget.initialBook.title} & More';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    super.dispose();
  }



  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
  if (_currentStep < 2) {  // Changed from 3 to 2 (3 steps total: 0, 1, 2)
    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(userBooksProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Combine Books'),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: booksAsync.when(
                  data: (books) => PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStep1SelectBooks(books),
        _buildStep2ArrangeBooks(), // Updated with 3D previews
        _buildStep3NameAndConfirm(), // Renamed from step 4
      ],
    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

Widget _buildProgressIndicator() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        _buildStepIndicator(0, 'Select', Icons.library_books),
        _buildStepConnector(0),
        _buildStepIndicator(1, 'Order', Icons.reorder),
        _buildStepConnector(1),
        _buildStepIndicator(2, 'Name', Icons.edit),
      ],
    ),
  );
}

Widget _buildStepIndicator(int step, String label, IconData icon) {
  final isActive = _currentStep == step;
  final isCompleted = _currentStep > step;

  return Expanded(
    child: Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? const Color(0xFFF59E0B)
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFFF59E0B) : Colors.grey[600],
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ],
    ),
  );
}

  Widget _buildStepConnector(int step) {
    final isCompleted = _currentStep > step;
    
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isCompleted ? const Color(0xFFF59E0B) : Colors.grey[300],
      ),
    );
  }

// Replace the _buildStep1SelectBooks method in combine_books_page.dart

Widget _buildStep1SelectBooks(List<Book> allBooks) {
  final availableBooks = allBooks
      .where((book) => !_selectedBooks.any((selected) => selected.id == book.id))
      .toList();

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📚 Choose Books to Combine',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select at least 2 books. You can arrange their order in the next step.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF59E0B).withValues(alpha: 0.1),
                const Color(0xFFF59E0B).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_selectedBooks.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Books Selected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_calculateTotalPages()} pages total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedBooks.length >= 2)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (_selectedBooks.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Books',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedBooks = [widget.initialBook];
                  });
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // ✅ CHANGED: Show selected books as 3D previews in horizontal scroll
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedBooks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final book = _selectedBooks[index];
                final pagesAsync = ref.watch(bookPagesProvider(book.id));
                
                return Stack(
                  children: [
                    pagesAsync.when(
                      data: (pages) => BookPreview3D(
                        book: book,
                        firstPage: pages.isNotEmpty ? pages.first : null,
                        width: 140,
                        height: 180,
                        onTap: book.id == widget.initialBook.id ? null : () {
                          setState(() {
                            _selectedBooks.remove(book);
                          });
                        },
                      ),
                      loading: () => _buildLoadingBook(book),
                      error: (_, _) => _buildErrorBook(book),
                    ),
                    
                    // Remove button
                    if (book.id != widget.initialBook.id)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBooks.remove(book);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    
                    // Lock indicator for initial book
                    if (book.id == widget.initialBook.id)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        Text(
          'Available Books',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        if (availableBooks.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'All books selected!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // ✅ CHANGED: Grid of 3D book previews
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
            ),
            itemCount: availableBooks.length,
            itemBuilder: (context, index) {
              final book = availableBooks[index];
              final pagesAsync = ref.watch(bookPagesProvider(book.id));
              
              return pagesAsync.when(
                data: (pages) => BookPreview3D(
                  book: book,
                  firstPage: pages.isNotEmpty ? pages.first : null,
                  width: 140,
                  height: 180,
                  onTap: () {
                    setState(() {
                      _selectedBooks.add(book);
                    });
                  },
                ),
                loading: () => _buildLoadingBook(book),
                error: (_, _) => _buildErrorBook(book),
              );
            },
          ),
      ],
    ),
  );
}

// ✅ ADD these helper methods after _buildStep1SelectBooks:

Widget _buildLoadingBook(Book book) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 140,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[400],
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: 140,
        child: Text(
          book.title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}

Widget _buildErrorBook(Book book) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 140,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Center(
          child: Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.red[300],
          ),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: 140,
        child: Text(
          book.title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}


// ✅ ADD these helper methods after _buildBookCard:


Widget _buildStep2ArrangeBooks() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📖 Arrange Book Order',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Drag books to reorder. Pages will be combined in this order.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.preview, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  const Text(
                    'Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPageFlowPreview(),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Reorderable list of books with 3D previews
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedBooks.length,
          onReorder: _onReorderBooks,
          proxyDecorator: (child, index, animation) {
            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final book = _selectedBooks[index];
            final pagesAsync = ref.watch(bookPagesProvider(book.id));
            
            return ReorderableDragStartListener(
              key: ValueKey(book.id),
              index: index,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Drag handle - more prominent
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                        child: Icon(
                          Icons.drag_indicator,
                          color: Colors.grey[400],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Position number
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // 3D Book Preview
                      pagesAsync.when(
                        data: (pages) => BookPreview3D(
                          book: book,
                          firstPage: pages.isNotEmpty ? pages.first : null,
                          width: 80,
                          height: 100,
                        ),
                        loading: () => Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                        error: (_, _) => Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.error_outline, color: Colors.red[300]),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Book info - Title and Page Count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Book title - prominent
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Page count with icon
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${book.pageCount} pages',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ready',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildPageFlowPreview() {
    int startPage = 1;
    return Column(
      children: _selectedBooks.asMap().entries.map((entry) {
        final index = entry.key;
        final book = entry.value;
        final endPage = startPage + book.pageCount - 1;
        
        final widget = Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Pages $startPage - $endPage',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              '${book.pageCount} pages',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        );
        
        startPage = endPage + 1;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: widget,
        );
      }).toList(),
    );
  }




 Widget _buildStep3NameAndConfirm() {
  final totalPages = _calculateTotalPages();
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✨ Almost Done!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Give your combined book a name and review the details.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF59E0B).withValues(alpha: 0.1),
                const Color(0xFFF59E0B).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    icon: Icons.auto_stories,
                    label: 'Books',
                    value: '${_selectedBooks.length}',
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildSummaryItem(
                    icon: Icons.description,
                    label: 'Total Pages',
                    value: '$totalPages',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Book Title',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter a name for your combined book',
            prefixIcon: const Icon(Icons.book, color: Color(0xFFF59E0B)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Books in Order',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: _selectedBooks.asMap().entries.map((entry) {
              final index = entry.key;
              final book = entry.value;
              final isLast = index == _selectedBooks.length - 1;
              
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF59E0B),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(book.title),
                    subtitle: Text('${book.pageCount} pages'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  if (!isLast) Divider(height: 1, color: Colors.grey[200]),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: CheckboxListTile(
            value: _deleteOriginalBooks,
            onChanged: (value) {
              setState(() {
                _deleteOriginalBooks = value ?? false;
              });
            },
            title: const Text('Delete original books'),
            subtitle: Text(
              'Original books will be permanently deleted after combining',
              style: TextStyle(
                fontSize: 12,
                color: _deleteOriginalBooks ? Colors.red[600] : Colors.grey[600],
              ),
            ),
            secondary: Icon(
              _deleteOriginalBooks ? Icons.delete_forever : Icons.delete_outline,
              color: _deleteOriginalBooks ? Colors.red : Colors.grey,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    ),
  );
}
Widget _buildSummaryItem({
required IconData icon,
required String label,
required String value,
}) {
return Column(
children: [
Icon(icon, color: const Color(0xFFF59E0B), size: 32),
const SizedBox(height: 8),
Text(
value,
style: const TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Color(0xFFF59E0B),
),
),
Text(
label,
style: TextStyle(
fontSize: 14,
color: Colors.grey[600],
),
),
],
);
}
Widget _buildNavigationBar() {
  final canProceed = _currentStep == 0
      ? _selectedBooks.length >= 2
      : _currentStep == 2
          ? _titleController.text.trim().isNotEmpty
          : true;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 12),
          
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: canProceed
                  ? (_currentStep == 2 ? _handleCombineBooks : _nextStep)
                  : null,
              icon: Icon(_currentStep == 2 ? Icons.merge_type : Icons.arrow_forward),
              label: Text(_currentStep == 2 ? 'Combine Books' : 'Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

int _calculateTotalPages() {
return _selectedBooks.fold(0, (sum, book) => sum + book.pageCount);
}
void _onReorderBooks(int oldIndex, int newIndex) {
setState(() {
if (newIndex > oldIndex) {
newIndex -= 1;
}
final book = _selectedBooks.removeAt(oldIndex);
_selectedBooks.insert(newIndex, book);
});
}
// ✅ NEW: Reorder individual pages
Future<void> _handleCombineBooks() async {
if (_selectedBooks.length < 2) {
_showMessage('Please select at least 2 books', isError: true);
return;
}
if (_titleController.text.trim().isEmpty) {
  _showMessage('Please enter a title', isError: true);
  return;
}

final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Row(
      children: [
        Icon(Icons.merge_type, color: Color(0xFFF59E0B)),
        SizedBox(width: 12),
        Text('Confirm Combination'),
      ],
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Combining ${_selectedBooks.length} books into:'),
        const SizedBox(height: 8),
        Text(
          '"${_titleController.text.trim()}"',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Books', style: TextStyle(fontSize: 12)),
                  Text(
                    '${_selectedBooks.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('Pages', style: TextStyle(fontSize: 12)),
                  Text(
                    '${_calculateTotalPages()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_deleteOriginalBooks) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Original books will be deleted!',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Combine Now'),
      ),
    ],
  ),
);

if (confirmed != true) return;

_showLoadingMessage('Combining books...');

final bookActions = ref.read(bookActionsProvider);

// ✅ MODIFIED: Pass custom page order if enabled
final combinedBook = await bookActions.combineBooks(
  bookIds: _selectedBooks.map((b) => b.id).toList(),
  title: _titleController.text.trim(),
  description: null,
  deleteOriginalBooks: _deleteOriginalBooks, // ✅ NEW PARAMETER
);

if (!mounted) return;

ScaffoldMessenger.of(context).hideCurrentSnackBar();

if (combinedBook != null) {
  _showMessage(
    'Successfully created "${combinedBook.title}"! 🎉',
    isError: false,
  );
  
  await Future.delayed(const Duration(milliseconds: 500));
  if (mounted) {
    Navigator.pop(context);
  }
} else {
  _showMessage('Failed to combine books. Please try again.', isError: true);
}
}
void _showMessage(String message, {required bool isError}) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Row(
children: [
Icon(
isError ? Icons.error_outline : Icons.check_circle_outline,
color: Colors.white,
),
const SizedBox(width: 12),
Expanded(child: Text(message)),
],
),
backgroundColor: isError ? Colors.red : Colors.green,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
),
);
}
void _showLoadingMessage(String message) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Row(
children: [
const SizedBox(
width: 20,
height: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
),
),
const SizedBox(width: 16),
Text(message),
],
),
behavior: SnackBarBehavior.floating,
duration: const Duration(minutes: 5),
),
);
}
}
// ✅ NEW: Helper class to track page info
// ignore: unused_element
class _PageInfo {
final BookPage page;
final String bookTitle;
final String bookId;
_PageInfo({
required this.page,
required this.bookTitle,
required this.bookId,
});
}
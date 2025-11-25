//lib/services/book_export_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../models/book_models.dart';
import 'platform_file_saver.dart';

class BookExportService {
  /// Export book as PDF (Works on Web, iOS, Android, Desktop)
  Future<File?> exportAsPDF({
    required Book book,
    required List<BookPage> pages,
  }) async {
    try {
      debugPrint('📄 === START PDF EXPORT ===');
      debugPrint('Platform: ${kIsWeb ? 'Web' : 'Mobile/Desktop'}');
      debugPrint('Book: ${book.title}');
      debugPrint('Pages: ${pages.length}');

      final pdf = pw.Document();

      // Add each page to PDF
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        debugPrint('📄 Processing page ${i + 1}/${pages.length}');
        await _addPageToPDF(pdf, page, book);
      }

      debugPrint('📄 Generating PDF bytes...');
      final pdfBytes = await pdf.save();

      // Save using platform-specific implementation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_sanitizeFileName(book.title)}_$timestamp.pdf';
      
      final file = await PlatformFileSaver.saveFile(pdfBytes, fileName);
      debugPrint('📄 === END PDF EXPORT ===\n');
      return file;
    } catch (e, stack) {
      debugPrint('❌ PDF Export Error: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  Future<void> _addPageToPDF(
    pw.Document pdf,
    BookPage page,
    Book book,
  ) async {
    final pageWidth = book.pageSize.width;
    final pageHeight = book.pageSize.height;

    // ✅ Load background image if exists (before building page)
    pw.ImageProvider? backgroundImage;
    if (page.background.imageUrl != null && 
        page.background.imageUrl!.isNotEmpty) {
      backgroundImage = await _loadNetworkImage(page.background.imageUrl!);
    }

    // ✅ Load all element images before building page
    final elementWidgets = <pw.Widget>[];
    for (final element in page.elements) {
      final widget = await _buildPdfElementAsync(element);
      elementWidgets.add(widget);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight),
        build: (context) {
          return pw.Stack(
            children: [
              // Background color
              pw.Container(
                width: pageWidth,
                height: pageHeight,
                color: _convertToPdfColor(page.background.color),
              ),
              
              // Background image (if exists)
              if (backgroundImage != null)
                pw.Container(
                  width: pageWidth,
                  height: pageHeight,
                  child: pw.Image(backgroundImage, fit: pw.BoxFit.cover),
                ),
              
              // Elements
              ...elementWidgets,
            ],
          );
        },
      ),
    );
  }

  Future<pw.ImageProvider?> _loadNetworkImage(String url) async {
    try {
      debugPrint('📥 Loading image: ${url.substring(0, 50)}...');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        debugPrint('✅ Image loaded successfully');
        return pw.MemoryImage(response.bodyBytes);
      } else {
        debugPrint('⚠️ Failed to load image. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load image: $e');
    }
    return null;
  }

  Future<pw.Widget> _buildPdfElementAsync(PageElement element) async {
    return pw.Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: pw.Container(
        width: element.size.width,
        height: element.size.height,
        child: await _buildElementContentAsync(element),
      ),
    );
  }

  Future<pw.Widget> _buildElementContentAsync(PageElement element) async {
    switch (element.type) {
      case ElementType.text:
        return _buildTextElement(element);
      case ElementType.shape:
        return _buildShapeElement(element);
      case ElementType.image:
        return await _buildImageElementAsync(element);
      default:
        return pw.Container();
    }
  }

  pw.Widget _buildTextElement(PageElement element) {
    final text = element.properties['text'] as String? ?? '';
    final style = element.textStyle;

    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: style?.fontSize ?? 16,
        fontWeight: style?.fontWeight == FontWeight.bold 
            ? pw.FontWeight.bold 
            : pw.FontWeight.normal,
        fontStyle: style?.fontStyle == FontStyle.italic
            ? pw.FontStyle.italic
            : pw.FontStyle.normal,
        color: style?.color != null 
            ? _convertToPdfColor(style!.color!)
            : PdfColors.black,
      ),
      textAlign: _convertTextAlign(element.textAlign),
    );
  }

  pw.Widget _buildShapeElement(PageElement element) {
    final colorHex = element.properties['color'] as String?;
    final color = colorHex != null 
        ? _parsePdfColor(colorHex) 
        : PdfColors.blue;
    final filled = element.properties['filled'] as bool? ?? true;
    final shapeType = element.properties['shapeType'] as String? ?? 'rectangle';

    switch (shapeType) {
      case 'circle':
        return pw.Container(
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: filled ? color : null,
            border: !filled ? pw.Border.all(color: color, width: 2) : null,
          ),
        );
      case 'rectangle':
      default:
        return pw.Container(
          decoration: pw.BoxDecoration(
            color: filled ? color : null,
            border: !filled ? pw.Border.all(color: color, width: 2) : null,
            borderRadius: pw.BorderRadius.circular(4),
          ),
        );
    }
  }

  Future<pw.Widget> _buildImageElementAsync(PageElement element) async {
    final imageUrl = element.properties['imageUrl'] as String?;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final image = await _loadNetworkImage(imageUrl);
      
      if (image != null) {
        return pw.Image(image, fit: pw.BoxFit.contain);
      }
    }
    
    // Placeholder if image failed to load
    return pw.Container(
      color: PdfColors.grey300,
      child: pw.Center(
        child: pw.Icon(
          const pw.IconData(0xe3f4), // image icon
          size: 24,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  /// Export book as EPUB (placeholder for future implementation)
  Future<File?> exportAsEPUB({
    required Book book,
    required List<BookPage> pages,
  }) async {
    try {
      debugPrint('📚 === START EPUB EXPORT ===');
      debugPrint('Book: ${book.title}');
      debugPrint('Pages: ${pages.length}');
      debugPrint('⚠️ EPUB export is not yet implemented');
      debugPrint('📚 === END EPUB EXPORT ===\n');

      return null;
    } catch (e, stack) {
      debugPrint('❌ EPUB Export Error: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  /// Share exported file (Mobile/Desktop only - Web uses direct download)
  Future<void> shareFile(File file, String title) async {
    if (kIsWeb) {
      debugPrint('⚠️ Share not available on web (file already downloaded)');
      return;
    }

    try {
      debugPrint('📤 Sharing file: ${file.path}');
      
      // ✅ Correct API for share_plus ^12.0.1
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$title\n\nExported from MyCornerStoneHub',
      );
      
      debugPrint('✅ File shared successfully');
    } catch (e) {
      debugPrint('❌ Share error: $e');
      // Don't crash the app if share fails
    }
  }

  // Helper methods
  PdfColor _convertToPdfColor(Color color) {
    return PdfColor(
      (color.r * 255.0).round() / 255,
      (color.g * 255.0).round() / 255,
      (color.b * 255.0).round() / 255,
      (color.a * 255.0).round() / 255,
    );
  }

  PdfColor _parsePdfColor(String colorHex) {
    try {
      final hexColor = colorHex.replaceAll('#', '').replaceAll('0x', '');
      final colorInt = int.parse(hexColor, radix: 16);
      
      final a = ((colorInt >> 24) & 0xFF) / 255;
      final r = ((colorInt >> 16) & 0xFF) / 255;
      final g = ((colorInt >> 8) & 0xFF) / 255;
      final b = (colorInt & 0xFF) / 255;
      
      return PdfColor(r, g, b, a);
    } catch (e) {
      return PdfColors.blue;
    }
  }

  pw.TextAlign _convertTextAlign(TextAlign? align) {
    switch (align) {
      case TextAlign.left:
        return pw.TextAlign.left;
      case TextAlign.center:
        return pw.TextAlign.center;
      case TextAlign.right:
        return pw.TextAlign.right;
      case TextAlign.justify:
        return pw.TextAlign.justify;
      default:
        return pw.TextAlign.left;
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
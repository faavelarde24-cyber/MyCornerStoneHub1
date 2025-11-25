import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

Future<File?> saveFileImpl(List<int> bytes, String fileName) async {
  try {
    debugPrint('📥 Triggering web download...');
    
    // Convert to Uint8List
    final uint8list = Uint8List.fromList(bytes);
    
    // Create blob
    final blob = html.Blob([uint8list], 'application/pdf');
    
    // Create download URL
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Create anchor and trigger download
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    
    // Clean up
    html.Url.revokeObjectUrl(url);
    
    debugPrint('✅ Web download triggered: $fileName');
    return File(fileName);
  } catch (e, stack) {
    debugPrint('❌ Web download error: $e');
    debugPrint('Stack: $stack');
    return null;
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<File?> saveFileImpl(List<int> bytes, String fileName) async {
  try {
    debugPrint('💾 Saving PDF to device...');
    
    // Convert to Uint8List if needed
    final uint8list = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/Downloads');
    
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final file = File('${downloadsDir.path}/$fileName');
    await file.writeAsBytes(uint8list);

    debugPrint('✅ PDF saved: ${file.path}');
    return file;
  } catch (e) {
    debugPrint('❌ Device save error: $e');
    return null;
  }
}
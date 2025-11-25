import 'dart:io';
import 'platform_file_saver_stub.dart'
    if (dart.library.html) 'platform_file_saver_web.dart'
    if (dart.library.io) 'platform_file_saver_io.dart';

abstract class PlatformFileSaver {
  static Future<File?> saveFile(List<int> bytes, String fileName) {
    return saveFileImpl(bytes, fileName);
  }
}
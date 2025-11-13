// lib/services/storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class StorageService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Bucket names - matching your Supabase buckets
  static const String imagesBucket = 'book-images';
  static const String audioBucket = 'book-audio';
  static const String videosBucket = 'book-videos';
  static const String exportsBucket = 'book-exports';

  // File size limits (in bytes) - Supabase free tier max is 50MB per file
  static const int maxImageSize = 5 * 1024 * 1024;   // 5 MB
  static const int maxAudioSize = 10 * 1024 * 1024;  // 10 MB
  static const int maxVideoSize = 50 * 1024 * 1024;  // 50 MB (Supabase max)
  static const int maxExportSize = 20 * 1024 * 1024; // 20 MB

  /// Validates file size before upload
  bool _validateFileSize(int fileSize, int maxSize) {
    if (fileSize > maxSize) {
      debugPrint('❌ File too large: ${_getFileSize(fileSize)} (max: ${_getFileSize(maxSize)})');
      return false;
    }
    return true;
  }

  /// Gets human-readable file size
  String _getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  /// Uploads an image file (max 5 MB) - Cross-platform
  Future<String?> uploadImage(dynamic file, String folder, {String? originalFileName}) async {
    debugPrint('🖼️ uploadImage() called');
    debugPrint('   File type: ${file.runtimeType}');
    debugPrint('   Folder: $folder');
    
    try {
      // Validate file size
      int fileSize;
      if (file is File) {
        debugPrint('   Calculating File size...');
        fileSize = file.lengthSync();
      } else if (file is XFile) {
        debugPrint('   Calculating XFile size...');
        fileSize = await file.length();
      } else if (file is Uint8List) {
        debugPrint('   Calculating Uint8List size...');
        fileSize = file.length;
      } else {
        debugPrint('   ❌ Unsupported file type for image upload');
        return null;
      }

      debugPrint('   File size: ${_getFileSize(fileSize)}');
      debugPrint('   Max allowed: ${_getFileSize(maxImageSize)}');

      if (!_validateFileSize(fileSize, maxImageSize)) {
        return null;
      }

      debugPrint('   ✅ Size validation passed');
      debugPrint('   Calling uploadFile()...');
      return await uploadFile(file, imagesBucket, folder, originalFileName: originalFileName);
    } catch (e, stackTrace) {
      debugPrint('   ❌ ERROR in uploadImage: $e');
      debugPrint('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Uploads an audio file (max 10 MB)
  Future<String?> uploadAudio(dynamic file, String folder, {String? originalFileName}) async {
    try {
      int fileSize;
      if (file is File) {
        fileSize = file.lengthSync();
      } else if (file is XFile) {
        fileSize = await file.length();
      } else if (file is Uint8List) {
        fileSize = file.length;
      } else {
        return null;
      }

      if (!_validateFileSize(fileSize, maxAudioSize)) {
        return null;
      }
      return uploadFile(file, audioBucket, folder, originalFileName: originalFileName);
    } catch (e) {
      debugPrint('❌ Error in uploadAudio: $e');
      return null;
    }
  }

  /// Uploads a video file (max 50 MB)
  Future<String?> uploadVideo(dynamic file, String folder, {String? originalFileName}) async {
    try {
      int fileSize;
      if (file is File) {
        fileSize = file.lengthSync();
      } else if (file is XFile) {
        fileSize = await file.length();
      } else if (file is Uint8List) {
        fileSize = file.length;
      } else {
        return null;
      }

      if (!_validateFileSize(fileSize, maxVideoSize)) {
        return null;
      }
      return uploadFile(file, videosBucket, folder, originalFileName: originalFileName);
    } catch (e) {
      debugPrint('❌ Error in uploadVideo: $e');
      return null;
    }
  }

  /// Uploads an export file (max 20 MB)
  Future<String?> uploadExport(dynamic file, String folder, {String? originalFileName}) async {
    try {
      int fileSize;
      if (file is File) {
        fileSize = file.lengthSync();
      } else if (file is XFile) {
        fileSize = await file.length();
      } else if (file is Uint8List) {
        fileSize = file.length;
      } else {
        return null;
      }

      if (!_validateFileSize(fileSize, maxExportSize)) {
        return null;
      }
      return uploadFile(file, exportsBucket, folder, originalFileName: originalFileName);
    } catch (e) {
      debugPrint('❌ Error in uploadExport: $e');
      return null;
    }
  }

  /// Generic upload method with cross-platform support (Web + Mobile)
  Future<String?> uploadFile(
    dynamic file, // Can be File (mobile) or XFile (web) or Uint8List
    String bucket,
    String folder, {
    Function(double)? onProgress,
    String? originalFileName, // NEW: Optional original filename for extension
  }) async {
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚀 UPLOAD STARTED');
      debugPrint('═══════════════════════════════════════');
      debugPrint('📦 Bucket: $bucket');
      debugPrint('📁 Folder: $folder');
      debugPrint('📄 File Type: ${file.runtimeType}');
      if (originalFileName != null) {
        debugPrint('📝 Original Filename: $originalFileName');
      }
      
      // Get current user ID for folder organization
      debugPrint('🔐 Checking authentication...');
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No authenticated user - cannot upload');
        return null;
      }
      debugPrint('✅ User authenticated: $userId');

      // Handle different file types (cross-platform)
      Uint8List fileBytes;
      String fileExtension;
      int fileSize;

      debugPrint('🔄 Processing file type: ${file.runtimeType}');

      if (file is File) {
        debugPrint('📱 Detected: dart:io File (Mobile)');
        try {
          debugPrint('   ➤ Reading file bytes...');
          fileBytes = await file.readAsBytes();
          debugPrint('   ✅ File bytes read: ${fileBytes.length} bytes');
          
          debugPrint('   ➤ Getting file extension...');
          fileExtension = path.extension(file.path);
          debugPrint('   ✅ Extension: $fileExtension');
          
          fileSize = fileBytes.length;
          debugPrint('   ✅ File size: ${_getFileSize(fileSize)}');
        } catch (e) {
          debugPrint('   ❌ ERROR reading File: $e');
          rethrow;
        }
      } else if (file is XFile) {
        debugPrint('🌐 Detected: XFile (Web/Cross-platform)');
        try {
          debugPrint('   ➤ Reading XFile bytes...');
          fileBytes = await file.readAsBytes();
          debugPrint('   ✅ XFile bytes read: ${fileBytes.length} bytes');
          
          debugPrint('   ➤ Getting file extension from name: ${file.name}');
          // ⚠️ CRITICAL: Use file.name instead of file.path for web compatibility
          fileExtension = path.extension(file.name);
          debugPrint('   ✅ Extension: $fileExtension');
          
          fileSize = fileBytes.length;
          debugPrint('   ✅ File size: ${_getFileSize(fileSize)}');
        } catch (e) {
          debugPrint('   ❌ ERROR reading XFile: $e');
          debugPrint('   Stack trace: ${StackTrace.current}');
          rethrow;
        }
      } else if (file is Uint8List) {
        debugPrint('💾 Detected: Uint8List (Raw bytes)');
        fileBytes = file;
        
        // Get extension from original filename if provided, otherwise default to .png
        if (originalFileName != null && originalFileName.isNotEmpty) {
          fileExtension = path.extension(originalFileName);
          debugPrint('   ✅ Using extension from original filename: $fileExtension');
        } else {
          fileExtension = '.png'; // Default extension
          debugPrint('   ⚠️ No filename provided, using default: $fileExtension');
        }
        
        fileSize = fileBytes.length;
        debugPrint('   ✅ Using raw bytes: ${_getFileSize(fileSize)}');
      } else {
        debugPrint('❌ UNSUPPORTED file type: ${file.runtimeType}');
        debugPrint('   Supported types: File, XFile, Uint8List');
        return null;
      }

      debugPrint('📤 Preparing upload...');
      debugPrint('   Size: ${_getFileSize(fileSize)}');

      // Generate unique filename
      debugPrint('🔧 Generating filename...');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp$fileExtension';
      debugPrint('   ✅ Filename: $fileName');
      
      // File structure: userId/folder/filename
      // This matches the RLS policy: (storage.foldername(name))[1] = auth.uid()::text
      debugPrint('🔧 Building file path...');
      final filePath = folder.isEmpty 
          ? '$userId/$fileName' 
          : '$userId/$folder/$fileName';
      debugPrint('   ✅ Full path: $filePath');

      // Upload to Supabase Storage using binary data
      debugPrint('☁️ Uploading to Supabase Storage...');
      debugPrint('   Bucket: $bucket');
      debugPrint('   Path: $filePath');
      debugPrint('   Bytes: ${fileBytes.length}');
      
      try {
        await _supabase.storage
            .from(bucket)
            .uploadBinary(
              filePath, 
              fileBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
        debugPrint('   ✅ Upload to storage successful!');
      } catch (e) {
        debugPrint('   ❌ ERROR during uploadBinary: $e');
        debugPrint('   Error type: ${e.runtimeType}');
        rethrow;
      }

      // Get public URL
      debugPrint('🔗 Generating public URL...');
      try {
        final publicUrl = _supabase.storage
            .from(bucket)
            .getPublicUrl(filePath);
        debugPrint('   ✅ Public URL generated: $publicUrl');
        
        debugPrint('═══════════════════════════════════════');
        debugPrint('✅ UPLOAD COMPLETED SUCCESSFULLY');
        debugPrint('═══════════════════════════════════════');
        
        return publicUrl;
      } catch (e) {
        debugPrint('   ❌ ERROR getting public URL: $e');
        rethrow;
      }
    } on StorageException catch (e) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ STORAGE EXCEPTION');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Message: ${e.message}');
      debugPrint('Status code: ${e.statusCode}');
      debugPrint('═══════════════════════════════════════');
      return null;
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ UNEXPECTED ERROR');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Error: $e');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('═══════════════════════════════════════');
      return null;
    }
  }

  /// Deletes a file from Supabase Storage
  /// [filePath] should be the full path including userId, e.g., 'user-id/images/filename.jpg'
  Future<bool> deleteFile(String bucket, String filePath) async {
    try {
      debugPrint('🗑️ Deleting: $bucket/$filePath');
      
      await _supabase.storage
          .from(bucket)
          .remove([filePath]);
      
      debugPrint('✅ File deleted successfully');
      return true;
    } on StorageException catch (e) {
      debugPrint('❌ Delete error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected delete error: $e');
      return false;
    }
  }

  /// Extracts file path from public URL for deletion
  /// Example: https://xxx.supabase.co/storage/v1/object/public/book-images/user-id/images/123.jpg
  /// Returns: user-id/images/123.jpg
  String? extractFilePathFromUrl(String publicUrl, String bucket) {
    try {
      final uri = Uri.parse(publicUrl);
      final segments = uri.pathSegments;
      
      // Find the bucket name in segments
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex == -1) return null;
      
      // Get everything after the bucket name
      final pathSegments = segments.sublist(bucketIndex + 1);
      return pathSegments.join('/');
    } catch (e) {
      debugPrint('❌ Error extracting file path: $e');
      return null;
    }
  }

  /// Get file metadata without downloading
  Future<FileObjectV2?> getFileInfo(String bucket, String filePath) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .info(filePath);
      
      return response;
    } catch (e) {
      debugPrint('❌ Error getting file info: $e');
      return null;
    }
  }

  /// Lists all files in a user's folder
  Future<List<FileObject>> listUserFiles(String bucket, String folder) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final path = folder.isEmpty ? userId : '$userId/$folder';
      
      final files = await _supabase.storage
          .from(bucket)
          .list(path: path);
      
      return files;
    } catch (e) {
      debugPrint('❌ Error listing files: $e');
      return [];
    }
  }

  /// Gets the total storage used by current user across all buckets
  Future<int> getTotalStorageUsed() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      int totalBytes = 0;

      // Check each bucket
      final buckets = [imagesBucket, audioBucket, videosBucket, exportsBucket];
      
      for (final bucket in buckets) {
        try {
          final files = await _supabase.storage
              .from(bucket)
              .list(path: userId);
          
          for (final file in files) {
            // Note: FileObject doesn't always have metadata.size
            // You may need to call info() for each file to get accurate sizes
            totalBytes += file.metadata?['size'] as int? ?? 0;
          }
        } catch (e) {
          debugPrint('⚠️ Could not access bucket $bucket: $e');
        }
      }

      debugPrint('💾 Total storage used: ${_getFileSize(totalBytes)}');
      return totalBytes;
    } catch (e) {
      debugPrint('❌ Error calculating storage: $e');
      return 0;
    }
  }

  /// Helper: Check if file is an image
  bool isImageFile(String filename) {
    final ext = path.extension(filename).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(ext);
  }

  /// Helper: Check if file is an audio file
  bool isAudioFile(String filename) {
    final ext = path.extension(filename).toLowerCase();
    return ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'].contains(ext);
  }

  /// Helper: Check if file is a video file
  bool isVideoFile(String filename) {
    final ext = path.extension(filename).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv'].contains(ext);
  }

  /// Helper: Check if file is a PDF
  bool isPdfFile(String filename) {
    return path.extension(filename).toLowerCase() == '.pdf';
  }
}
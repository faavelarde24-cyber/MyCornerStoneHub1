// lib/services/image_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_image.dart';

class ImageSearchService {
  static const String _pexelsApiKey = 'qDsmsoocymc7P6V82Z5bHQxxhamnRPQN8qvKwVQ9TYeo20bzmY5ZaImv';
  static const String _baseUrl = 'https://api.pexels.com/v1';

  Future<List<SearchImage>> searchImages(String query, {int perPage = 30}) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?query=$query&per_page=$perPage'),
        headers: {
          'Authorization': _pexelsApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['photos'] as List;
        return photos.map((photo) => SearchImage.fromPexels(photo)).toList();
      } else {
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching images: $e');
    }
  }
}
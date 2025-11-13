// lib/models/search_image.dart
class SearchImage {
  final String id;
  final String thumbnailUrl;
  final String fullUrl;
  final String photographer;
  final String photographerUrl;

  SearchImage({
    required this.id,
    required this.thumbnailUrl,
    required this.fullUrl,
    required this.photographer,
    required this.photographerUrl,
  });

  factory SearchImage.fromPexels(Map<String, dynamic> json) {
    return SearchImage(
      id: json['id'].toString(),
      thumbnailUrl: json['src']['medium'],
      fullUrl: json['src']['large2x'],
      photographer: json['photographer'],
      photographerUrl: json['photographer_url'],
    );
  }
}
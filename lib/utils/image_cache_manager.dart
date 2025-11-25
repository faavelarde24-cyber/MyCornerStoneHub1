import 'dart:ui' as ui;

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final Map<String, ui.Image> _cache = {};
  final int _maxCacheSize = 50; // Cache up to 50 images

  ui.Image? get(String url) => _cache[url];

  void put(String url, ui.Image image) {
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry
      _cache.remove(_cache.keys.first);
    }
    _cache[url] = image;
  }

  void clear() => _cache.clear();

  void remove(String url) => _cache.remove(url);
}
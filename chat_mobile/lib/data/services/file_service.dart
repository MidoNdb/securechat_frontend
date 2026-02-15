// lib/data/services/file_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileService extends GetxService {
  static const String _imagePrefix = 'image_msg_';
  static const String _voicePrefix = 'voice_msg_';
  static const String _filePrefix = 'file_msg_';

  Directory? _cacheDir;

  @override
  Future<void> onInit() async {
    super.onInit();
    _cacheDir = await getTemporaryDirectory();
  }

  Future<Directory> _ensureCacheDir() async {
    _cacheDir ??= await getTemporaryDirectory();
    return _cacheDir!;
  }

  Future<File> saveToCacheDir(
    Uint8List data,
    String messageId, {
    required String extension,
  }) async {
    final dir = await _ensureCacheDir();
    final prefix = _prefixForExtension(extension);
    final filePath = '${dir.path}/$prefix$messageId.$extension';
    final file = File(filePath);
    await file.writeAsBytes(data);
    return file;
  }

  Future<File> saveImageToCache(Uint8List imageData, String messageId, {
    String extension = 'jpg',
  }) async {
    return saveToCacheDir(imageData, messageId, extension: extension);
  }

  Future<File> saveVoiceToCache(Uint8List voiceData, String messageId) async {
    return saveToCacheDir(voiceData, messageId, extension: 'm4a');
  }

  Future<File?> getFromCache(String messageId) async {
    final dir = await _ensureCacheDir();

    for (final combo in _allPossibleFiles(messageId)) {
      final file = File('${dir.path}/$combo');
      if (await file.exists()) return file;
    }

    return null;
  }

  Future<File?> getImageFromCache(String messageId) async {
    final dir = await _ensureCacheDir();

    for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
      final file = File('${dir.path}/$_imagePrefix$messageId.$ext');
      if (await file.exists()) return file;
    }
    return null;
  }

  Future<File?> getVoiceFromCache(String messageId) async {
    final dir = await _ensureCacheDir();

    for (final ext in ['m4a', 'aac', 'mp3']) {
      final file = File('${dir.path}/$_voicePrefix$messageId.$ext');
      if (await file.exists()) return file;
    }
    return null;
  }

  Future<bool> existsInCache(String messageId) async {
    return (await getFromCache(messageId)) != null;
  }

  Future<void> deleteFromCache(String messageId) async {
    final dir = await _ensureCacheDir();

    for (final combo in _allPossibleFiles(messageId)) {
      final file = File('${dir.path}/$combo');
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> clearCache() async {
    final dir = await _ensureCacheDir();
    final files = dir.listSync();

    for (final file in files) {
      if (file is File && _isOurFile(file.path.split('/').last)) {
        await file.delete();
      }
    }
  }

  Future<Uint8List> compressImage(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1920,
    required int maxSizeKB,
  }) async {
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      if (compressed == null) throw Exception('Compression failed');
      return compressed;
    } catch (_) {
      return await imageFile.readAsBytes();
    }
  }

  Future<int> getCacheSize() async {
    final dir = await _ensureCacheDir();
    int totalSize = 0;

    for (final file in dir.listSync()) {
      if (file is File && _isOurFile(file.path.split('/').last)) {
        totalSize += await file.length();
      }
    }

    return totalSize;
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _prefixForExtension(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return _imagePrefix;
      case 'm4a':
      case 'aac':
      case 'mp3':
        return _voicePrefix;
      default:
        return _filePrefix;
    }
  }

  List<String> _allPossibleFiles(String messageId) {
    final prefixes = [_imagePrefix, _voicePrefix, _filePrefix];
    final extensions = [
      'jpg', 'jpeg', 'png', 'webp',
      'm4a', 'aac', 'mp3',
      'pdf', 'doc', 'docx',
    ];

    return [
      for (final prefix in prefixes)
        for (final ext in extensions)
          '$prefix$messageId.$ext',
    ];
  }

  bool _isOurFile(String fileName) {
    return fileName.startsWith(_imagePrefix) ||
        fileName.startsWith(_voicePrefix) ||
        fileName.startsWith(_filePrefix);
  }
}
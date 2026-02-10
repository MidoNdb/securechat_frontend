// lib/data/services/file_service.dart
// ✅ SERVICE DE GESTION FICHIERS CORRIGÉ - Support multi-types

import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileService extends GetxService {
  
  // ✅ CORRECTION : Préfixes par type de fichier
  static const String _imagePrefix = 'image_msg_';
  static const String _voicePrefix = 'voice_msg_';
  static const String _filePrefix = 'file_msg_';
  
  Directory? _cacheDir;
  
  // ==================== INITIALISATION ====================
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initCacheDirectory();
  }
  
  Future<void> _initCacheDirectory() async {
    try {
      _cacheDir = await getTemporaryDirectory();
      print('✅ Cache directory: ${_cacheDir?.path}');
    } catch (e) {
      print('❌ Erreur init cache: $e');
    }
  }
  
  // ==================== SAUVEGARDE FICHIERS ====================
  
  /// ✅ Sauvegarder un fichier dans le cache avec le bon préfixe selon le type
  Future<File> saveToCacheDir(
    Uint8List data,
    String messageId, {
    required String extension,
  }) async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      // ✅ Déterminer le préfixe selon l'extension
      String prefix;
      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png' || extension == 'webp') {
        prefix = _imagePrefix;
      } else if (extension == 'm4a' || extension == 'aac' || extension == 'mp3') {
        prefix = _voicePrefix;
      } else {
        prefix = _filePrefix;
      }
      
      // ✅ Construire le nom complet avec le BON préfixe et extension
      final fileName = '$prefix$messageId.$extension';
      final filePath = '${_cacheDir!.path}/$fileName';
      final file = File(filePath);
      
      // Écrire les données
      await file.writeAsBytes(data);
      
      final sizeKB = data.length / 1024;
      print('💾 Fichier sauvegardé: $fileName (${sizeKB.toStringAsFixed(2)} KB)');
      
      return file;
      
    } catch (e) {
      print('❌ Erreur saveToCacheDir: $e');
      rethrow;
    }
  }
  
  /// ✅ Sauvegarder un fichier image (alias pour compatibilité)
  Future<File> saveImageToCache(
    Uint8List imageData,
    String messageId, {
    String extension = 'jpg',
  }) async {
    return saveToCacheDir(imageData, messageId, extension: extension);
  }
  
  /// ✅ Sauvegarder un fichier vocal (alias pour compatibilité)
  Future<File> saveVoiceToCache(
    Uint8List voiceData,
    String messageId,
  ) async {
    return saveToCacheDir(voiceData, messageId, extension: 'm4a');
  }
  
  // ==================== RÉCUPÉRATION FICHIERS ====================
  
  /// ✅ Récupérer un fichier du cache (cherche tous les préfixes possibles)
  Future<File?> getFromCache(String messageId) async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      // ✅ Liste des combinaisons possibles (préfixe + extension)
      final possibleFiles = [
        // Images
        '${_imagePrefix}$messageId.jpg',
        '${_imagePrefix}$messageId.jpeg',
        '${_imagePrefix}$messageId.png',
        '${_imagePrefix}$messageId.webp',
        // Vocaux
        '${_voicePrefix}$messageId.m4a',
        '${_voicePrefix}$messageId.aac',
        '${_voicePrefix}$messageId.mp3',
        // Fichiers
        '${_filePrefix}$messageId.pdf',
        '${_filePrefix}$messageId.doc',
        '${_filePrefix}$messageId.docx',
      ];
      
      // Chercher le premier fichier qui existe
      for (final fileName in possibleFiles) {
        final filePath = '${_cacheDir!.path}/$fileName';
        final file = File(filePath);
        
        if (await file.exists()) {
          print('✅ Fichier trouvé en cache: $fileName');
          return file;
        }
      }
      
      print('⚠️ Fichier non trouvé en cache: $messageId');
      return null;
      
    } catch (e) {
      print('❌ Erreur getFromCache: $e');
      return null;
    }
  }
  
  /// ✅ Récupérer une image du cache (méthode spécifique)
  Future<File?> getImageFromCache(String messageId) async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      final extensions = ['jpg', 'jpeg', 'png', 'webp'];
      
      for (final ext in extensions) {
        final fileName = '$_imagePrefix$messageId.$ext';
        final filePath = '${_cacheDir!.path}/$fileName';
        final file = File(filePath);
        
        if (await file.exists()) {
          print('✅ Image trouvée: $fileName');
          return file;
        }
      }
      
      print('! Image non trouvée en cache: ${_imagePrefix}$messageId');
      return null;
      
    } catch (e) {
      print('❌ Erreur getImageFromCache: $e');
      return null;
    }
  }
  
  /// ✅ Récupérer un vocal du cache (méthode spécifique)
  Future<File?> getVoiceFromCache(String messageId) async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      final extensions = ['m4a', 'aac', 'mp3'];
      
      for (final ext in extensions) {
        final fileName = '$_voicePrefix$messageId.$ext';
        final filePath = '${_cacheDir!.path}/$fileName';
        final file = File(filePath);
        
        if (await file.exists()) {
          print('✅ Vocal trouvé: $fileName');
          return file;
        }
      }
      
      print('! Vocal non trouvé en cache: ${_voicePrefix}$messageId');
      return null;
      
    } catch (e) {
      print('❌ Erreur getVoiceFromCache: $e');
      return null;
    }
  }
  
  // ==================== VÉRIFICATION EXISTENCE ====================
  
  /// Vérifier si un fichier existe en cache
  Future<bool> existsInCache(String messageId) async {
    final file = await getFromCache(messageId);
    return file != null;
  }
  
  // ==================== SUPPRESSION ====================
  
  /// Supprimer un fichier du cache
  Future<void> deleteFromCache(String messageId) async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      // Chercher et supprimer tous les fichiers correspondants
      final possiblePrefixes = [_imagePrefix, _voicePrefix, _filePrefix];
      final possibleExtensions = ['jpg', 'jpeg', 'png', 'webp', 'm4a', 'aac', 'mp3', 'pdf', 'doc', 'docx'];
      
      for (final prefix in possiblePrefixes) {
        for (final ext in possibleExtensions) {
          final fileName = '$prefix$messageId.$ext';
          final filePath = '${_cacheDir!.path}/$fileName';
          final file = File(filePath);
          
          if (await file.exists()) {
            await file.delete();
            print('🗑️ Fichier supprimé: $fileName');
          }
        }
      }
      
    } catch (e) {
      print('❌ Erreur deleteFromCache: $e');
    }
  }
  
  /// Nettoyer tout le cache
  Future<void> clearCache() async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      final files = _cacheDir!.listSync();
      int deletedCount = 0;
      
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          
          // Supprimer uniquement nos fichiers (avec nos préfixes)
          if (fileName.startsWith(_imagePrefix) || 
              fileName.startsWith(_voicePrefix) || 
              fileName.startsWith(_filePrefix)) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      print('🗑️ Cache nettoyé: $deletedCount fichier(s) supprimé(s)');
      
    } catch (e) {
      print('❌ Erreur clearCache: $e');
    }
  }
  
  /// Nettoyer le cache par préfixe
  Future<void> clearCacheByPrefix(String prefix) async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      final files = _cacheDir!.listSync();
      int deletedCount = 0;
      
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          
          if (fileName.startsWith(prefix)) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      print('🗑️ Cache nettoyé ($prefix): $deletedCount fichier(s) supprimé(s)');
      
    } catch (e) {
      print('❌ Erreur clearCacheByPrefix: $e');
    }
  }
  
  // ==================== COMPRESSION IMAGES ====================
  
  /// Compresser une image (utile pour les images)
  Future<Uint8List> compressImage(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1920, required int maxSizeKB,
  }) async {
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );
      
      if (compressed == null) {
        throw Exception('Compression failed');
      }
      
      final originalSize = await imageFile.length();
      final compressedSize = compressed.length;
      final ratio = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
      
      print('🗜️ Image compressée: ${originalSize ~/ 1024} KB → ${compressedSize ~/ 1024} KB (-$ratio%)');
      
      return compressed;
      
    } catch (e) {
      print('❌ Erreur compression: $e');
      // Retourner l'image originale en cas d'erreur
      return await imageFile.readAsBytes();
    }
  }
  
  // ==================== STATISTIQUES ====================
  
  /// Obtenir la taille du cache
  Future<int> getCacheSize() async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      int totalSize = 0;
      final files = _cacheDir!.listSync();
      
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          
          if (fileName.startsWith(_imagePrefix) || 
              fileName.startsWith(_voicePrefix) || 
              fileName.startsWith(_filePrefix)) {
            totalSize += await file.length();
          }
        }
      }
      
      return totalSize;
      
    } catch (e) {
      print('❌ Erreur getCacheSize: $e');
      return 0;
    }
  }
  
  /// Formater la taille en MB
  String formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  // ==================== UTILITAIRES ====================
  
  /// Sauvegarder un fichier générique (ancienne API, pour compatibilité)
  @Deprecated('Utiliser saveToCacheDir à la place')
  Future<void> saveFile({
    required String fileName,
    required Uint8List data,
  }) async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      final filePath = '${_cacheDir!.path}/$fileName';
      final file = File(filePath);
      
      await file.writeAsBytes(data);
      
      final sizeKB = data.length / 1024;
      print('💾 Fichier sauvegardé: $fileName (${sizeKB.toStringAsFixed(2)} KB)');
      
    } catch (e) {
      print('❌ Erreur saveFile: $e');
      rethrow;
    }
  }
  
  /// Récupérer un fichier générique (ancienne API, pour compatibilité)
  @Deprecated('Utiliser getFromCache à la place')
  Future<File?> getFile(String fileName) async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      final filePath = '${_cacheDir!.path}/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        print('✅ Fichier trouvé: $fileName');
        return file;
      }
      
      print('! Fichier non trouvé: $fileName');
      return null;
      
    } catch (e) {
      print('❌ Erreur getFile: $e');
      return null;
    }
  }
  
  /// Supprimer un fichier générique (ancienne API, pour compatibilité)
  @Deprecated('Utiliser deleteFromCache à la place')
  Future<void> deleteFile(String fileName) async {
    try {
      if (_cacheDir == null) {
        await _initCacheDirectory();
      }
      
      final filePath = '${_cacheDir!.path}/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Fichier supprimé: $fileName');
      }
      
    } catch (e) {
      print('❌ Erreur deleteFile: $e');
    }
  }
}


// // lib/data/services/file_service.dart

// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;

// /// Service pour gestion des fichiers (compression, cache, etc.)
// class FileService {
  
//   // ==================== COMPRESSION IMAGE ====================
  
//   /// Compresse une image pour réduire sa taille
//   /// 
//   /// Objectif: Réduire à ~500KB max tout en gardant qualité acceptable
//   /// 
//   /// Paramètres:
//   /// - imageFile: Fichier image original
//   /// - maxSizeKB: Taille maximale en KB (défaut: 500)
//   /// - quality: Qualité JPEG 1-100 (défaut: 85)
//   /// 
//   /// Retourne: Bytes de l'image compressée
//   Future<Uint8List> compressImage(
//     File imageFile, {
//     int maxSizeKB = 500,
//     int quality = 85,
//   }) async {
//     try {
//       print('🗜️ Compression image...');
      
//       // Taille originale
//       final originalSize = await imageFile.length();
//       print('   Taille originale: ${originalSize / 1024} KB');
      
//       // Si déjà petite, pas de compression
//       if (originalSize < maxSizeKB * 1024) {
//         print('   ✅ Image déjà petite, pas de compression');
//         return await imageFile.readAsBytes();
//       }
      
//       // Compression
//       final compressedBytes = await FlutterImageCompress.compressWithFile(
//         imageFile.absolute.path,
//         quality: quality,
//         format: CompressFormat.jpeg, // Toujours JPEG (meilleure compression)
//       );
      
//       if (compressedBytes == null) {
//         throw Exception('Échec compression image');
//       }
      
//       print('   ✅ Compressée: ${compressedBytes.length / 1024} KB');
//       print('   Réduction: ${((1 - compressedBytes.length / originalSize) * 100).toStringAsFixed(1)}%');
      
//       // Si encore trop grande, réduire qualité
//       if (compressedBytes.length > maxSizeKB * 1024 && quality > 50) {
//         print('   ⚠️ Encore trop grande, réduction qualité...');
//         return await compressImage(
//           imageFile,
//           maxSizeKB: maxSizeKB,
//           quality: quality - 15,
//         );
//       }
      
//       return Uint8List.fromList(compressedBytes);
      
//     } catch (e) {
//       print('❌ Erreur compression image: $e');
//       // Fallback: retourner image originale
//       return await imageFile.readAsBytes();
//     }
//   }
  
//   // ==================== CACHE LOCAL ====================
  
//   /// Sauvegarde des bytes dans le cache local
//   /// 
//   /// Utilise le dossier temporaire du système
//   /// Format: image_msg_{messageId}.jpg
//   Future<File> saveToCacheDir(
//     Uint8List bytes,
//     String messageId, {
//     String extension = 'jpg',
//   }) async {
//     try {
//       // Récupérer dossier cache
//       final tempDir = await getTemporaryDirectory();
      
//       // Créer sous-dossier messages si nécessaire
//       final messagesDir = Directory('${tempDir.path}/messages');
//       if (!await messagesDir.exists()) {
//         await messagesDir.create(recursive: true);
//       }
      
//       // Nom fichier
//       final filename = 'image_msg_$messageId.$extension';
//       final filePath = '${messagesDir.path}/$filename';
      
//       // Écrire fichier
//       final file = File(filePath);
//       await file.writeAsBytes(bytes);
      
//       print('💾 Image sauvegardée: $filename (${bytes.length / 1024} KB)');
      
//       return file;
      
//     } catch (e) {
//       throw Exception('Erreur sauvegarde cache: $e');
//     }
//   }
  
//   /// Récupère un fichier depuis le cache
//   Future<File?> getFromCache(
//     String messageId, {
//     String extension = 'jpg',
//   }) async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final filename = 'image_msg_$messageId.$extension';
//       final filePath = '${tempDir.path}/messages/$filename';
      
//       final file = File(filePath);
      
//       if (await file.exists()) {
//         print('✅ Image trouvée en cache: $filename');
//         return file;
//       }
      
//       print('⚠️ Image non trouvée en cache: $filename');
//       return null;
      
//     } catch (e) {
//       print('❌ Erreur lecture cache: $e');
//       return null;
//     }
//   }
  
//   /// Vérifie si un fichier existe en cache
//   Future<bool> existsInCache(
//     String messageId, {
//     String extension = 'jpg',
//   }) async {
//     final file = await getFromCache(messageId, extension: extension);
//     return file != null;
//   }
  
//   /// Supprime un fichier du cache
//   Future<void> deleteFromCache(
//     String messageId, {
//     String extension = 'jpg',
//   }) async {
//     try {
//       final file = await getFromCache(messageId, extension: extension);
//       if (file != null && await file.exists()) {
//         await file.delete();
//         print('🗑️ Image supprimée du cache: $messageId');
//       }
//     } catch (e) {
//       print('❌ Erreur suppression cache: $e');
//     }
//   }
  
//   // ==================== NETTOYAGE CACHE ====================
  
//   /// Nettoie les fichiers cache trop vieux
//   /// 
//   /// Par défaut: supprime fichiers > 7 jours
//   Future<void> cleanOldCache({int daysOld = 7}) async {
//     try {
//       print('🧹 Nettoyage cache...');
      
//       final tempDir = await getTemporaryDirectory();
//       final messagesDir = Directory('${tempDir.path}/messages');
      
//       if (!await messagesDir.exists()) {
//         return;
//       }
      
//       final now = DateTime.now();
//       int deletedCount = 0;
      
//       await for (final entity in messagesDir.list()) {
//         if (entity is File) {
//           final stat = await entity.stat();
//           final age = now.difference(stat.modified).inDays;
          
//           if (age > daysOld) {
//             await entity.delete();
//             deletedCount++;
//           }
//         }
//       }
      
//       print('✅ Cache nettoyé: $deletedCount fichiers supprimés');
      
//     } catch (e) {
//       print('❌ Erreur nettoyage cache: $e');
//     }
//   }
  
//   /// Calcule la taille totale du cache
//   Future<int> getCacheSize() async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final messagesDir = Directory('${tempDir.path}/messages');
      
//       if (!await messagesDir.exists()) {
//         return 0;
//       }
      
//       int totalSize = 0;
      
//       await for (final entity in messagesDir.list()) {
//         if (entity is File) {
//           final stat = await entity.stat();
//           totalSize += stat.size;
//         }
//       }
      
//       return totalSize;
      
//     } catch (e) {
//       print('❌ Erreur calcul taille cache: $e');
//       return 0;
//     }
//   }
  
//   /// Vide complètement le cache
//   Future<void> clearAllCache() async {
//     try {
//       print('🗑️ Vidage cache complet...');
      
//       final tempDir = await getTemporaryDirectory();
//       final messagesDir = Directory('${tempDir.path}/messages');
      
//       if (await messagesDir.exists()) {
//         await messagesDir.delete(recursive: true);
//         print('✅ Cache vidé');
//       }
      
//     } catch (e) {
//       print('❌ Erreur vidage cache: $e');
//     }
//   }
  
//   // ==================== UTILITAIRES ====================
  
//   /// Récupère l'extension d'un fichier
//   String getFileExtension(String filePath) {
//     return path.extension(filePath).toLowerCase().replaceAll('.', '');
//   }
  
//   /// Récupère le nom du fichier sans extension
//   String getFileNameWithoutExtension(String filePath) {
//     return path.basenameWithoutExtension(filePath);
//   }
  
//   /// Formate une taille en bytes vers un format lisible
//   String formatFileSize(int bytes) {
//     if (bytes < 1024) {
//       return '$bytes B';
//     } else if (bytes < 1024 * 1024) {
//       return '${(bytes / 1024).toStringAsFixed(1)} KB';
//     } else {
//       return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
//     }
//   }
// }
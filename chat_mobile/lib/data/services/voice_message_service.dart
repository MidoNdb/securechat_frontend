// lib/data/services/voice_message_service.dart
// ✅ Service complet pour messages vocaux E2EE

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/message.dart';
import 'crypto_service.dart';
import 'file_service.dart';
import 'secure_storage_service.dart';
import '../api/dio_client.dart';
import '../api/api_endpoints.dart';

class VoiceMessageService extends GetxService {
  final CryptoService _crypto = Get.find<CryptoService>();
  final FileService _fileService = Get.find<FileService>();
  final SecureStorageService _storage = Get.find<SecureStorageService>();
  final DioClient _dio = Get.find<DioClient>();
  
  late final AudioRecorder _recorder;
  
  // États observables
  final isRecording = false.obs;
  final recordingDuration = 0.obs;
  final currentAmplitude = 0.0.obs;
  
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  
  // ==================== INITIALISATION ====================
  
  @override
  void onInit() {
    super.onInit();
    _recorder = AudioRecorder();
    print('✅ VoiceMessageService initialisé');
  }
  
  @override
  void onClose() {
    _recorder.dispose();
    super.onClose();
  }
  
  // ==================== ENREGISTREMENT ====================
  
  /// Démarrer l'enregistrement audio
  Future<bool> startRecording() async {
    try {
      // 1. Vérifier permissions
      if (!await _recorder.hasPermission()) {
        print('❌ Permission microphone refusée');
        return false;
      }
      
      // 2. Préparer le fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/voice_$timestamp.m4a';
      
      // 3. Configuration de l'enregistrement
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // AAC pour compression
        bitRate: 128000,             // 128 kbps
        sampleRate: 44100,           // 44.1 kHz
        numChannels: 1,              // Mono
      );
      
      // 4. Démarrer l'enregistrement
      await _recorder.start(
        config,
        path: _currentRecordingPath!,
      );
      
      isRecording.value = true;
      _recordingStartTime = DateTime.now();
      recordingDuration.value = 0;
      
      // 5. Timer pour mise à jour durée
      _startDurationTimer();
      
      // 6. Stream amplitude (pour animation)
      _startAmplitudeStream();
      
      print('🎤 Enregistrement démarré: $_currentRecordingPath');
      return true;
      
    } catch (e) {
      print('❌ Erreur startRecording: $e');
      isRecording.value = false;
      return false;
    }
  }
  
  /// Arrêter l'enregistrement et retourner le fichier
  Future<File?> stopRecording() async {
    try {
      if (!isRecording.value) {
        return null;
      }
      
      // 1. Arrêter l'enregistrement
      final path = await _recorder.stop();
      
      isRecording.value = false;
      _recordingStartTime = null;
      
      if (path == null) {
        print('❌ Enregistrement annulé');
        return null;
      }
      
      // 2. Vérifier le fichier
      final file = File(path);
      
      if (!await file.exists()) {
        print('❌ Fichier audio introuvable');
        return null;
      }
      
      final fileSize = await file.length();
      print('🎤 Enregistrement terminé: ${fileSize ~/ 1024} KB, ${recordingDuration.value}s');
      
      return file;
      
    } catch (e) {
      print('❌ Erreur stopRecording: $e');
      isRecording.value = false;
      return null;
    }
  }
  
  /// Annuler l'enregistrement en cours
  Future<void> cancelRecording() async {
    try {
      if (isRecording.value) {
        await _recorder.stop();
        isRecording.value = false;
        _recordingStartTime = null;
        recordingDuration.value = 0;
        
        // Supprimer le fichier temporaire
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        
        print('🗑️ Enregistrement annulé');
      }
    } catch (e) {
      print('❌ Erreur cancelRecording: $e');
    }
  }
  
  // ==================== ENVOI MESSAGE VOCAL ====================
  
  /// Envoyer un message vocal chiffré E2EE
  Future<Message> sendVoice({
    required String conversationId,
    required String recipientUserId,
    required File voiceFile,
  }) async {
    try {
      // 1. Lire les bytes du fichier audio
      final voiceBytes = await voiceFile.readAsBytes();
      
      // 2. Extraire métadonnées
      final metadata = await _extractVoiceMetadata(voiceFile, voiceBytes);
      
      // 3. Récupérer clés E2EE
      final myDhPrivateKey = await _storage.getDHPrivateKey();
      final mySignPrivateKey = await _storage.getSignPrivateKey();
      
      if (myDhPrivateKey == null || mySignPrivateKey == null) {
        throw Exception('Clés E2EE manquantes');
      }
      
      // 4. Récupérer clés publiques destinataire
      final recipientKeys = await _getRecipientPublicKeys(recipientUserId);
      
      // 5. Convertir en Base64
      final base64Voice = base64Encode(voiceBytes);
      
      // 6. Chiffrement E2EE
      final encrypted = await _crypto.encryptMessage(
        plaintext: base64Voice,
        myDhPrivateKeyB64: myDhPrivateKey,
        theirDhPublicKeyB64: recipientKeys['dh_public_key']!,
        mySignPrivateKeyB64: mySignPrivateKey,
      );
      
      // 7. Préparation requête
      final payload = {
        'conversation_id': conversationId,
        'recipient_user_id': recipientUserId,
        'type': 'VOICE',
        'encrypted_content': encrypted['ciphertext']!,
        'nonce': encrypted['nonce']!,
        'auth_tag': encrypted['auth_tag']!,
        'signature': encrypted['signature']!,
        'metadata': metadata,
      };
      
      // 8. Envoi HTTP
      final response = await _dio.privateDio.post(
        ApiEndpoints.sendMessage,
        data: payload,
      );
      
      // 9. Extraction message
      final messageData = response.data['data'] as Map<String, dynamic>;
      final message = Message.fromJson(messageData);
      
      // 10. Sauvegarder en cache
      await _fileService.saveToCacheDir(
        voiceBytes,
        message.id,
        extension: 'm4a',
      );
      
      print('✅ Message vocal envoyé: ${message.id}');
      
      // 11. Supprimer fichier temporaire
      if (await voiceFile.exists()) {
        await voiceFile.delete();
      }
      
      return message;
      
    } catch (e) {
      print('❌ Erreur sendVoice: $e');
      rethrow;
    }
  }
  
  // ==================== RÉCEPTION MESSAGE VOCAL ====================
  
  /// Déchiffrer un message vocal reçu
  Future<File> decryptVoice(Message message) async {
    try {
      // 1. Vérifier cache
      final cachedFile = await _fileService.getFromCache(message.id);
      if (cachedFile != null) {
        return cachedFile;
      }
      
      // 2. Récupérer clés E2EE locales
      final myDhPrivateKey = await _storage.getDHPrivateKey();
      
      if (myDhPrivateKey == null) {
        throw Exception('Clé DH manquante');
      }
      
      // 3. ✅ CORRECTION: Utiliser recipientUserId pour récupérer les bonnes clés
      // Si c'est MON message → utiliser mes clés publiques
      // Si c'est un message REÇU → utiliser les clés de l'expéditeur
      final currentUserId = await _storage.getUserId();
      final isMyMessage = message.senderId == currentUserId;
      
      String keyUserId;
      if (isMyMessage && message.recipientUserId != null) {
        // Mon message → déchiffrer avec les clés du destinataire
        keyUserId = message.recipientUserId!;
      } else {
        // Message reçu → déchiffrer avec les clés de l'expéditeur
        keyUserId = message.senderId;
      }
      
      final otherKeys = await _getRecipientPublicKeys(keyUserId);
      
      // 4. Déchiffrement E2EE
      final decryptedBase64 = await _crypto.decryptMessage(
        ciphertextB64: message.encryptedContent,
        nonceB64: message.nonce!,
        authTagB64: message.authTag!,
        signatureB64: message.signature!,
        myDhPrivateKeyB64: myDhPrivateKey,
        theirDhPublicKeyB64: otherKeys['dh_public_key']!,
        theirSignPublicKeyB64: otherKeys['sign_public_key']!,
      );
      
      // 5. Décoder Base64
      final voiceBytes = base64Decode(decryptedBase64);
      
      // 6. Sauvegarder en cache
      final file = await _fileService.saveToCacheDir(
        Uint8List.fromList(voiceBytes),
        message.id,
        extension: 'm4a',
      );
      
      print('✅ Message vocal déchiffré: ${message.id}');
      
      return file;
      
    } catch (e) {
      print('❌ Erreur decryptVoice: $e');
      rethrow;
    }
  }
  
  // ==================== MÉTADONNÉES ====================
  
  Future<Map<String, dynamic>> _extractVoiceMetadata(
    File voiceFile,
    Uint8List voiceBytes,
  ) async {
    try {
      final duration = recordingDuration.value;
      
      return {
        'duration': duration,
        'size': voiceBytes.length,
        'format': 'm4a',
        'codec': 'aac',
        'bitrate': 128000,
        'sample_rate': 44100,
        'channels': 1,
        'original_name': voiceFile.path.split('/').last,
      };
      
    } catch (e) {
      return {
        'size': voiceBytes.length,
        'format': 'm4a',
      };
    }
  }
  
  // ==================== RÉCUPÉRATION CLÉS ====================
  
  Future<Map<String, String>> _getRecipientPublicKeys(String userId) async {
    try {
      final response = await _dio.privateDio.get(
        ApiEndpoints.getPublicKeys(userId),
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        
        return {
          'dh_public_key': data['dh_public_key'] as String,
          'sign_public_key': data['sign_public_key'] as String,
        };
      }
      
      throw Exception('Error ${response.statusCode}');
      
    } catch (e) {
      print('❌ Erreur récupération clés: $e');
      rethrow;
    }
  }
  
  // ==================== HELPERS PRIVÉS ====================
  
  void _startDurationTimer() {
    Future.doWhile(() async {
      if (!isRecording.value) return false;
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (isRecording.value && _recordingStartTime != null) {
        recordingDuration.value = 
          DateTime.now().difference(_recordingStartTime!).inSeconds;
      }
      
      return isRecording.value;
    });
  }
  
  void _startAmplitudeStream() {
    _recorder.onAmplitudeChanged(const Duration(milliseconds: 200))
      .listen((amplitude) {
        if (isRecording.value) {
          // Normaliser entre 0 et 1
          currentAmplitude.value = (amplitude.current + 50) / 50;
          currentAmplitude.value = currentAmplitude.value.clamp(0.0, 1.0);
        }
      });
  }
  
  // ==================== UTILITAIRES ====================
  
  /// Vérifier si un message vocal est en cache
  Future<bool> isVoiceCached(String messageId) async {
    return await _fileService.existsInCache(messageId);
  }
  
  /// Supprimer un message vocal du cache
  Future<void> deleteVoiceFromCache(String messageId) async {
    await _fileService.deleteFromCache(messageId);
  }
  
  /// Formater la durée en MM:SS
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  /// Vérifier si on peut enregistrer
  Future<bool> hasRecordPermission() async {
    return await _recorder.hasPermission();
  }
}


// lib/data/services/voice_message_service.dart

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

  final isRecording = false.obs;
  final recordingDuration = 0.obs;
  final currentAmplitude = 0.0.obs;

  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  // Cache des clés publiques (même pattern que MessageService)
  final Map<String, _CachedKeys> _publicKeysCache = {};

  @override
  void onInit() {
    super.onInit();
    _recorder = AudioRecorder();
  }

  @override
  void onClose() {
    _recorder.dispose();
    super.onClose();
  }

  Future<bool> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) return false;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/voice_$timestamp.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );

      await _recorder.start(config, path: _currentRecordingPath!);

      isRecording.value = true;
      _recordingStartTime = DateTime.now();
      recordingDuration.value = 0;

      _startDurationTimer();
      _startAmplitudeStream();

      return true;
    } catch (e) {
      isRecording.value = false;
      return false;
    }
  }

  Future<File?> stopRecording() async {
    try {
      if (!isRecording.value) return null;

      final path = await _recorder.stop();

      isRecording.value = false;
      _recordingStartTime = null;

      if (path == null) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      return file;
    } catch (e) {
      isRecording.value = false;
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (!isRecording.value) return;

      await _recorder.stop();
      isRecording.value = false;
      _recordingStartTime = null;
      recordingDuration.value = 0;

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
  }

  Future<Message> sendVoice({
    required String conversationId,
    required String recipientUserId,
    required File voiceFile,
  }) async {
    final voiceBytes = await voiceFile.readAsBytes();
    final metadata = _buildMetadata(voiceFile, voiceBytes);

    final myDhPrivateKey = await _storage.getDHPrivateKey();
    final mySignPrivateKey = await _storage.getSignPrivateKey();

    if (myDhPrivateKey == null || mySignPrivateKey == null) {
      throw Exception('Clés E2EE manquantes');
    }

    final recipientKeys = await _getPublicKeysCached(recipientUserId);
    final base64Voice = base64Encode(voiceBytes);

    // Chiffrement E2EE (utilise Isolate via CryptoService si pas en cache)
    final encrypted = await _crypto.encryptMessage(
      plaintext: base64Voice,
      myDhPrivateKeyB64: myDhPrivateKey,
      theirDhPublicKeyB64: recipientKeys['dh_public_key']!,
      mySignPrivateKeyB64: mySignPrivateKey,
    );

    final response = await _dio.privateDio.post(
      ApiEndpoints.sendMessage,
      data: {
        'conversation_id': conversationId,
        'recipient_user_id': recipientUserId,
        'type': 'VOICE',
        'encrypted_content': encrypted['ciphertext']!,
        'nonce': encrypted['nonce']!,
        'auth_tag': encrypted['auth_tag']!,
        'signature': encrypted['signature']!,
        'metadata': metadata,
      },
    );

    final message = Message.fromJson(response.data['data'] as Map<String, dynamic>);

    // Sauvegarder en cache
    await _fileService.saveToCacheDir(voiceBytes, message.id, extension: 'm4a');

    // Supprimer fichier temporaire
    if (await voiceFile.exists()) await voiceFile.delete();

    return message;
  }

  Future<File> decryptVoice(Message message) async {
    // Vérifier cache fichier
    final cachedFile = await _fileService.getFromCache(message.id);
    if (cachedFile != null) return cachedFile;

    final myDhPrivateKey = await _storage.getDHPrivateKey();
    if (myDhPrivateKey == null) throw Exception('Clé DH manquante');

    final currentUserId = await _storage.getUserId();
    final isMyMessage = message.senderId == currentUserId;

    // Déterminer les bonnes clés (même logique que MessageService)
    String dhKeyUserId;
    String signKeyUserId;

    if (isMyMessage && message.recipientUserId != null) {
      dhKeyUserId = message.recipientUserId!;
      signKeyUserId = currentUserId!;
    } else {
      dhKeyUserId = message.senderId;
      signKeyUserId = message.senderId;
    }

    final dhKeys = await _getPublicKeysCached(dhKeyUserId);
    final signKeys = dhKeyUserId == signKeyUserId
        ? dhKeys
        : await _getPublicKeysCached(signKeyUserId);

    // Déchiffrement (Isolate si premier message de cette conversation)
    final decryptedBase64 = await _crypto.decryptMessage(
      ciphertextB64: message.encryptedContent,
      nonceB64: message.nonce!,
      authTagB64: message.authTag!,
      signatureB64: message.signature!,
      myDhPrivateKeyB64: myDhPrivateKey,
      theirDhPublicKeyB64: dhKeys['dh_public_key']!,
      theirSignPublicKeyB64: signKeys['sign_public_key']!,
    );

    final voiceBytes = base64Decode(decryptedBase64);

    return await _fileService.saveToCacheDir(
      Uint8List.fromList(voiceBytes),
      message.id,
      extension: 'm4a',
    );
  }

  Future<Map<String, String>> _getPublicKeysCached(String userId) async {
    final cached = _publicKeysCache[userId];
    if (cached != null && !cached.isExpired) return cached.keys;

    final response = await _dio.privateDio.get(
      ApiEndpoints.getPublicKeys(userId),
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] as Map<String, dynamic>;
      final keys = {
        'dh_public_key': data['dh_public_key'] as String,
        'sign_public_key': data['sign_public_key'] as String,
      };

      _publicKeysCache[userId] = _CachedKeys(
        keys: keys,
        fetchedAt: DateTime.now(),
      );
      return keys;
    }

    throw Exception('Erreur récupération clés');
  }

  Map<String, dynamic> _buildMetadata(File voiceFile, Uint8List voiceBytes) {
    return {
      'duration': recordingDuration.value,
      'size': voiceBytes.length,
      'format': 'm4a',
      'codec': 'aac',
      'bitrate': 128000,
      'sample_rate': 44100,
      'channels': 1,
      'original_name': voiceFile.path.split('/').last,
    };
  }

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
    _recorder.onAmplitudeChanged(const Duration(milliseconds: 200)).listen(
      (amplitude) {
        if (isRecording.value) {
          currentAmplitude.value = ((amplitude.current + 50) / 50).clamp(0.0, 1.0);
        }
      },
    );
  }

  Future<bool> isVoiceCached(String messageId) async {
    return await _fileService.existsInCache(messageId);
  }

  Future<void> deleteVoiceFromCache(String messageId) async {
    await _fileService.deleteFromCache(messageId);
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<bool> hasRecordPermission() async {
    return await _recorder.hasPermission();
  }
}

class _CachedKeys {
  final Map<String, String> keys;
  final DateTime fetchedAt;
  _CachedKeys({required this.keys, required this.fetchedAt});
  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > const Duration(minutes: 30);
}
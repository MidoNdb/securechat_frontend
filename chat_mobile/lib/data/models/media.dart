// lib/data/models/media.dart

class Media {
  final int id;
  final int messageId;
  final String type; // image, video, audio, document
  final String? url;
  final String? localPath;
  final String? thumbnailUrl;
  final int? fileSize;
  final String? fileName;
  final String? mimeType;
  final int? duration; // Pour audio/vidéo en secondes
  final int? width; // Pour images/vidéos
  final int? height; // Pour images/vidéos
  final String? encryptedFileUrl;
  final bool isDownloaded;

  Media({
    required this.id,
    required this.messageId,
    required this.type,
    this.url,
    this.localPath,
    this.thumbnailUrl,
    this.fileSize,
    this.fileName,
    this.mimeType,
    this.duration,
    this.width,
    this.height,
    this.encryptedFileUrl,
    this.isDownloaded = false,
  });

  // Obtenir la taille formatée
  String get formattedSize {
    if (fileSize == null) return '';
    
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Obtenir la durée formatée (pour audio/vidéo)
  String get formattedDuration {
    if (duration == null) return '';
    
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'],
      messageId: json['message_id'],
      type: json['type'],
      url: json['url'],
      localPath: json['local_path'],
      thumbnailUrl: json['thumbnail_url'],
      fileSize: json['file_size'],
      fileName: json['file_name'],
      mimeType: json['mime_type'],
      duration: json['duration'],
      width: json['width'],
      height: json['height'],
      encryptedFileUrl: json['encrypted_file_url'],
      isDownloaded: json['is_downloaded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'type': type,
      'url': url,
      'local_path': localPath,
      'thumbnail_url': thumbnailUrl,
      'file_size': fileSize,
      'file_name': fileName,
      'mime_type': mimeType,
      'duration': duration,
      'width': width,
      'height': height,
      'encrypted_file_url': encryptedFileUrl,
      'is_downloaded': isDownloaded,
    };
  }

  Media copyWith({
    int? id,
    int? messageId,
    String? type,
    String? url,
    String? localPath,
    String? thumbnailUrl,
    int? fileSize,
    String? fileName,
    String? mimeType,
    int? duration,
    int? width,
    int? height,
    String? encryptedFileUrl,
    bool? isDownloaded,
  }) {
    return Media(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      type: type ?? this.type,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSize: fileSize ?? this.fileSize,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      encryptedFileUrl: encryptedFileUrl ?? this.encryptedFileUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
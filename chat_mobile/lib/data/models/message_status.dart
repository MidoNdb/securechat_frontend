// lib/data/models/message_status.dart

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  String get value {
    switch (this) {
      case MessageStatus.sending: return 'sending';
      case MessageStatus.sent: return 'sent';
      case MessageStatus.delivered: return 'delivered';
      case MessageStatus.read: return 'read';
      case MessageStatus.failed: return 'failed';
    }
  }

  static MessageStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'sending': return MessageStatus.sending;
      case 'sent': return MessageStatus.sent;
      case 'delivered': return MessageStatus.delivered;
      case 'read': return MessageStatus.read;
      case 'failed': return MessageStatus.failed;
      default: return MessageStatus.sent;
    }
  }
}
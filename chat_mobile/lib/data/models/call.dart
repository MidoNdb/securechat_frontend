class Call {
  String roomId;
  String callerId;
  String receiverId;
  String callType; // "audio" | "video"
  bool isActive;   // peut changer pendant l'appel
  String status;   // "RINGING", "ACCEPTED", "ENDED", etc.

  // Ajout des champs supplémentaires que tu utilises
  String id;
  String conversationId;
  DateTime? startedAt;

  Call({
    required this.id,
    required this.conversationId,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    this.roomId = '',
    this.isActive = false,
    this.status = "INITIAL",
    this.startedAt,
  });

   // Getter pour compatibilité avec la view
  String get callerName => callerId; 
  String get receiverName => receiverId;

  get type => null;

}

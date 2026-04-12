import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      timestamp:
          (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class DoodleMessage {
  final String senderID;
  final String senderEmail;
  final String reciverId;
  final Map<String, dynamic> doodleContent; // 🎨 holds doodle data
  final Timestamp timestamp;

  DoodleMessage({
    required this.senderID,
    required this.senderEmail,
    required this.reciverId,
    required this.doodleContent,
    required this.timestamp,
  });

  // convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'reciverId': reciverId,
      'type': 'doodle', // 👈 mark as doodle
      'doodleContent': doodleContent,
      'timestamp': timestamp,
    };
  }
}

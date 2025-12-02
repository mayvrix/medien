import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medien/models/doodle_messsage_model.dart';
import 'package:medien/models/message_model.dart';

class ChatService {
  // get instance of firestore and auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // get user stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // go through each user
        final user = doc.data();

        // return user
        return user;
      }).toList();
    });
  }

  // send message
  Future<void> sendMessage(String reciverId, String message) async {
    // get current user info
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // create new message
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail, // ✅ fixed
      reciverId: reciverId,          // ✅ fixed spelling
      message: message,
      timestamp: timestamp,
    );

    // construct chatroom id for two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserID, reciverId];
    ids.sort(); // ensure two people have same id
    String chatRoomID = ids.join('_');

    // add message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // get messages
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    // construct chatroom ID for two users
    List<String> ids = [userID, otherUserID];
    ids.sort(); // ensure two people have same id
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }


  // send doodle message
Future<void> sendDoodleMessage({
  required String reciverId,
  required String text,
  required String font,
  required double fontSize,
  required String colorHex,
}) async {
  final String currentUserID = _auth.currentUser!.uid;
  final String currentUserEmail = _auth.currentUser!.email!;
  final Timestamp timestamp = Timestamp.now();

  // build doodle message
  final doodleMessage = DoodleMessage(
    senderID: currentUserID,
    senderEmail: currentUserEmail,
    reciverId: reciverId,
    timestamp: timestamp,
    doodleContent: {
      "text": text,
      "font": font,
      "fontSize": fontSize,
      "color": colorHex,
    },
  );

  // construct chatroom id
  List<String> ids = [currentUserID, reciverId];
  ids.sort();
  String chatRoomID = ids.join('_');

  // save to firestore
  await _firestore
      .collection("chat_rooms")
      .doc(chatRoomID)
      .collection("messages")
      .add(doodleMessage.toMap());
}

Future<void> deleteMessage(String reciverId, String messageId) async {
  final String currentUserID = _auth.currentUser!.uid;

  // construct chatroom id
  List<String> ids = [currentUserID, reciverId];
  ids.sort();
  String chatRoomID = ids.join('_');

  await _firestore
      .collection("chat_rooms")
      .doc(chatRoomID)
      .collection("messages")
      .doc(messageId)
      .delete();
}


}

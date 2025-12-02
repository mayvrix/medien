import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new group (✅ untouched)
  Future<String> createGroup({
    required String groupName,
    required List<String> memberIds,
  }) async {
    final String groupId = _firestore.collection("groups").doc().id;

    await _firestore.collection("groups").doc(groupId).set({
      "groupId": groupId,
      "name": groupName,
      "adminId": _auth.currentUser!.uid,
      "members": memberIds,
      "createdAt": FieldValue.serverTimestamp(),
      "lastMessage": null,
      "lastMessageAt": null,
    });

    return groupId;
  }

  /// Delete group (only admin can delete)
  Future<void> deleteGroup(String groupId) async {
    final groupDoc = await _firestore.collection("groups").doc(groupId).get();
    if (!groupDoc.exists) throw Exception("Group not found");

    final data = groupDoc.data()!;
    if (data["adminId"] != _auth.currentUser!.uid) {
      throw Exception("Only admin can delete this group");
    }

    // Delete all messages inside the group first
    final messages = await _firestore
        .collection("groups")
        .doc(groupId)
        .collection("messages")
        .get();

    for (var msg in messages.docs) {
      await msg.reference.delete();
    }

    // Delete the group itself
    await _firestore.collection("groups").doc(groupId).delete();
  }

  /// Send text message
  Future<void> sendMessage(String groupId, String message) async {
    final String senderId = _auth.currentUser!.uid;
    final String senderEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    await _firestore.collection("groups").doc(groupId).collection("messages").add({
      "senderId": senderId,
      "senderEmail": senderEmail,
      "message": message,
      "type": "text", // ✅ mark as text
      "timestamp": timestamp,
    });

    // update lastMessage at group level
    await _firestore.collection("groups").doc(groupId).update({
      "lastMessage": message,
      "lastMessageAt": timestamp,
    });
  }

  /// Send doodle message (same as 1-to-1 but for groups)
  Future<void> sendDoodleMessage({
    required String groupId,
    required String text,
    required String font,
    required double fontSize,
    required String colorHex,
  }) async {
    final String senderId = _auth.currentUser!.uid;
    final String senderEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    await _firestore.collection("groups").doc(groupId).collection("messages").add({
      "senderId": senderId,
      "senderEmail": senderEmail,
      "type": "doodle", // ✅ mark type as doodle
      "timestamp": timestamp,
      "doodleContent": {
        "text": text,
        "font": font,
        "fontSize": fontSize,
        "color": colorHex,
      },
    });

    await _firestore.collection("groups").doc(groupId).update({
      "lastMessage": "[Doodle]",
      "lastMessageAt": timestamp,
    });
  }

  /// Delete a specific message (sender or admin can delete)
  Future<void> deleteMessage(String groupId, String messageId) async {
    final String currentUserID = _auth.currentUser!.uid;

    final msgRef = _firestore
        .collection("groups")
        .doc(groupId)
        .collection("messages")
        .doc(messageId);

    final msgDoc = await msgRef.get();
    if (!msgDoc.exists) return;

    final data = msgDoc.data()!;
    final groupDoc = await _firestore.collection("groups").doc(groupId).get();

    if (data["senderId"] == currentUserID ||
        groupDoc.data()!["adminId"] == currentUserID) {
      await msgRef.delete();
    } else {
      throw Exception("You cannot delete this message");
    }
  }

  /// Get group messages stream
  Stream<QuerySnapshot> getMessages(String groupId) {
    return _firestore
        .collection("groups")
        .doc(groupId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  /// Get all groups user is a member of
  Stream<List<Map<String, dynamic>>> getUserGroups() {
    final userId = _auth.currentUser!.uid;
    return _firestore.collection("groups").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data())
          .where((group) => (group["members"] as List).contains(userId))
          .toList();
    });
  }

  /// Add user to group
  Future<void> addMember(String groupId, String userId) async {
    await _firestore.collection("groups").doc(groupId).update({
      "members": FieldValue.arrayUnion([userId]),
    });
  }

  /// Remove user from group
  Future<void> removeMember(String groupId, String userId) async {
    await _firestore.collection("groups").doc(groupId).update({
      "members": FieldValue.arrayRemove([userId]),
    });
  }

  /// Make another member admin (only current admin can do)
  Future<void> makeAdmin(String groupId, String newAdminId) async {
    final groupDoc = await _firestore.collection("groups").doc(groupId).get();
    if (!groupDoc.exists) throw Exception("Group not found");

    if (groupDoc.data()!["adminId"] != _auth.currentUser!.uid) {
      throw Exception("Only current admin can assign new admin");
    }

    await _firestore.collection("groups").doc(groupId).update({
      "adminId": newAdminId,
    });
  }
}

// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';

class AuthService {
  
  //instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login user
 // Login user
Future<UserCredential> signInWithEmailPassword(String email, String password) async {
  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // ✅ Only update, never overwrite
    await _firestore.collection("Users").doc(userCredential.user!.uid).set(
      {
        'email': email,
        'lastLogin': FieldValue.serverTimestamp(), // optional
      },
      SetOptions(merge: true), // 👈 merge keeps username/profileNumber safe
    );

    return userCredential;
  } on FirebaseAuthException catch (e) {
    throw Exception(e.code);
  }
}


  //sign in
    Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
       try {
        //CREATE USER
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
        );

        // SAVE USER IN  DOC
        _firestore.collection("Users").doc(userCredential.user!.uid).set(
          {
            'uid' : userCredential.user!.uid,
            'email' : email
          }
        );

      return userCredential;
    }
   on FirebaseAuthException catch (e) {
 throw Exception(e.code);
}   
}




  //sign out
  Future<void> signOut() async{
    return await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }



   // ---------------- PROFILE ---------------- //

  /// Save username + profile number
  Future<void> setProfile({
    required String uid,
    required String username,
    required int profileNumber,
  }) async {
    await _firestore.collection("Users").doc(uid).set(
      {
        'username': username,
        'profileNumber': profileNumber,
      },
      SetOptions(merge: true), // ✅ merge to not overwrite uid/email
    );
  }

  /// Get profile info for a user
  Future<Map<String, dynamic>?> getProfile(String uid) async {
    DocumentSnapshot doc = await _firestore.collection("Users").doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  
}

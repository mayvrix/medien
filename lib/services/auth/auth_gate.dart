// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:medien/screens/auth_page.dart';
// import 'package:medien/screens/home_screen.dart';

// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(),
//        builder: (context, snapshot){

//         //user is logged in
//         if (snapshot.hasData){
//           return const HomeScreen();
//         }

//         //user is not logged in
//         else{
//           return const AuthPage();
//         }


//        }
//        ),
//     );
//   }
// }



import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medien/screens/auth_page.dart';
import 'package:medien/screens/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // waiting for Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // user is logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // user is not logged in
        return const AuthPage();
      },
    );
  }
}

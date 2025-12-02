import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medien/core/theme_colors.dart';
import 'package:medien/services/auth/auth_service.dart';

import '../core/size.dart'; // your S class

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final TextEditingController _usernameController = TextEditingController();
  int? _selectedPf; // stores selected profile number (1–9)
  bool _loading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  bool get _isNextEnabled {
    return _selectedPf != null && _usernameController.text.trim().isNotEmpty;
  }

  Future<void> _handleNext() async {
    if (!_isNextEnabled) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No logged-in user found");
      }

      await _authService.setProfile(
        uid: user.uid,
        username: _usernameController.text.trim(),
        profileNumber: _selectedPf!,
      );

      debugPrint("✅ Profile saved for ${user.uid}");

      // Navigate to home after saving
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/home");
      }
    } catch (e) {
      debugPrint("❌ Failed to save profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.appColors;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
    
              Colors.white,
              Colors.white,
            ],
            stops: const [ 0.1, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(s.wp(0.07)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Top avatar ---
                    Container(
                      padding: EdgeInsets.all(s.wp(0.03)),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(s.rad(0.075)),
                      ),
                      child: CircleAvatar(
                        radius: s.wp(0.15),
                        backgroundColor: colors.onPrimary,
                        backgroundImage: _selectedPf != null
                            ? AssetImage('assets/image/pf$_selectedPf.png')
                            : null,
                        child: _selectedPf == null
                            ? Icon(Icons.person,
                                size: s.wp(0.12), color: colors.primary)
                            : null,
                      ),
                    ),
                    SizedBox(height: s.hp(0.02)),

                    // --- Grid of profile pics ---
                    Container(
                      padding: EdgeInsets.all(s.wp(0.08)),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.onPrimary, width: 0),
                        borderRadius: BorderRadius.circular(s.rad(0.075)),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: 9,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: s.wp(0.03),
                          mainAxisSpacing: s.hp(0.015),
                        ),
                        itemBuilder: (context, index) {
                          final pfNum = index + 1;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPf = pfNum;
                              });
                            },
                            child: CircleAvatar(
                              radius: s.wp(0.12),
                              backgroundImage:
                                  AssetImage('assets/image/pf$pfNum.png'),
                              foregroundColor: Colors.transparent,
                              child: _selectedPf == pfNum
                                  ? Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colors.primary,
                                          width: 3,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: s.hp(0.02)),

                    // --- Username input ---
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: s.wp(0.05)),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.primary, width: 3.5),
                        borderRadius: BorderRadius.circular(s.rad(0.04)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _usernameController,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(
                                fontSize: s.sp(0.045),
                                fontFamily: "RSO",
                                color: colors.primary,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "username",
                                hintStyle: TextStyle(
                                  fontSize: s.sp(0.045),
                                  fontFamily: "RSO",
                                  color: colors.primary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                          Icon(Icons.edit_square,
                              color: colors.primary, size: s.wp(0.06)),
                        ],
                      ),
                    ),
                    SizedBox(height: s.hp(0.05)),

                    // --- Next button ---
                    GestureDetector(
                      onTap: _isNextEnabled && !_loading ? _handleNext : null,
                      child: Container(
                        width: s.wp(0.35),
                        height: s.wp(0.35),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isNextEnabled
                              ? colors.primary
                              : colors.onPrimary,
                        ),
                        child: _loading
                            ? Center(
                                child: SizedBox(
                                  width: s.wp(0.08),
                                  height: s.wp(0.08),
                                  child: CircularProgressIndicator(
                                    color: colors.onPrimary,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            : Icon(Icons.arrow_forward,
                                color: colors.onPrimary, size: s.wp(0.1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

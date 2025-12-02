import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medien/core/theme_colors.dart';
import 'package:medien/services/auth/auth_service.dart';
import '../core/size.dart'; // your S class

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController _usernameController = TextEditingController();
  int? _selectedPf;
  bool _loading = false;
  String? _currentUsername;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _usernameController.text = data['username'] ?? "";
      _currentUsername = data['username'] ?? "username";
      _selectedPf = data['profileNumber'];
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_usernameController.text.trim().isEmpty || _selectedPf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select avatar and enter username")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.setProfile(
        uid: user.uid,
        username: _usernameController.text.trim(),
        profileNumber: _selectedPf!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile updated")),
      );

      // Notify previous screen to refresh
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("❌ Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Override Android back button to also notify
  Future<bool> _onWillPop() async {
    Navigator.pop(context, true); // notify previous screen
    return false; // prevent default pop because we already did it
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.appColors;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: BoxDecoration(color: colors.onPrimary),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(s.wp(0.07)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // --- Username input ---
                          Container(
                            margin: EdgeInsets.only(bottom: s.hp(0.03)),
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
                                    style: TextStyle(
                                      fontSize: s.sp(0.045),
                                      fontFamily: "RSO",
                                      color: colors.primary,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: _currentUsername ?? "username",
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

                          // --- Top avatar ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.all(s.wp(0.03)),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(s.rad(0.075)),
                                ),
                                child: CircleAvatar(
                                  radius: s.wp(0.155),
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

                              // --- Save button (always enabled) ---
                              GestureDetector(
                                onTap: _saveProfile,
                                child: Container(
                                  width: s.wp(0.44),
                                  height: s.wp(0.44),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primary,
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
                          SizedBox(height: s.hp(0.04)),

                          // --- Grid of profile pics ---
                          Container(
                            padding: EdgeInsets.all(s.wp(0.00)),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(s.rad(0.075)),
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              itemCount: 9,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: s.wp(0.0),
                                mainAxisSpacing: s.hp(0.00),
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
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Back button ---
                Positioned(
                  top: s.hp(0.02),
                  left: s.wp(0.05),
                  child: _CapsuleButton(
                    onTap: () => Navigator.pop(context, true), // notify previous screen
                    icon: Icons.arrow_back,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CapsuleButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _CapsuleButton({
    required this.onTap,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: s.w * 0.25,
        height: s.w * 0.12,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(s.rad(0.04)),
        ),
        child: Icon(
          icon,
          size: s.sp(0.05),
          color: color,
        ),
      ),
    );
  }
}

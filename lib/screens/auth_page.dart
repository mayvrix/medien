// lib/screens/phone_auth_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medien/core/size.dart';
import '../services/auth/auth_service.dart';
import '../core/theme_colors.dart';
// import 'home_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSignUp = true;
  bool _loading = false;

 _submitSignUp(BuildContext context) async {
  final password = _passwordController.text.trim();
  final confirmPassword = _confirmPasswordController.text.trim();

  if (password != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwords do not match")),
    );
    return;
  }

  final _auth = AuthService();
  try {
    await _auth.signUpWithEmailPassword(
      _emailController.text,
      _passwordController.text,
    );

    // 🔹 After successful signup, push to UserDetailsPage
    if (mounted) {
      Navigator.pushReplacementNamed(context, "/userDetails");
    }
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(e.toString()),
      ),
    );
  }
}


  void _submitLogIn(BuildContext context) async {
    final _auth = AuthService();

    try {
      await _auth.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(e.toString()),
              ));
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
 
        Colors.white,   // fade into white
        Colors.white,   // rest white

      ],
      stops: const [
   
        0.14,   // fade finished by 10%
        1.0,   // rest white
      ],
    ),
  
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: s.wp(0.08)),
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(height:s.h*0.005),
                  // 🔹 Top - Toggle buttons
                  Container(
                   
                    margin: EdgeInsets.only(top: s.hp(0.03)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(s.rad(0.09)),
                      border: Border.all(color: colors.primary, width: 2),
                      color:  colors.onPrimary,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSignUp = true),
                            child: Container(
                              padding:
                                  EdgeInsets.symmetric(vertical: s.hp(0.015)),
                              decoration: BoxDecoration(
                                color: _isSignUp
                                    ? colors.primary
                                    : colors.onPrimary,
                                borderRadius:
                                    BorderRadius.circular(s.rad(0.09)),
                              ),
                              child: Center(
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: s.sp(0.04),
                                    fontFamily: "RSO",
                                    color: _isSignUp
                                        ? colors.onPrimary
                                        : colors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSignUp = false),
                            child: Container(
                              padding:
                                  EdgeInsets.symmetric(vertical: s.hp(0.015)),
                              decoration: BoxDecoration(
                                color: !_isSignUp
                                    ? colors.primary
                                    : colors.onPrimary,
                                borderRadius:
                                    BorderRadius.circular(s.rad(0.09)),
                              ),
                              child: Center(
                                child: Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: s.sp(0.04),
                                    fontFamily: "RSO",
                                    color: !_isSignUp
                                        ? colors.onPrimary
                                        : colors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height:s.h*0.005),

                  // 🔹 Middle - Fields + Arrow button
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Email',
                        s: s,
                        colors: colors,
                      ),
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Password',
                        s: s,
                        colors: colors,
                        obscure: true,
                      ),
                      if (_isSignUp)
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: 'Confirm Password',
                          s: s,
                          colors: colors,
                          obscure: true,
                        ),
                      SizedBox(height: s.hp(0.01)),
                      _loading
                          ? CircularProgressIndicator(color: colors.primary)
                          : GestureDetector(
                              onTap: () {
                                if (_isSignUp) {
                                  _submitSignUp(context);
                                } else {
                                  _submitLogIn(context);
                                }
                              },
                              child: Container(
                                width: s.wp(0.37),
                                height: s.wp(0.37),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: colors.onPrimary,
                                  size: s.sp(0.05),
                                ),
                              ),
                            ),
                    ],
                  ),

                  // 🔹 Bottom - App name
                  Padding(
                    padding: EdgeInsets.only(bottom: s.hp(0.04)),
                    child: Text(
                      'medien',
                      style: TextStyle(
                        fontSize: s.sp(0.15),
                        fontFamily: "RSO",
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required S s,
    required AppPalette colors,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: s.hp(0.02)),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: s.sp(0.035),
          fontFamily: "RSO",
          color: colors.primary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: colors.primary,
            fontFamily: "RSO",
          ),
          filled: true,
          fillColor: colors.onPrimary,
          contentPadding: EdgeInsets.symmetric(
            vertical: s.hp(0.02),
            horizontal: s.wp(0.04),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(s.rad(0.09)),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(s.rad(0.09)),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

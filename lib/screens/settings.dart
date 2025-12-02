import 'package:flutter/material.dart';
import 'package:medien/core/theme_colors.dart';
// import 'package:medien/screens/auth_page.dart';
import 'package:medien/services/auth/auth_service.dart';
import '../core/size.dart';
// import '../core/theme_controller.dart';
import 'theme_selection_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  
void logout(BuildContext context) async {
  final _auth = AuthService();
  await _auth.signOut();
  // ✅ No navigation needed — AuthGate handles it

   // Pop the current page (if possible)
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}


  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // final c = ThemeControllerProvider.of(context);
    final colors = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s.pad(0.02)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Capsule Back Button
              _CapsuleButton(
                onTap: () => Navigator.pop(context),
                icon: Icons.arrow_back,
                color: colors.primary, // color should be Color, not full appColors
              ),
              SizedBox(height: s.hp(0.03)),

              // Capsule "Themes" container
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ThemeSelectionScreen(),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  height: s.w * 0.40,
                  padding: EdgeInsets.symmetric(
                    horizontal: s.pad(0.035),
                    vertical: s.pad(0.017),
                  ),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(s.rad(0.058)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // vertical centering
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // text left, icon right
                    children: [
                      Text(
                        "Themes",
                        style: TextStyle(
                          fontSize: s.sp(0.15),
                          height: 1,
                          color: colors.primary,
                          fontFamily: "SSEC",
                        ),
                      ),
                      Icon(
                        Icons.format_color_fill_rounded,
                        size: s.sp(0.05),
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),

              // const Spacer(),
              SizedBox(height: s.h*0.02,),


              //bye bbye
               GestureDetector(
                onTap: () => logout(context),
                child: Container(
                  width: double.infinity,
                  height: s.w * 0.40,
                  padding: EdgeInsets.symmetric(
                    horizontal: s.pad(0.035),
                    vertical: s.pad(0.017),
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(s.rad(0.058)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // vertical centering
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // text left, icon right
                    children: [
                      Text(
                        "Log Out",
                        style: TextStyle(
                          fontSize: s.sp(0.15),
                          height: 1,
                          color: colors.card,
                          fontFamily: "SSEC",
                        ),
                      ),
                      Icon(
                        Icons.logout_outlined,
                        size: s.sp(0.05),
                        color: colors.card,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
        padding: EdgeInsets.all(s.pad(0.015)),
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

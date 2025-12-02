import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:medien/screens/edit_profile.dart';
import 'package:medien/screens/groups/create_group.dart';
import 'package:medien/screens/groups/view_group.dart';
import '../core/theme_colors.dart';
import '../core/size.dart';

class BottomFabBar extends StatefulWidget {
  final VoidCallback onPrimaryAction;
  final VoidCallback onProfileUpdated;

  const BottomFabBar({
    super.key,
    required this.onPrimaryAction,
    required this.onProfileUpdated,
  });

  @override
  State<BottomFabBar> createState() => _BottomFabBarState();
}

class _BottomFabBarState extends State<BottomFabBar> {
  bool expanded = false;

  void _toggle() {
    setState(() => expanded = !expanded);
    widget.onPrimaryAction();
  }

void _showHeartPopup() {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) {
      return Positioned(
        bottom: MediaQuery.of(context).size.height * 0.12, // above FAB
        left: MediaQuery.of(context).size.width * 0.46, // center horizontally
        child: _HeartPopup(onFinish: () {
          entry.remove(); // remove after fade
        }),
      );
    },
  );

  overlay.insert(entry);
}


  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.appColors;

    final barHeight = s.hp(.09);
    final radius = s.rad(.03);

    return Stack(
      children: [
        // Background blur when expanded
       if (expanded)
  Positioned.fill(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque, // 👈 ensures taps register everywhere
      onTap: () {
        setState(() => expanded = false); // close menu
      },
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                c.blur,
                c.onPrimary,
              ],
            ),
          ),
        ),
      ),
    ),
  ),

        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              left: s.wp(.055),
              right: s.wp(.055),
              bottom: s.hp(.025),
            ),
            child: Row(
              children: [
                GestureDetector(
  // Inside BottomFabBar, when tapping profile icon
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ProfileEditPage()),
  ).then((refresh) {
    if (refresh == true) {
      widget.onProfileUpdated(); // trigger setState in HomeScreen
    }
  });
},
                  child: _iconTile1(context, Icons.account_circle, barHeight, radius)),
                SizedBox(width: s.wp(.013)),
                GestureDetector(
                  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) =>  GroupScreen()),
  );
                  },
                  child: _iconTile2(context, Icons.perm_phone_msg_sharp, barHeight, radius)),
                SizedBox(width: s.wp(.013)),
                GestureDetector(
                  onTap: _showHeartPopup,
 
                  child: _iconTile3(context, Icons.favorite, barHeight, radius)),
                const Spacer(),

                // Arrow action button
                SizedBox(
                  height: barHeight * 1.1,
                  width: barHeight * 1.1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          expanded ? barHeight : radius,
                        ),
                      ),
                    ),
                    onPressed: _toggle,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: expanded
                          ? Icon(
                              Icons.arrow_upward,
                              key: const ValueKey("up"),
                              size: s.sp(.05),
                              color: c.icon,
                            )
                          : Transform.rotate(
                              key: const ValueKey("forward"),
                              angle: -45 * 3.1415926535 / 180,
                              child: Icon(
                                Icons.arrow_forward,
                                size: s.sp(.05),
                                color: c.icon,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Capsule menu with 2 options
        // Capsule menus with 2 options (separate capsules)
if (expanded) ...[
  // Positioned(
  //   right: s.wp(.055),
  //   bottom: barHeight * 2.4,
  //   child: _capsuleOption(
  //     context,
  //     "nearby chat",
  //     () {
  //       // handle option 1
  //     },
  //   ),
  // ),
  Positioned(
  right: s.wp(.055),
  bottom: barHeight * 1.6,
  child: _capsuleOption(
    context,
    "create a group",
    () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateGroupScreen(),
        ),
      );
    },
  ),
),

],
      ]
    );
  }

  Widget _capsuleOption(BuildContext context, String text, VoidCallback onTap) {
    final s = S.of(context);
    final c = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: s.wp(.04),
          vertical: s.hp(.01),
        ),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: c.onPrimary,
            fontSize: s.sp(.035),
            fontFamily: "POP"
          ),
        ),
      ),
    );
  }

  Widget _iconTile1(BuildContext context, IconData icon, double h, double radius) {
    final s = S.of(context);
    final c = context.appColors;
    final w = MediaQuery.of(context).size.width;

    return Container(
      height: h * 0.75,
      width: h * 1,
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(w * 0.08),
          topRight: Radius.circular(w * 0.01),
          bottomLeft: Radius.circular(w * 0.08),
          bottomRight: Radius.circular(w * 0.01),
        ),
      ),
      child: Icon(icon, size: s.sp(.045), color: c.icon),
    );
  }

  Widget _iconTile2(BuildContext context, IconData icon, double h, double radius) {
    final s = S.of(context);
    final c = context.appColors;
    final w = MediaQuery.of(context).size.width;

    return Container(
      height: h * 0.75,
      width: h * 1,
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(w * 0.02),
      ),
      child: Icon(icon, size: s.sp(.045), color: c.icon),
    );
  }

  Widget _iconTile3(BuildContext context, IconData icon, double h, double radius) {
    final s = S.of(context);
    final c = context.appColors;
    final w = MediaQuery.of(context).size.width;

    return Container(
      height: h * 0.75,
      width: h * 1,
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(w * 0.01),
          topRight: Radius.circular(w * 0.08),
          bottomLeft: Radius.circular(w * 0.01),
          bottomRight: Radius.circular(w * 0.08),
        ),
      ),
      child: Icon(icon, size: s.sp(.045), color: c.icon),
    );
  }
}




class _HeartPopup extends StatefulWidget {
  final VoidCallback onFinish;
  const _HeartPopup({required this.onFinish});

  @override
  State<_HeartPopup> createState() => _HeartPopupState();
}

class _HeartPopupState extends State<_HeartPopup> {
  double opacity = 1.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => opacity = 0.0);
      }
    });
    Future.delayed(const Duration(seconds: 3), widget.onFinish);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          // Bubble with text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "hi there",
              style: TextStyle(
                fontFamily: "POP",
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ),
          // little pointer triangle
          CustomPaint(
            painter: _TrianglePainter(),
            child: const SizedBox(height: 10, width: 20),
          ),
         
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

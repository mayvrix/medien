import 'package:flutter/material.dart';
import '../core/size.dart';
import '../core/theme_controller.dart';
import '../core/theme_colors.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final controller = ThemeControllerProvider.of(context);
    final colors = context.appColors;
    final bool auto = false;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s.pad(0.02)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CapsuleButton(
                onTap: () => Navigator.pop(context),
                icon: Icons.arrow_back,
                 color: colors.primary,
              ),
              SizedBox(height: s.hp(0.03)),

              // Theme options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ThemeCard(
                    label: "COOL",
                    asset: "assets/image/cool.jpg",
                    selected: controller.selectedTheme == "cool",
                    onTap: () => controller.selectTheme("cool"),
                    tag: "w1",
                  ),
                  SizedBox(width: s.wp(0.02)),
                  _ThemeCard(
                    label: "WARM",
                    asset: "assets/image/warm.jpg",
                    selected: controller.selectedTheme == "warm",
                    onTap: () => controller.selectTheme("warm"),
                    tag: "w2",
                  ),
                ],
              ),

              SizedBox(height: s.hp(0.04)),

              // Dark mode toggle card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(s.pad(0.02)),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(s.rad(0.05)),
                ),
                child: Column(
                  children: [
                    Text(
                      "DARK MODE",
                      style: TextStyle(fontSize: s.sp(0.16),
                       fontFamily: "SSEC",
                       color: colors.primary,
                       height: 1
                       ),
                    ),
                   Transform.scale(
  scale: 1.4, // increase switch size
  child: Switch(
    value: controller.isDarkMode,
    onChanged: controller.toggleDarkMode,
    activeColor: controller.selectedTheme == "warm"
        ? const Color.fromARGB(255, 148, 255, 98) // warm primary
        : const Color.fromARGB(255, 82, 29, 229), // cool primary
    activeTrackColor: controller.selectedTheme == "warm"
        ? const Color.fromARGB(255, 255, 199, 180) // warm light track
        : const Color(0xFFCDC1FF), // cool light track
    inactiveThumbColor: controller.selectedTheme == "warm"
        ? const Color(0xFFE0B2A8) // warm muted
        : const Color.fromARGB(255, 139, 152, 201), // cool muted
    inactiveTrackColor: controller.selectedTheme == "warm"
        ? const Color.fromARGB(255, 211, 248, 195) // warm light bg
        : const Color.fromARGB(255, 224, 209, 255), // cool light bg
  ),
),

                  ],
                ),
              ),
              

              const Spacer(),

              Transform.translate(
                offset: Offset(0, s.h*0.02),
                child: Center(child: Icon(Icons.waves_rounded,
                size: s.sp(0.05),
                color: const Color.fromARGB(255, 255, 255, 255),
                ))),

              Transform.translate(
                offset: Offset(0, s.h*0.01),
                child: Center(
                  child: Text(
                    "wavelayer",
                    style: TextStyle(
                      fontSize: s.sp(0.05),
                      fontFamily: "SHT",
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
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
class _ThemeCard extends StatelessWidget {
  final String label;
  final String asset;
  final bool selected;
  final String tag; // w1 or w2
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.asset,
    required this.selected,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s.wp(0.45),
                height: s.hp(0.25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(s.rad(0.07)),
                  border: Border.all(
                    color: selected ? colors.primary : Colors.transparent,
                    width: s.wp(0.011),
                  ),
                  image: DecorationImage(
                    image: AssetImage(asset),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: s.pad(0.012),
                    vertical: s.pad(0.004),
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(0, 255, 255, 255),
                    borderRadius: BorderRadius.circular(s.rad(0.02)),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: s.sp(0.069),
                      color: Colors.white,
                      fontFamily: "SHT",
                      
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: s.hp(0.007)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: s.pad(0.05),
              vertical: s.pad(0.005),
            ),
            decoration: BoxDecoration(
              color: tag=="w1"?Color.fromARGB(255, 91, 41, 228) : Color.fromARGB(255, 99, 255, 60),
              borderRadius: BorderRadius.circular(s.rad(0.09)),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: s.sp(0.04),
                fontFamily: "SHT",
                color: Colors.white,
              ),
            ),
          ),
        ],
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
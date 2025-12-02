import 'package:flutter/material.dart';
import 'package:medien/core/theme_colors.dart';
import 'package:medien/core/size.dart';

/// ---------------- FONT DIALOG ----------------
Future<String?> showFontDialog(BuildContext context) {
  final s = S.of(context);
  final palette = context.appColors;

  final fonts = {
    "Savate": {"family": "SVT", "size": s.sp(0.036)},
    "Bungee Outline": {"family": "BGO", "size": s.sp(0.040)},
    "Sofia Sans Extra Condensed": {"family": "SSEC", "size": s.sp(0.034)},
    "Doto": {"family": "DOTO", "size": s.sp(0.038)},
    "Press Start 2P": {"family": "PS2", "size": s.sp(0.022)},
    "Bangers": {"family": "BNG", "size": s.sp(0.038)},
    "Racing Sans One": {"family": "RSO", "size": s.sp(0.038)},
    "Pinyon Script": {"family": "PNS", "size": s.sp(0.042)},
    "Tiny5": {"family": "TN5", "size": s.sp(0.038)},
  };

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (ctx) => Container(
      width: double.infinity,
      margin: EdgeInsets.all(s.pad(0.02)),
      padding: EdgeInsets.all(s.pad(0.03)),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(s.rad(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("^",
              style: TextStyle(
                fontFamily: "TN5",
                fontSize: s.sp(0.1),
                color: palette.onPrimary,
                height: 0.4,
              )),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: fonts.entries.map((e) {
              final family = e.value["family"] as String;
              final size = e.value["size"] as double;

              return GestureDetector(
                onTap: () => Navigator.pop(ctx, family),
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: s.hp(0.0025)),
                  padding: EdgeInsets.symmetric(
                      vertical: s.hp(0.005), horizontal: s.wp(0.06)),
                  decoration: BoxDecoration(
                    color: palette.onPrimary,
                    borderRadius: BorderRadius.circular(s.rad(0.04)),
                  ),
                  child: Center(
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontSize: size,
                        fontFamily: family,
                        color: palette.text,
                        height: 1.1,
                        fontWeight: family == "BGO" ? FontWeight.w900 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );
}

/// ---------------- SIZE DIALOG ----------------
Future<double?> showSizeDialog(BuildContext context, String fontFamily) {
  final s = S.of(context);
  final palette = context.appColors;

  Map<String, double> sizes = {
    "Smaller": s.sp(0.028),
    "Small": s.sp(0.032),
    "Regular": s.sp(0.038),
    "Big": s.sp(0.045),
    "Bigger": s.sp(0.055),
  };

  // Custom adjustments
  if (fontFamily == "PS2") {
    sizes = {
      "Smaller": s.sp(0.025),
      "Small": s.sp(0.029),
      "Regular": s.sp(0.032),
      "Big": s.sp(0.045),
      "Bigger": s.sp(0.050),
    };
  } else if (fontFamily == "RSO") {
    sizes = {
      "Smaller": s.sp(0.030),
      "Small": s.sp(0.040),
      "Regular": s.sp(0.051),
      "Big": s.sp(0.062),
      "Bigger": s.sp(0.075),
    };
  } else if (fontFamily == "SSEC") {
    sizes = {
      "Smaller": s.sp(0.032),
      "Small": s.sp(0.039),
      "Regular": s.sp(0.048),
      "Big": s.sp(0.057),
      "Bigger": s.sp(0.071),
    };
  } else if (fontFamily == "SVT") {
    sizes = {
      "Smaller": s.sp(0.029),
      "Small": s.sp(0.037),
      "Regular": s.sp(0.048),
      "Big": s.sp(0.054),
      "Bigger": s.sp(0.069),
    };
  } else if (fontFamily == "BGO") {
    sizes = {
      "Smaller": s.sp(0.030),
      "Small": s.sp(0.039),
      "Regular": s.sp(0.047),
      "Big": s.sp(0.058),
      "Bigger": s.sp(0.072),
    };
  } else if (fontFamily == "DOTO") {
    sizes = {
      "Smaller": s.sp(0.032),
      "Small": s.sp(0.040),
      "Regular": s.sp(0.052),
      "Big": s.sp(0.062),
      "Bigger": s.sp(0.075),
    };
  } else if (fontFamily == "BNG") {
    sizes = {
      "Smaller": s.sp(0.028),
      "Small": s.sp(0.035),
      "Regular": s.sp(0.047),
      "Big": s.sp(0.055),
      "Bigger": s.sp(0.075),
    };
  } else if (fontFamily == "PNS") {
    sizes = {
      "Smaller": s.sp(0.035),
      "Small": s.sp(0.049),
      "Regular": s.sp(0.058),
      "Big": s.sp(0.067),
      "Bigger": s.sp(0.074),
    };
  } else if (fontFamily == "TN5") {
    sizes = {
      "Smaller": s.sp(0.030),
      "Small": s.sp(0.040),
      "Regular": s.sp(0.050),
      "Big": s.sp(0.060),
      "Bigger": s.sp(0.070),
    };
  }

  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (ctx) => Container(
      width: double.infinity,
      margin: EdgeInsets.all(s.pad(0.02)),
      padding: EdgeInsets.all(s.pad(0.03)),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(s.rad(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("^",
              style: TextStyle(
                fontFamily: "TN5",
                fontSize: s.sp(0.1),
                color: palette.onPrimary,
                height: 0.4,
              )),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: sizes.entries
                .map((e) => GestureDetector(
                      onTap: () => Navigator.pop(ctx, e.value),
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: s.hp(0.0025)),
                        padding: EdgeInsets.symmetric(
                            vertical: s.hp(0.005), horizontal: s.wp(0.06)),
                        decoration: BoxDecoration(
                          color: palette.onPrimary,
                          borderRadius: BorderRadius.circular(s.rad(0.04)),
                        ),
                        child: Center(
                          child: Text(
                            e.key,
                            style: TextStyle(
                              fontSize: s.sp(0.035),
                              letterSpacing: s.w*0.03,
                              fontFamily: "POP",
                              color: palette.text,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    ),
  );
}

/// ---------------- COLOR DIALOG ----------------
Future<String?> showColorDialog(BuildContext context) {
  final s = S.of(context);
  final palette = context.appColors;

  final List<Color> colors = [
    const Color.fromARGB(255, 226, 135, 0),
    const Color.fromARGB(255, 38, 255, 0),
    const Color.fromARGB(255, 209, 123, 179),
    const Color.fromARGB(255, 1, 24, 202),
    const Color.fromARGB(255, 220, 15, 0),
    const Color.fromARGB(255, 61, 182, 65),
    const Color.fromARGB(255, 74, 95, 255),
  ];

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (ctx) => Container(
      width: double.infinity,
      margin: EdgeInsets.all(s.pad(0.02)),
      padding: EdgeInsets.all(s.pad(0.03)),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(s.rad(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("^",
              style: TextStyle(
                fontFamily: "TN5",
                fontSize: s.sp(0.1),
                color: palette.onPrimary,
                height: 0.4,
              )),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: colors.map((c) {
              final hex =
                  "#${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}";
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, hex),
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: s.hp(0.0025)),
                  padding: EdgeInsets.symmetric(
                      vertical: s.hp(0.010), horizontal: s.wp(0.06)),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(s.rad(0.04)),
                    border: Border.all(color: palette.onPrimary, width: 5),
                  ),
                  child: Center(
                    child: Text(
                      " ",
                      style: TextStyle(
                        fontSize: s.sp(0.020),
                        fontFamily: "RSO",
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );
}

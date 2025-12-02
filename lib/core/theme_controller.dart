import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  bool isDarkMode;
  String selectedTheme; // "cool" or "warm"

  ThemeController({
    this.isDarkMode = false,
    this.selectedTheme = "cool",
  });

  /// Load saved preferences
  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool("isDarkMode") ?? false;
    final theme = prefs.getString("selectedTheme") ?? "cool";
    return ThemeController(isDarkMode: isDark, selectedTheme: theme);
  }

  void toggleDarkMode(bool value) async {
    isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("isDarkMode", isDarkMode);
  }

  void selectTheme(String theme) async {
    selectedTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("selectedTheme", selectedTheme);
  }
}

/// InheritedNotifier wrapper
class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, "No ThemeController found in context");
    return provider!.notifier!;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medien/screens/auth_page.dart';
import 'package:medien/screens/home_screen.dart';
import 'package:medien/screens/user_details.dart';
import 'package:medien/services/auth/auth_gate.dart';
import 'firebase_options.dart';
// import 'screens/auth_page.dart';
// import 'screens/home_screen.dart';
import 'core/theme_colors.dart';
import 'core/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load saved theme
  final themeController = await ThemeController.load();

  runApp(
    ThemeControllerProvider(
      controller: themeController,
      child: const MedienApp(),
    ),
  );
}

class MedienApp extends StatefulWidget {
  const MedienApp({super.key});

  @override
  State<MedienApp> createState() => _MedienAppState();
}

class _MedienAppState extends State<MedienApp> {
  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerProvider.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Select palette based on theme mode
        final palette = controller.selectedTheme == "warm"
            ? (controller.isDarkMode
                ? AppPalette.warmdark()
                : AppPalette.warmlight())
            : (controller.isDarkMode
                ? AppPalette.dark()
                : AppPalette.light());

        final ext = AppColors(palette);

        // Set status bar colors
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                controller.isDarkMode ? Brightness.light : Brightness.dark,
          ),
        );

      return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'medien',
  themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
  theme: ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: palette.bg,
    extensions: [ext],
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.primary,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: palette.bg,
    extensions: [ext],
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.primary,
    ),
  ),

  // 🔹 Define named routes
  routes: {
    '/auth': (context) => const AuthPage(),
    '/home': (context) => const HomeScreen(),
    '/userDetails': (context) => const UserDetailsPage(),
    "/gate": (context) => const AuthGate()
  },

  // 🔹 You can start with either `home:` OR `initialRoute:`
  // home: const UserDetailsPage(),
  initialRoute: '/gate',
);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'services/storage_and_share_service.dart';

// Global notifier for dynamic theme switching without bulky state libraries
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved theme preference
  final savedMode = await StorageAndShareService.getThemeMode();
  if (savedMode == 'light') {
    themeModeNotifier.value = ThemeMode.light;
  } else if (savedMode == 'dark') {
    themeModeNotifier.value = ThemeMode.dark;
  } else {
    themeModeNotifier.value = ThemeMode.system;
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const BdEpaperHubApp());
}

class BdEpaperHubApp extends StatelessWidget {
  const BdEpaperHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'রানার • Runner',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Warm Newsprint Light Theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF9F7F2),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF004D40),
              primary: const Color(0xFF004D40),
              secondary: const Color(0xFFC62828),
              surface: Colors.white,
              surfaceContainerHighest: const Color(0xFFF0ECE1),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.hindSiliguriTextTheme(
              ThemeData.light().textTheme,
            ).copyWith(
              titleLarge: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: const Color(0xFF1A1A1A),
              ),
              titleMedium: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: const Color(0xFF212121),
              ),
              bodyMedium: GoogleFonts.hindSiliguri(
                fontSize: 13.5,
                color: const Color(0xFF424242),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF004D40),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE5E0D5), width: 1),
              ),
            ),
          ),
          // OLED Midnight Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF004D40),
              primary: const Color(0xFF26A69A),
              secondary: const Color(0xFFEF5350),
              surface: const Color(0xFF1E1E1E),
              surfaceContainerHighest: const Color(0xFF2A2A2A),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.hindSiliguriTextTheme(
              ThemeData.dark().textTheme,
            ).copyWith(
              titleLarge: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: const Color(0xFFF5F5F5),
              ),
              titleMedium: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: const Color(0xFFE0E0E0),
              ),
              bodyMedium: GoogleFonts.hindSiliguri(
                fontSize: 13.5,
                color: const Color(0xFFB0BEC5),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

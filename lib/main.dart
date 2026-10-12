import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'posts_screen.dart';
import 'details_screen.dart';
import 'favorites_screen.dart';

// Shared palette (existing names kept so other screens keep compiling).
const Color brandBlue = Color(0xFF5B5BD6);
const Color pageBackground = Color(0xFFF6F6FB);
const Color primaryText = Color(0xFF17233C);
const Color secondaryText = Color(0xFF6E7685);

// Additional shared colors.
const Color brandViolet = Color(0xFF8B7CF6);
const Color softBlue = Color(0xFFEEEEFC);
const Color lineColor = Color(0xFFE9E9F2);
const Color dangerRed = Color(0xFFB42318);

const List<BoxShadow> softShadow = [
  BoxShadow(
    color: Color(0x0F17233C),
    blurRadius: 18,
    offset: Offset(0, 6),
  ),
];

/// Decorative category used to color-code articles.
class PostCategory {
  const PostCategory(this.name, this.icon, this.color, this.tint);

  final String name;
  final IconData icon;
  final Color color;
  final Color tint;
}

const List<PostCategory> postCategories = [
  PostCategory(
    'Design',
    Icons.palette_outlined,
    Color(0xFF5B5BD6),
    Color(0xFFEEEEFC),
  ),
  PostCategory(
    'Technology',
    Icons.memory_rounded,
    Color(0xFF0E9AA7),
    Color(0xFFE2F5F6),
  ),
  PostCategory(
    'Lifestyle',
    Icons.spa_outlined,
    Color(0xFFE0568A),
    Color(0xFFFCE8F0),
  ),
  PostCategory(
    'Business',
    Icons.trending_up_rounded,
    Color(0xFFE08A1E),
    Color(0xFFFDF1DE),
  ),
  PostCategory(
    'Science',
    Icons.science_outlined,
    Color(0xFF2F9E6B),
    Color(0xFFE3F5EC),
  ),
];

int categoryIndexOf(dynamic id) {
  final n = id is int ? id : (int.tryParse('$id') ?? 0);
  return n.abs() % postCategories.length;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('favoritesBox');

  runApp(const PostReaderApp());
}

class PostReaderApp extends StatelessWidget {
  const PostReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Reader & Favorites',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: pageBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: pageBackground,
          foregroundColor: primaryText,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: lineColor),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryText,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          hintStyle: const TextStyle(color: secondaryText),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: lineColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: lineColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: brandBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: dangerRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: dangerRed, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandBlue,
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: lineColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PostsScreen(),
        '/details': (context) => const DetailsScreen(),
        '/favorites': (context) => const FavoritesScreen(),
      },
    );
  }
}
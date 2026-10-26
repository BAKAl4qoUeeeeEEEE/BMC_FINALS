import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/shop_page.dart';

const String supabaseUrl = 'https://relwoizlzfccmrhxswyl.supabase.co';
const String supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJlbHdvaXpsemZjY21yaHhzd3lsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5OTc0NDEsImV4cCI6MjEwODU3MzQ0MX0.TM19ECbKGyDj7vegxdPyGWspMS8szqiyrJEF4ywLRoY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(const ElDragonApp());
}

class ElDragonApp extends StatelessWidget {
  const ElDragonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'El Dragon PC Parts',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8F560),
          brightness: Brightness.dark,
          primary: const Color(0xFFC8F560),
          onPrimary: const Color(0xFF151A0D),
          surface: const Color(0xFF191C22),
        ),
        scaffoldBackgroundColor: const Color(0xFF0E1014),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E1014),
          centerTitle: false,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF191C22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: const ShopPage(),
    );
  }
}

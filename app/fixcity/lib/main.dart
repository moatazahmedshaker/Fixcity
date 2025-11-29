import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import 'home_page.dart';
import 'report_page.dart';
import 'track_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'admin/admin_login_page.dart';
import 'admin/admin_dashboard_page.dart';
import 'admin/report_details_page.dart';

const supabaseUrl = 'https://fxpdvgyeducxtucamfdj.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4cGR2Z3llZHVjeHR1Y2FtZmRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MzQ4ODUsImV4cCI6MjA3NzUxMDg4NX0.RVQHkXLg3-xYROsvc9wwJe6zqFa0EDsO1qqTL_jJPLU';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixcity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C), 
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00695C),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00695C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00695C), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        // REMOVED cardTheme TO FIX THE ERROR
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/report': (context) => const ReportPage(),
        '/track': (context) => const TrackPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/admin': (context) => const AdminLoginPage(),
        '/admin/dashboard': (context) => const AdminDashboardPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name != null &&
            settings.name!.startsWith('/admin/report/')) {
          final reportId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => ReportDetailsPage(reportId: reportId),
          );
        }
        return null; 
      },
    );
  }
}
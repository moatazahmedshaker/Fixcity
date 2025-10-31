import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'report_page.dart';
import 'track_page.dart';
import 'admin/admin_login_page.dart';
import 'admin/admin_dashboard_page.dart';
import 'admin/report_details_page.dart';

const supabaseUrl = 'https://fxpdvgyeducxtucamfdj.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4cGR2Z3llZHVjeHR1Y2FtZmRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MzQ4ODUsImV4cCI6MjA3NzUxMDg4NX0.RVQHkXLg3-xYROsvc9wwJe6zqFa0EDsO1qqTL_jJPLU';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // NEW: Supabase Initialization
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة البلاغات الموحدة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      
      initialRoute: '/',
      routes: {
        // --- Mobile App Routes ---
        '/': (context) => const HomePage(),
        '/report': (context) => const ReportPage(),
        '/track': (context) => const TrackPage(),

        // --- Web Admin Panel Routes ---
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
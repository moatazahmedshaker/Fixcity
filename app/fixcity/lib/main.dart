import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'splash_page.dart';
import 'home_page.dart';
import 'report_page.dart';
import 'track_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'my_reports_page.dart';
import 'admin/admin_login_page.dart';
import 'admin/admin_dashboard_page.dart';
import 'admin/report_details_page.dart';
import 'governor/governor_login_page.dart';
import 'governor/governor_dashboard_page.dart';
import 'governor/governor_report_page.dart';

const supabaseUrl = 'https://fxpdvgyeducxtucamfdj.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4cGR2Z3llZHVjeHR1Y2FtZmRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MzQ4ODUsImV4cCI6MjA3NzUxMDg4NX0.RVQHkXLg3-xYROsvc9wwJe6zqFa0EDsO1qqTL_jJPLU';

final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('ar'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        return MaterialApp(
          title: 'Fixcity',
          debugShowCheckedModeBanner: false,

          // Reactive directionality — switches with language toggle
          builder: (context, child) => Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),

          theme: ThemeData(
            useMaterial3: true,
            // Fully manual color scheme — no auto-generated blues
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D6A4F),
              onPrimary: Colors.white,
              secondary: Color(0xFF52B788),
              onSecondary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0B1F3A),
              error: Color(0xFFEF4444),
              onError: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0B1F3A),
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D6A4F)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(color: Color(0xFF2D6A4F)),
            checkboxTheme: CheckboxThemeData(fillColor: WidgetStateProperty.all(const Color(0xFF2D6A4F))),
            radioTheme: RadioThemeData(fillColor: WidgetStateProperty.all(const Color(0xFF2D6A4F))),
          ),

          // Splash is the initial route
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashPage(),
            '/': (context) => const HomePage(),
            '/report': (context) => const ReportPage(),
            '/track': (context) => const TrackPage(),
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignupPage(),
            '/my_reports': (context) => const MyReportsPage(),
            '/admin': (context) => const AdminLoginPage(),
            '/admin/dashboard': (context) => const AdminDashboardPage(),
            '/governor': (context) => const GovernorLoginPage(),
            '/governor/dashboard': (context) => const GovernorDashboardPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name != null && settings.name!.startsWith('/admin/report/')) {
              final reportId = settings.name!.split('/').last;
              return MaterialPageRoute(builder: (context) => ReportDetailsPage(reportId: reportId));
            }
            if (settings.name != null && settings.name!.startsWith('/governor/report/')) {
              final reportId = settings.name!.split('/').last;
              return MaterialPageRoute(builder: (context) => GovernorReportPage(reportId: reportId));
            }
            return null;
          },
        );
      },
    );
  }
}

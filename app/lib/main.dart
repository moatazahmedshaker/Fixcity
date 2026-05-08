import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'splash_page.dart';
import 'main_scaffold.dart';
import 'home_page.dart';
import 'report_page.dart';
import 'track_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'my_reports_page.dart';
import 'notifications_page.dart';
import 'achievements_page.dart';
import 'profile_page.dart';
import 'admin/admin_login_page.dart';
import 'admin/admin_dashboard_page.dart';
import 'admin/report_details_page.dart';
import 'governor/governor_login_page.dart';
import 'governor/governor_dashboard_page.dart';
import 'governor/governor_report_page.dart';
import 'theme.dart';
import 'settings_page.dart';

const supabaseUrl     = 'https://fxpdvgyeducxtucamfdj.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4cGR2Z3llZHVjeHR1Y2FtZmRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5MzQ4ODUsImV4cCI6MjA3NzUxMDg4NX0.RVQHkXLg3-xYROsvc9wwJe6zqFa0EDsO1qqTL_jJPLU';

final ValueNotifier<Locale> appLocale    = ValueNotifier(const Locale('ar'));
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkMode,
          builder: (context, dark, _) {
        return MaterialApp(
          title: 'FixCity',
          debugShowCheckedModeBanner: false,
          builder: (context, child) => Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary:     kRed,
              onPrimary:   Colors.white,
              secondary:   kBlue,
              onSecondary: Colors.white,
              surface:     Color(0xFF1E1E1E),
              onSurface:   Colors.white,
              error:       Color(0xFFEF4444),
              onError:     Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF0D0D0D),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A2E), foregroundColor: Colors.white, centerTitle: true, elevation: 0),
            elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)),
            inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF2A2A2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF444444), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBlue, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
          ),
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              primary:     kRed,
              onPrimary:   Colors.white,
              secondary:   kBlue,
              onSecondary: Colors.white,
              surface:     Colors.white,
              onSurface:   kDark,
              error:       Color(0xFFEF4444),
              onError:     Colors.white,
            ),
            scaffoldBackgroundColor: kBg,
            appBarTheme: const AppBarTheme(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: kRed),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBlue, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(color: kRed),
          ),
          navigatorObservers: [routeObserver],
          initialRoute: '/splash',
          routes: {
            '/splash':              (context) => const SplashPage(),
            '/':                    (context) => const MainScaffold(),
            '/home':                (context) => const MainScaffold(initialIndex: 0),
            '/report':              (context) => ReportPage(),
            '/track':               (context) => const TrackPage(),
            '/login':               (context) => const LoginPage(),
            '/signup':              (context) => const SignupPage(),
            '/my_reports':          (context) => const MainScaffold(initialIndex: 1),
            '/notifications':       (context) => const MainScaffold(initialIndex: 2),
            '/achievements':        (context) => const MainScaffold(initialIndex: 3),
            '/profile':             (context) => const MainScaffold(initialIndex: 4),
            '/admin':               (context) => const AdminLoginPage(),
            '/admin/dashboard':     (context) => const AdminDashboardPage(),
            '/governor':            (context) => const GovernorLoginPage(),
            '/governor/dashboard':  (context) => const GovernorDashboardPage(),
            '/settings':            (context) => const SettingsPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name != null && settings.name!.startsWith('/admin/report/')) {
              final reportId = settings.name!.split('/').last;
              return MaterialPageRoute(builder: (_) => ReportDetailsPage(reportId: reportId));
            }
            if (settings.name != null && settings.name!.startsWith('/governor/report/')) {
              final reportId = settings.name!.split('/').last;
              return MaterialPageRoute(builder: (_) => GovernorReportPage(reportId: reportId));
            }
            return null;
          },
        );
      },
    );
          },
        );
  }
}

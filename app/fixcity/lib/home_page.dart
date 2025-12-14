import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'translations.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  User? _user;

  @override
  void initState() {
    super.initState();
    _supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _user = data.session?.user;
      });
    });
    _user = _supabase.auth.currentUser;
  }

  void _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('snack_logout', lang: appLocale.value.languageCode))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('app_title', lang: appLocale.value.languageCode)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (appLocale.value.languageCode == 'ar') {
                  appLocale.value = const Locale('en');
                } else {
                  appLocale.value = const Locale('ar');
                }
              });
            },
            child: Text(
              t('switch_lang', lang: appLocale.value.languageCode),
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/admin');
            },
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: t('admin_tooltip', lang: appLocale.value.languageCode),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('welcome_title', lang: appLocale.value.languageCode),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                t('welcome_subtitle', lang: appLocale.value.languageCode),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 48),
              
              _buildHomeCard(
                context,
                icon: Icons.report_problem,
                title: t('submit_report', lang: appLocale.value.languageCode),
                subtitle: t('report_subtitle', lang: appLocale.value.languageCode),
                routeName: '/report',
              ),
              const SizedBox(height: 16),
              
              _buildHomeCard(
                context,
                icon: Icons.search,
                title: t('track_report', lang: appLocale.value.languageCode),
                subtitle: t('track_subtitle', lang: appLocale.value.languageCode),
                routeName: '/track',
              ),
              const SizedBox(height: 16),
              if (_user == null)
                _buildHomeCard(
                  context,
                  icon: Icons.login,
                  title: t('login', lang: appLocale.value.languageCode),
                  subtitle: t('login_subtitle', lang: appLocale.value.languageCode),
                  routeName: '/login',
                )
              else
                _buildHomeCard(
                  context,
                  icon: Icons.person,
                  title: t('my_reports', lang: appLocale.value.languageCode),
                  subtitle: t('my_reports_subtitle', lang: appLocale.value.languageCode),
                  routeName: '/my_reports',
                ),
              if (_user != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton(
                    onPressed: _logout,
                    child: Text(t('logout', lang: appLocale.value.languageCode)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String routeName,
  }) {
    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: () {
          if (routeName == '/my_reports') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t('snack_construction', lang: appLocale.value.languageCode)))
            );
          } else {
            Navigator.of(context).pushNamed(routeName);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40.0, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
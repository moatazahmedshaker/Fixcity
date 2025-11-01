import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        const SnackBar(content: Text('تم تسجيل الخروج')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة البلاغات الموحدة'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/admin');
            },
            child: const Text(
              'Admin Login', 
              style: TextStyle(color: Colors.white)
            ),
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
                'مرحباً بكم في منصة البلاغات الموحدة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'ساعدنا في جعل مدينتك أفضل مكان للعيش',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 48),
              
              _buildHomeCard(
                context,
                icon: Icons.report_problem,
                title: 'الإبلاغ عن مشكلة',
                subtitle: 'أبلغ عن مشكلة في المرافق العامة',
                routeName: '/report',
              ),
              const SizedBox(height: 16),
              
              _buildHomeCard(
                context,
                icon: Icons.search,
                title: 'متابعة بلاغ',
                subtitle: 'تابع حالة البلاغ المقدم بالكود',
                routeName: '/track',
              ),
              const SizedBox(height: 16),

              if (_user == null)
                _buildHomeCard(
                  context,
                  icon: Icons.login,
                  title: 'تسجيل الدخول',
                  subtitle: 'سجل الدخول لمتابعة بلاغاتك',
                  routeName: '/login',
                )
              else
                _buildHomeCard(
                  context,
                  icon: Icons.person,
                  title: 'بلاغاتي',
                  subtitle: 'عرض كل البلاغات التي قدمتها',
                  routeName: '/my_reports',
                ),

              if (_user != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton(
                    onPressed: _logout,
                    child: const Text('تسجيل الخروج'),
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
              const SnackBar(content: Text('صفحة بلاغاتي (تحت الإنشاء)'))
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
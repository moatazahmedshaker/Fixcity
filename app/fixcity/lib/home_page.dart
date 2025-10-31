// lib/home_page.dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة البلاغات الموحدة'),
        actions: [
          // This button is a "secret" way to get to your admin panel
          // You can also just type /admin in the URL bar on web
          TextButton(
            child: const Text('Admin', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).pushNamed('/admin');
            },
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
                'ساعدنا في حل مدينتك أفضل مكان للعيش',
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
                subtitle: 'تابع حالة البلاغ المقدم',
                routeName: '/track',
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
          Navigator.of(context).pushNamed(routeName);
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
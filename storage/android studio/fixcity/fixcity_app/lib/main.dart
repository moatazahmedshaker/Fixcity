import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});  // ← CHANGED to super.key

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixCity مصر',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});  // ← CHANGED to super.key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FixCity مصر'),
        backgroundColor: const Color(0xFFD71828),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.report_problem,
              size: 80,
              color: Color(0xFFD71828),
            ),
            const SizedBox(height: 20),
            const Text(
              'مرحباً بكم في FixCity',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                debugPrint('Report button pressed!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD71828),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('الإبلاغ عن مشكلة'),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                debugPrint('Track button pressed!');
              },
              child: const Text('تتبع بلاغ'),
            ),
          ],
        ),
      ),
    );
  }
}
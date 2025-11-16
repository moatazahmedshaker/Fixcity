import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/problem.dart'; 

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}
class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;
  void _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/admin');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم - كل البلاغات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('reports')
            .select()
            .order('created_at', ascending: false)
            .limit(100) 
            .then((data) => data.cast<Map<String, dynamic>>().toList()),
            
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد بلاغات حالياً.'));
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ في تحميل البيانات: ${snapshot.error}'));
          }
          final reports = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('الكود')),
                  DataColumn(label: Text('العنوان')),
                  DataColumn(label: Text('الفئة')),
                  DataColumn(label: Text('الحالة')),
                  DataColumn(label: Text('تاريخ الإنشاء')),
                  DataColumn(label: Text('تفاصيل')),
                ],
                rows: reports.map((data) {
                  final Problem problem = Problem.fromSupabase(data);
                  final DateTime createdAt = DateTime.parse(data['created_at']); 
                  final formattedDate = '${createdAt.year}/${createdAt.month}/${createdAt.day}';
                  return DataRow(
                    cells: [
                      DataCell(Text(problem.reportCode)),
                      DataCell(Text(problem.title)),
                      DataCell(Text(problem.category)),
                      DataCell(Text(problem.status)),
                      DataCell(Text(formattedDate)),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/admin/report/${data['id']}');
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
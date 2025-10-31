// lib/admin/admin_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/problem.dart'; // We reuse our model

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _logout() {
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة التحكم - كل البلاغات'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // This Stream listens for real-time changes in the 'reports' collection
        stream: _firestore.collection('reports').orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('لا توجد بلاغات حالياً.'));
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ في تحميل البيانات.'));
          }

          // We have data, let's build the table
          final reports = snapshot.data!.docs;

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
                rows: reports.map((doc) {
                  // Parse the document into our Problem object
                  final problem = Problem.fromJson(doc);
                  final createdAt = problem.createdAt.toDate();
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
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            // Navigate to the details page with the report's ID
                            Navigator.of(context).pushNamed('/admin/report/${problem.id}');
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
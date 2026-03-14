import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/problem.dart';
import '../login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;
  String _filterStatus = 'all';

  static const _green = Color(0xFF2D6A4F);
  static const _navy = Color(0xFF0B1F3A);

  void _logout() async {
    await supabase.auth.signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/admin');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'in_progress': return const Color(0xFF1A56DB);
      case 'resolved': return _green;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'in_progress': return 'جارٍ العمل';
      case 'resolved': return 'تم الحل';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.location_pin, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          RichText(text: const TextSpan(
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            children: [TextSpan(text: 'Fix'), TextSpan(text: 'City', style: TextStyle(color: Color(0xFF52B788)))],
          )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: const Text('Admin', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.logout_outlined, size: 20), onPressed: _logout, tooltip: 'تسجيل الخروج'),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('reports').select().order('created_at', ascending: false).limit(100)
            .then((data) => data.cast<Map<String, dynamic>>().toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DashboardSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final allReports = snapshot.data ?? [];
          final filtered = _filterStatus == 'all'
              ? allReports
              : allReports.where((r) => r['status'] == _filterStatus).toList();

          // Stats
          final pending = allReports.where((r) => r['status'] == 'pending').length;
          final inProgress = allReports.where((r) => r['status'] == 'in_progress').length;
          final resolved = allReports.where((r) => r['status'] == 'resolved').length;

          return Column(children: [
            // Stats header
            Container(
              color: _navy,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(children: [
                _StatChip(value: '${allReports.length}', label: 'الكل', color: Colors.white70, selected: _filterStatus == 'all', onTap: () => setState(() => _filterStatus = 'all')),
                const SizedBox(width: 8),
                _StatChip(value: '$pending', label: 'انتظار', color: const Color(0xFFF59E0B), selected: _filterStatus == 'pending', onTap: () => setState(() => _filterStatus = 'pending')),
                const SizedBox(width: 8),
                _StatChip(value: '$inProgress', label: 'جارٍ', color: const Color(0xFF60A5FA), selected: _filterStatus == 'in_progress', onTap: () => setState(() => _filterStatus = 'in_progress')),
                const SizedBox(width: 8),
                _StatChip(value: '$resolved', label: 'محلول', color: const Color(0xFF52B788), selected: _filterStatus == 'resolved', onTap: () => setState(() => _filterStatus = 'resolved')),
              ]),
            ),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade200),
                      const SizedBox(height: 12),
                      Text('لا توجد بلاغات', style: TextStyle(color: Colors.grey.shade400)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final data = filtered[index];
                        final problem = Problem.fromSupabase(data);
                        final statusColor = _statusColor(problem.status);
                        final date = problem.createdAt;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.report_problem_outlined, color: statusColor, size: 22),
                            ),
                            title: Text(problem.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const SizedBox(height: 4),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(_statusLabel(problem.status), style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 8),
                                Text(problem.reportCode, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, letterSpacing: 0.5)),
                              ]),
                              const SizedBox(height: 2),
                              Text('${date.year}/${date.month}/${date.day}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                            ]),
                            trailing: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.edit_outlined, size: 18, color: _green),
                              ),
                              onPressed: () => Navigator.of(context).pushNamed('/admin/report/${data['id']}'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatChip({required this.value, required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color.withOpacity(0.5) : Colors.transparent),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        ]),
      ),
    );
  }
}

class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();
  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _bone({double height = 16, double? width, double radius = 8}) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        height: height, width: width,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          FadeTransition(opacity: _anim, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _bone(height: 14, width: 180),
            const SizedBox(height: 8),
            _bone(height: 10, width: 120),
            const SizedBox(height: 4),
            _bone(height: 10, width: 80),
          ])),
        ]),
      ),
    );
  }
}


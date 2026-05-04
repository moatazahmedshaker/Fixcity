import '../theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/problem.dart';
import '../login_page.dart';
import '../main.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;
  String _filterStatus = 'all';
  List<Map<String, dynamic>> _allReports = [];
  bool _loading = true;

  static const _red   = Color(0xFFCC0000);
  static const _dark  = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      final data = await supabase.from('reports').select().order('created_at', ascending: false).limit(200);
      if (mounted) setState(() {
        _allReports = data.cast<Map<String, dynamic>>();
        _loading    = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logout() async {
    await supabase.auth.signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/admin');
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':    return const Color(0xFFF59E0B);
      case 'in_progress':return const Color(0xFF1A56DB);
      case 'resolved':   return kRed;
      default:           return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    final isAr = appLocale.value.languageCode == 'ar';
    if (isAr) {
      switch (s) {
        case 'pending':    return 'قيد الانتظار';
        case 'in_progress':return 'جارٍ العمل';
        case 'resolved':   return 'تم الحل';
        default:           return s;
      }
    } else {
      switch (s) {
        case 'pending':    return 'Pending';
        case 'in_progress':return 'In Progress';
        case 'resolved':   return 'Resolved';
        default:           return s;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterStatus == 'all'
        ? _allReports
        : _allReports.where((r) => r['status'] == _filterStatus).toList();

    final pending    = _allReports.where((r) => r['status'] == 'pending').length;
    final inProgress = _allReports.where((r) => r['status'] == 'in_progress').length;
    final resolved   = _allReports.where((r) => r['status'] == 'resolved').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: kDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.location_pin, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          RichText(text: const TextSpan(
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            children: [TextSpan(text: 'Fix'), TextSpan(text: 'City', style: TextStyle(color: Color(0xFF185FA5)))],
          )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: const Text('Admin', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ),
        ]),
        actions: [
          // Pending badge
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 12),
              child: Stack(children: [
                const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Center(child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
                  ),
                ),
              ]),
            ),
          IconButton(icon: const Icon(Icons.refresh_outlined, size: 20), onPressed: _loadReports),
          IconButton(icon: const Icon(Icons.logout_outlined, size: 20), onPressed: _logout),
        ],
      ),
      body: Column(children: [
        // Filter chips with live counts
        Container(
          color: kDark,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            _StatChip(value: '${_allReports.length}', label: appLocale.value.languageCode == 'ar' ? 'الكل' : 'All',   color: Colors.white70,           selected: _filterStatus == 'all',        onTap: () => setState(() => _filterStatus = 'all')),
            const SizedBox(width: 8),
            _StatChip(value: '$pending',              label: appLocale.value.languageCode == 'ar' ? 'انتظار' : 'Pending', color: const Color(0xFFF59E0B),  selected: _filterStatus == 'pending',    onTap: () => setState(() => _filterStatus = 'pending')),
            const SizedBox(width: 8),
            _StatChip(value: '$inProgress',           label: appLocale.value.languageCode == 'ar' ? 'جارٍ' : 'Active',   color: const Color(0xFF60A5FA),  selected: _filterStatus == 'in_progress',onTap: () => setState(() => _filterStatus = 'in_progress')),
            const SizedBox(width: 8),
            _StatChip(value: '$resolved',             label: appLocale.value.languageCode == 'ar' ? 'محلول' : 'Resolved',  color: const Color(0xFF185FA5),  selected: _filterStatus == 'resolved',   onTap: () => setState(() => _filterStatus = 'resolved')),
          ]),
        ),

        Expanded(
          child: _loading
              ? const _DashboardSkeleton()
              : filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade200),
                      const SizedBox(height: 12),
                      Text(appLocale.value.languageCode == 'ar' ? 'لا توجد بلاغات' : 'No reports found', style: TextStyle(color: Colors.grey.shade400)),
                    ]))
                  : RefreshIndicator(
                      color: kRed,
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final data    = filtered[index];
                          final problem = Problem.fromSupabase(data);
                          final sc      = _statusColor(problem.status);
                          final date    = problem.createdAt;
                          final hasFixPhoto = (data['fix_photo_url'] ?? '').toString().isNotEmpty;
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
                                decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.report_problem_outlined, color: sc, size: 22),
                              ),
                              title: Text(problem.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kDark)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                    child: Text(_statusLabel(problem.status),
                                        style: TextStyle(fontSize: 10, color: sc, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 6),
                                  if ((data['district'] ?? '').toString().isNotEmpty)
                                    Text(data['district'], style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                                  if (hasFixPhoto) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.photo_camera, size: 12, color: kRed),
                                  ],
                                ]),
                                const SizedBox(height: 2),
                                Text('${date.year}/${date.month}/${date.day}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                              ]),
                              trailing: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.edit_outlined, size: 18, color: kRed),
                                ),
                                onPressed: () async {
                                  await Navigator.of(context).pushNamed('/admin/report/${data['id']}');
                                  // Refresh after returning from detail page
                                  _loadReports();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => FadeTransition(
        opacity: _anim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 14, width: 180, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(height: 10, width: 120, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 4),
              Container(height: 10, width: 80,  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
            ])),
          ]),
        ),
      ),
    );
  }
}

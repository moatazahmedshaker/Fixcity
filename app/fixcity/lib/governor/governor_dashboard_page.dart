import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/problem.dart';

class GovernorDashboardPage extends StatefulWidget {
  const GovernorDashboardPage({super.key});
  @override
  State<GovernorDashboardPage> createState() => _GovernorDashboardPageState();
}

class _GovernorDashboardPageState extends State<GovernorDashboardPage> {
  final supabase = Supabase.instance.client;
  String? _district;
  String? _governorName;
  String _filter = 'all';
  bool _profileLoading = true;

  static const _green = Color(0xFF2D6A4F);
  static const _navy  = Color(0xFF0B1F3A);

  final _filters = ['all', 'pending', 'in_progress', 'resolved'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final p = await supabase.from('profiles').select('governor_district').eq('id', user.id).single();
    setState(() {
      _district = p['governor_district'];
      _governorName = user.email;
      _profileLoading = false;
    });
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'all':        return 'الكل';
      case 'pending':    return 'قيد الانتظار';
      case 'in_progress':return 'جارٍ العمل';
      case 'resolved':   return 'تم الحل';
      default:           return f;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':    return const Color(0xFFF59E0B);
      case 'in_progress':return const Color(0xFF1A56DB);
      case 'resolved':   return _green;
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profileLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _green)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Text('لوحة رئيس الحي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          if (_district != null)
            Text(_district!, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
        ]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20),
            onPressed: () async {
              await supabase.auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/governor');
            },
          ),
        ],
      ),
      body: Column(children: [
        // Filter chips
        Container(
          color: _navy,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _green : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? _green : Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(_filterLabel(f),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Reports list
        Expanded(
          child: _district == null
              ? const Center(child: Text('لم يتم تعيين حي لهذا الحساب'))
              : FutureBuilder<List<Map<String, dynamic>>>(
                  future: _district == null ? Future.value([]) :
                    supabase.from('reports').select()
                      .eq('district', _district!)
                      .order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _green));
                    }
                    var reports = snapshot.data ?? [];
                    if (_filter != 'all') {
                      reports = reports.where((r) => r['status'] == _filter).toList();
                    }
                    if (reports.isEmpty) {
                      return Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade200),
                          const SizedBox(height: 12),
                          Text('لا توجد بلاغات', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                        ]),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reports.length,
                      itemBuilder: (context, i) {
                        final r = reports[i];
                        final status = r['status'] ?? 'pending';
                        final color = _statusColor(status);
                        final date = DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now();
                        final hasFixPhoto = r['fix_photo_url'] != null && r['fix_photo_url'].toString().isNotEmpty;
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/governor/report/${r['id']}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.report_problem_outlined, color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(r['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(_filterLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (hasFixPhoto)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('📷 صورة الإصلاح', style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w600)),
                                    ),
                                ]),
                                const SizedBox(height: 2),
                                Text('${date.year}/${date.month}/${date.day}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                              ])),
                              Icon(Icons.chevron_right, color: Colors.grey.shade300),
                            ]),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/problem.dart';
import 'translations.dart';
import 'main.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});
  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  final _supabase = Supabase.instance.client;

  static const _green = Color(0xFF2D6A4F);
  static const _navy = Color(0xFF0B1F3A);

  Future<List<Map<String, dynamic>>> _fetchMyReports() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    final response = await _supabase
        .from('reports')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return response.cast<Map<String, dynamic>>();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':     return const Color(0xFFF59E0B);
      case 'in_progress': return const Color(0xFF1A56DB);
      case 'resolved':    return _green;
      default:            return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':     return Icons.schedule_outlined;
      case 'in_progress': return Icons.construction_outlined;
      case 'resolved':    return Icons.check_circle_outline;
      default:            return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          t('my_reports', lang: lang),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _MyReportsSkeleton();
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.error_outline, size: 56, color: Colors.red.shade200),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'حدث خطأ أثناء التحميل' : 'Something went wrong',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: Text(isAr ? 'حاول مجدداً' : 'Try again',
                      style: const TextStyle(color: _green)),
                ),
              ]),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return _EmptyReports(isAr: isAr);
          }

          return RefreshIndicator(
            color: _green,
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final data = reports[index];
                final problem = Problem.fromSupabase(data);
                final statusColor = _statusColor(problem.status);
                final statusIcon = _statusIcon(problem.status);
                final date = problem.createdAt;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showReportDetail(context, problem, statusColor, statusIcon, isAr, lang),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        // Status icon
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        // Info
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(problem.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 5),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t(problem.status, lang: lang),
                                  style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Text(problem.reportCode,
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade400, letterSpacing: 0.5)),
                          ]),
                          const SizedBox(height: 3),
                          Text('${date.day}/${date.month}/${date.year}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ])),
                        Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
                      ]),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showReportDetail(
    BuildContext context,
    Problem problem,
    Color statusColor,
    IconData statusIcon,
    bool isAr,
    String lang,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(problem.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _navy),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(t(problem.status, lang: lang),
                    style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                _DetailCard(children: [
                  _DetailRow(icon: Icons.tag, label: isAr ? 'الكود' : 'Code', value: problem.reportCode),
                  _DetailRow(icon: Icons.category_outlined, label: isAr ? 'الفئة' : 'Category', value: t(problem.category, lang: lang)),
                  _DetailRow(icon: Icons.description_outlined, label: isAr ? 'الوصف' : 'Description', value: problem.description),
                  _DetailRow(icon: Icons.calendar_today_outlined, label: isAr ? 'تاريخ التقديم' : 'Submitted',
                      value: '${problem.createdAt.day}/${problem.createdAt.month}/${problem.createdAt.year}'),
                ]),
                const SizedBox(height: 12),
                if (problem.photoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(problem.photoUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                // Track button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/track');
                    },
                    icon: const Icon(Icons.manage_search_outlined, size: 18),
                    label: Text(isAr ? 'تابع هذا البلاغ' : 'Track this report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyReports extends StatelessWidget {
  final bool isAr;
  const _EmptyReports({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_outlined, size: 48, color: Color(0xFF2D6A4F)),
          ),
          const SizedBox(height: 24),
          Text(
            isAr ? 'لا توجد بلاغات بعد' : 'No reports yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0B1F3A)),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'بلاغاتك ستظهر هنا بعد تقديمها' : 'Your submitted reports will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/report'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(isAr ? 'تقديم أول بلاغ' : 'Submit your first report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────

class _MyReportsSkeleton extends StatefulWidget {
  const _MyReportsSkeleton();
  @override
  State<_MyReportsSkeleton> createState() => _MyReportsSkeletonState();
}

class _MyReportsSkeletonState extends State<_MyReportsSkeleton> with SingleTickerProviderStateMixin {
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
      itemCount: 5,
      itemBuilder: (_, __) => FadeTransition(
        opacity: _anim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 14, width: 200, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(height: 10, width: 120, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 4),
              Container(height: 10, width: 80, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 140),
              child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0B1F3A))),
            ),
          ]),
        ]),
      ),
      Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14),
    ]);
  }
}

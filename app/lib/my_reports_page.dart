import 'theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/problem.dart';
import 'translations.dart';
import 'main.dart';
import 'login_page.dart';
import 'package:url_launcher/url_launcher.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});
  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  final _supabase = Supabase.instance.client;

  static const _red   = Color(0xFFCC0000);
  static const _dark  = Color(0xFF1A1A2E);

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

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':     return const Color(0xFFF59E0B);
      case 'in_progress': return const Color(0xFF1A56DB);
      case 'resolved':    return kRed;
      default:            return Colors.grey;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'pending':     return Icons.schedule_outlined;
      case 'in_progress': return Icons.construction_outlined;
      case 'resolved':    return Icons.check_circle_outline;
      default:            return Icons.help_outline;
    }
  }

  // ── Ping report ──────────────────────────────────────────────────────────
  Future<void> _pingReport(String reportId, int currentPingCount, String lang) async {
    final isAr = lang == 'ar';
    try {
      await _supabase.from('reports').update({
        'pinged_at':  DateTime.now().toIso8601String(),
        'ping_count': currentPingCount + 1,
      }).eq('id', reportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? '🔔 تم إرسال تنبيه للمسؤول' : '🔔 Reminder sent to the responsible team'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'فشل إرسال التنبيه' : 'Failed to send reminder'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── WhatsApp share ────────────────────────────────────────────────────────
  Future<void> _shareOnWhatsApp(Problem problem, Map<String, dynamic> data, String lang) async {
    final isAr = lang == 'ar';
    // Fetch user's phone from profiles
    String? userPhone;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final profile = await _supabase.from('profiles').select('phone').eq('id', userId).single();
        userPhone = profile['phone']?.toString();
      }
    } catch (_) {}
    final status = problem.status;
    String statusText;
    if (isAr) {
      switch (status) {
        case 'pending':    statusText = 'قيد الانتظار ⏳'; break;
        case 'in_progress':statusText = 'جارٍ العمل 🔧'; break;
        case 'resolved':   statusText = 'تم الحل ✅'; break;
        default:           statusText = status;
      }
    } else {
      switch (status) {
        case 'pending':    statusText = 'Pending ⏳'; break;
        case 'in_progress':statusText = 'In Progress 🔧'; break;
        case 'resolved':   statusText = 'Resolved ✅'; break;
        default:           statusText = status;
      }
    }

    final message = isAr
        ? '📍 *تقرير FixCity*\n\n'
          '🔖 كود البلاغ: *${problem.reportCode}*\n'
          '📂 الفئة: ${problem.category}\n'
          '📊 الحالة: $statusText\n'
          '📅 تاريخ التقديم: ${problem.createdAt.day}/${problem.createdAt.month}/${problem.createdAt.year}\n\n'
          '${(data["district"] ?? "").toString().isNotEmpty ? "🏙️ الحي: ${data["district"]}\n" : ""}'
          '📝 الوصف: ${problem.description}'
        : '📍 *FixCity Report*\n\n'
          '🔖 Report Code: *${problem.reportCode}*\n'
          '📂 Category: ${problem.category}\n'
          '📊 Status: $statusText\n'
          '📅 Submitted: ${problem.createdAt.day}/${problem.createdAt.month}/${problem.createdAt.year}\n\n'
          '${(data["district"] ?? "").toString().isNotEmpty ? "🏙️ District: ${data["district"]}\n" : ""}'
          '📝 Description: ${problem.description}';

    final encoded = Uri.encodeComponent(message);
    // If we have the user's phone, open their own WhatsApp with the message
    // Otherwise open WhatsApp share picker
    final phone = userPhone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final waNumber = phone.startsWith('0') ? '2$phone' : phone; // Egypt: prefix with country code 20
    final url = waNumber.length >= 12
        ? Uri.parse('https://wa.me/$waNumber?text=' + encoded)
        : Uri.parse('https://wa.me/?text=' + encoded);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'لم يتم العثور على WhatsApp' : 'WhatsApp not found'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    // ── Login guard ─────────────────────────────────────────────────────
    if (_supabase.auth.currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(t('my_reports', lang: lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _GuestView(
          isAr: isAr,
          icon: Icons.folder_outlined,
          titleAr: 'بلاغاتي',
          titleEn: 'My Reports',
          subtitleAr: 'سجّل دخول لعرض بلاغاتك ومتابعة حالتها',
          subtitleEn: 'Login to view and track your submitted reports',
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(t('my_reports', lang: lang),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _MyReportsSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red.shade200),
              const SizedBox(height: 12),
              Text(isAr ? 'حدث خطأ أثناء التحميل' : 'Something went wrong',
                  style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {}),
                child: Text(isAr ? 'حاول مجدداً' : 'Try again',
                    style: const TextStyle(color: kRed)),
              ),
            ]));
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) return _EmptyReports(isAr: isAr);

          return RefreshIndicator(
            color: kRed,
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final data    = reports[index];
                final problem = Problem.fromSupabase(data);
                final sc      = _statusColor(problem.status);
                final si      = _statusIcon(problem.status);
                final date    = problem.createdAt;
                final hasFixPhoto = (data['fix_photo_url'] ?? '').toString().isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showReportDetail(context, problem, data, sc, si, isAr, lang),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(si, color: sc, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(problem.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kDark),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 5),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text(t(problem.status, lang: lang),
                                  style: TextStyle(fontSize: 10, color: sc, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 6),
                            if (hasFixPhoto)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: kRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.check_circle, color: kRed, size: 10),
                                  SizedBox(width: 3),
                                  Text('تم الإصلاح', style: TextStyle(fontSize: 9, color: kRed, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            const SizedBox(width: 6),
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

  void _showReportDetail(BuildContext context, Problem problem, Map<String, dynamic> data,
      Color sc, IconData si, bool isAr, String lang) {
    final fixPhotoUrl = data['fix_photo_url']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(si, color: sc, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(problem.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kDark),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(t(problem.status, lang: lang),
                    style: TextStyle(fontSize: 12, color: sc, fontWeight: FontWeight.w600)),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                _DetailCard(children: [
                  _DetailRow(icon: Icons.tag, label: isAr ? 'الكود' : 'Code', value: problem.reportCode),
                  _DetailRow(icon: Icons.category_outlined, label: isAr ? 'الفئة' : 'Category', value: t(problem.category, lang: lang)),
                  if ((data['district'] ?? '').toString().isNotEmpty)
                    _DetailRow(icon: Icons.location_city_outlined, label: isAr ? 'الحي' : 'District', value: data['district']),
                  _DetailRow(icon: Icons.description_outlined, label: isAr ? 'الوصف' : 'Description', value: problem.description),
                  _DetailRow(icon: Icons.calendar_today_outlined, label: isAr ? 'تاريخ التقديم' : 'Submitted',
                      value: '${problem.createdAt.day}/${problem.createdAt.month}/${problem.createdAt.year}'),
                ]),
                const SizedBox(height: 12),

                // Before photo
                if (problem.photoUrl != null) ...[
                  Align(alignment: Alignment.centerRight,
                      child: Text(isAr ? 'صورة المشكلة' : 'Problem Photo',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kDark))),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(problem.photoUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],

                // After fix photo
                if (fixPhotoUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: kRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: kRed, size: 18),
                      const SizedBox(width: 8),
                      Text(isAr ? '✅ تم الإصلاح — صورة الإصلاح:' : '✅ Fixed — After photo:',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kRed)),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(fixPhotoUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],

                const SizedBox(height: 16),
                // Ping button (only for pending/in_progress)
                if (problem.status != 'resolved') ...[
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final pingCount = (data['ping_count'] ?? 0) as int;
                        await _pingReport(problem.id!, pingCount, lang);
                        if (mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.notifications_outlined, size: 18, color: Colors.orange),
                      label: Text(
                        isAr ? '🔔 تنبيه المسؤول (لم يتم الحل بعد)' : '🔔 Ping — Report still unresolved',
                        style: const TextStyle(color: Colors.orange),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // WhatsApp share
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareOnWhatsApp(problem, data, lang),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: Text(isAr ? 'مشاركة عبر WhatsApp' : 'Share on WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Track button
                SizedBox(
                  width: double.infinity, height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/track');
                    },
                    icon: const Icon(Icons.manage_search_outlined, size: 18),
                    label: Text(isAr ? 'تابع هذا البلاغ' : 'Track this report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kRed,
                      side: const BorderSide(color: kRed),
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
            decoration: BoxDecoration(color: const Color(0xFFCC0000).withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.folder_open_outlined, size: 48, color: Color(0xFFCC0000)),
          ),
          const SizedBox(height: 24),
          Text(isAr ? 'لا توجد بلاغات بعد' : 'No reports yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text(isAr ? 'بلاغاتك ستظهر هنا بعد تقديمها' : 'Your submitted reports will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400, height: 1.5)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/report'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(isAr ? 'تقديم أول بلاغ' : 'Submit your first report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC0000), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 90),
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
              Container(height: 10, width: 80,  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

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
              child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            ),
          ]),
        ]),
      ),
      Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14),
    ]);
  }
}
class _GuestView extends StatelessWidget {
  final bool isAr;
  final IconData icon;
  final String titleAr, titleEn, subtitleAr, subtitleEn;
  const _GuestView({required this.isAr, required this.icon, required this.titleAr,
      required this.titleEn, required this.subtitleAr, required this.subtitleEn});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 100),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 96, height: 96,
              decoration: BoxDecoration(color: kRed.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: kRed)),
          const SizedBox(height: 24),
          Text(isAr ? titleAr : titleEn, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kDark)),
          const SizedBox(height: 10),
          Text(isAr ? subtitleAr : subtitleEn, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: kGrey, height: 1.6)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: Text(isAr ? 'تسجيل الدخول' : 'Log In',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed('/signup'),
              style: OutlinedButton.styleFrom(foregroundColor: kBlue,
                  side: const BorderSide(color: kBlue, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(isAr ? 'إنشاء حساب جديد' : 'Create Account',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

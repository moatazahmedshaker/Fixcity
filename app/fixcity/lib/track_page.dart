import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/problem.dart';
import 'login_page.dart';
import 'translations.dart';
import 'main.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});
  @override
  TrackPageState createState() => TrackPageState();
}

class TrackPageState extends State<TrackPage> {
  final supabase = Supabase.instance.client;
  final _codeController = TextEditingController();

  Problem? _foundProblem;
  List<StatusUpdate> _updates = [];
  bool _isLoading = false;
  String? _errorMessage;

  static const _green = Color(0xFF2D6A4F);
  static const _greenLight = Color(0xFF52B788);
  static const _navy = Color(0xFF0B1F3A);

  Future<void> _trackProblem() async {
    final lang = appLocale.value.languageCode;
    if (_codeController.text.trim().isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = null; _foundProblem = null; _updates = []; });
    try {
      final reportResponse = await supabase.from('reports').select().eq('report_code', _codeController.text.trim().toUpperCase()).limit(1).single();
      _foundProblem = Problem.fromSupabase(reportResponse);
      final updatesResponse = await supabase.from('status_updates').select().eq('report_id', _foundProblem!.id!).order('updated_at', ascending: false);
      if (updatesResponse.isNotEmpty) {
        _updates = updatesResponse.map((d) => StatusUpdate.fromSupabase(d)).toList();
      }
    } on PostgrestException {
      _errorMessage = t('not_found', lang: lang);
    } catch (e) {
      _errorMessage = '${t('error_message', lang: lang)} ${e.toString()}';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'in_progress': return const Color(0xFF1A56DB);
      case 'resolved': return const Color(0xFF2D6A4F);
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.schedule_outlined;
      case 'in_progress': return Icons.construction_outlined;
      case 'resolved': return Icons.check_circle_outline;
      default: return Icons.help_outline;
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
        title: Text(t('track_page_title', lang: lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(children: [
        // Search header
        Container(
          color: _navy,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 14, color: _navy, fontWeight: FontWeight.w600, letterSpacing: 1),
                  decoration: InputDecoration(
                    hintText: t('enter_code', lang: lang),
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.normal, letterSpacing: 0),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF2D6A4F)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (_) => _trackProblem(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _trackProblem,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
              ),
            ),
          ]),
        ),

        // Body
        Expanded(
          child: _isLoading
              ? const _TrackSkeleton()
              : _errorMessage != null
                  ? _ErrorState(message: _errorMessage!, isAr: isAr)
                  : _foundProblem != null
                      ? _ResultView(problem: _foundProblem!, updates: _updates, lang: lang, isAr: isAr, statusColor: _statusColor, statusIcon: _statusIcon)
                      : _EmptyState(isAr: isAr),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isAr;
  const _EmptyState({required this.isAr});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.manage_search_outlined, size: 72, color: Colors.grey.shade200),
      const SizedBox(height: 16),
      Text(isAr ? 'أدخل كود البلاغ للبحث' : 'Enter a report code to search',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
      Text(isAr ? 'الكود مكوّن من 10 أحرف وأرقام' : '10-character alphanumeric code',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade300)),
    ]));
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final bool isAr;
  const _ErrorState({required this.message, required this.isAr});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off_outlined, size: 64, color: Colors.red.shade200),
      const SizedBox(height: 16),
      Text(message, style: TextStyle(fontSize: 15, color: Colors.red.shade400, fontWeight: FontWeight.w500)),
    ]));
  }
}

class _ResultView extends StatelessWidget {
  final Problem problem;
  final List<StatusUpdate> updates;
  final String lang;
  final bool isAr;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;

  const _ResultView({required this.problem, required this.updates, required this.lang, required this.isAr, required this.statusColor, required this.statusIcon});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(problem.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Status hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(statusIcon(problem.status), color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t(problem.status, lang: lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
              Text(problem.reportCode, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, letterSpacing: 1)),
            ])),
          ]),
        ),

        const SizedBox(height: 20),

        // Report details card
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            _DetailTile(icon: Icons.title_outlined, label: isAr ? 'العنوان' : 'Title', value: problem.title),
            _Divider(),
            _DetailTile(icon: Icons.category_outlined, label: isAr ? 'الفئة' : 'Category', value: t(problem.category, lang: lang)),
            _Divider(),
            _DetailTile(icon: Icons.description_outlined, label: isAr ? 'الوصف' : 'Description', value: problem.description),
            _Divider(),
            _DetailTile(
              icon: Icons.calendar_today_outlined,
              label: isAr ? 'تاريخ التقديم' : 'Submitted',
              value: '${problem.createdAt.year}/${problem.createdAt.month}/${problem.createdAt.day}',
            ),
          ]),
        ),

        // Photo
        if (problem.photoUrl != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(problem.photoUrl!, width: double.infinity, height: 200, fit: BoxFit.cover),
          ),
        ],

        const SizedBox(height: 24),

        // Updates timeline
        Text(isAr ? 'سجل التحديثات' : 'Update History',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0B1F3A))),
        const SizedBox(height: 12),

        if (updates.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.grey.shade300, size: 20),
              const SizedBox(width: 10),
              Text(isAr ? 'لا توجد تحديثات حتى الآن' : 'No updates yet',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ]),
          )
        else
          ...updates.asMap().entries.map((entry) {
            final update = entry.value;
            final isLast = entry.key == updates.length - 1;
            final date = update.updatedAt;
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(color: Color(0xFF2D6A4F), shape: BoxShape.circle),
                ),
                if (!isLast) Container(width: 2, height: 56, color: Colors.grey.shade200),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(update.text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0B1F3A))),
                      const SizedBox(height: 4),
                      Text('${date.year}/${date.month}/${date.day}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ]),
                  ),
                ),
              ),
            ]);
          }),
      ]),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 120),
            child: Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF0B1F3A), fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16);
  }
}

class _TrackSkeleton extends StatefulWidget {
  const _TrackSkeleton();
  @override
  State<_TrackSkeleton> createState() => _TrackSkeletonState();
}

class _TrackSkeletonState extends State<_TrackSkeleton> with SingleTickerProviderStateMixin {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _bone(height: 80, radius: 16),
        const SizedBox(height: 20),
        _bone(height: 180, radius: 16),
        const SizedBox(height: 16),
        _bone(height: 200, radius: 16),
        const SizedBox(height: 20),
        _bone(height: 14, width: 120),
        const SizedBox(height: 12),
        _bone(height: 70, radius: 12),
        const SizedBox(height: 8),
        _bone(height: 70, radius: 12),
      ]),
    );
  }
}


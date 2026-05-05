import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'main.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});
  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _supabase = Supabase.instance.client;
  int _points = 0;
  int _reportCount = 0;
  int _resolvedCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isGuest = false;

  Future<void> _load() async {
    final user = _supabase.auth.currentUser;
    if (user == null) { setState(() { _loading = false; _isGuest = true; }); return; }
    try {
      final profile = await _supabase.from('profiles').select('points').eq('id', user.id).single();
      final reports = await _supabase.from('reports').select('status').eq('user_id', user.id);
      final list = (reports as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() {
        _points       = profile['points'] ?? 0;
        _reportCount  = list.length;
        _resolvedCount= list.where((r) => r['status'] == 'resolved').length;
        _loading      = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    final badges = [
      {'icon': '🏅', 'title': isAr ? 'أول بلاغ'       : 'First Report',    'desc': isAr ? 'قدّمت أول بلاغ'          : 'Submitted first report',       'earned': _reportCount >= 1,  'req': 1},
      {'icon': '🥉', 'title': isAr ? '5 بلاغات'        : '5 Reports',       'desc': isAr ? 'قدّمت 5 بلاغات'          : 'Submitted 5 reports',          'earned': _reportCount >= 5,  'req': 5},
      {'icon': '🥈', 'title': isAr ? '10 بلاغات'       : '10 Reports',      'desc': isAr ? 'قدّمت 10 بلاغات'         : 'Submitted 10 reports',         'earned': _reportCount >= 10, 'req': 10},
      {'icon': '🥇', 'title': isAr ? 'محارب المدينة'   : 'City Warrior',    'desc': isAr ? 'قدّمت 25 بلاغ'           : 'Submitted 25 reports',         'earned': _reportCount >= 25, 'req': 25},
      {'icon': '✅', 'title': isAr ? 'أول حل'           : 'First Resolved',  'desc': isAr ? 'تم حل أول بلاغ لك'       : 'First report resolved',        'earned': _resolvedCount >= 1,'req': 1},
      {'icon': '🏆', 'title': isAr ? 'بطل الحي'         : 'District Hero',   'desc': isAr ? 'تم حل 10 بلاغات لك'      : '10 reports resolved',          'earned': _resolvedCount >=10,'req': 10},
    ];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kDark,
        title: Text(isAr ? 'الإنجازات' : 'Achievements',
            style: const TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kRed))
          : _isGuest
              ? _GuestView(isAr: isAr)
              : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Points card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kDark, kDark2]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(children: [
                    const Text('⭐', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text('$_points', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: kWhite)),
                    Text(isAr ? 'نقطة' : 'Points', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _StatChip(value: '$_reportCount',   label: isAr ? 'بلاغ' : 'Reports'),
                      const SizedBox(width: 16),
                      _StatChip(value: '$_resolvedCount', label: isAr ? 'محلول' : 'Resolved'),
                    ]),
                  ]),
                ),
                const SizedBox(height: 24),

                Align(alignment: Alignment.centerRight,
                    child: Text(isAr ? 'الأوسمة' : 'Badges',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kDark))),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: badges.map((b) {
                    final earned = b['earned'] as bool;
                    return Container(
                      decoration: BoxDecoration(
                        color: earned ? kWhite : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: earned ? kRed.withOpacity(0.3) : Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(b['icon'] as String,
                            style: TextStyle(fontSize: 30, color: earned ? null : const Color(0xFFCCCCCC))),
                        const SizedBox(height: 6),
                        Text(b['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                color: earned ? kDark : kGrey)),
                        const SizedBox(height: 2),
                        Text(b['desc'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: earned ? kGrey : Colors.grey.shade400)),
                        if (!earned) ...[
                          const SizedBox(height: 2),
                          Text(isAr ? '🔒 مقفل' : '🔒 Locked',
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                        ],
                      ]),
                    );
                  }).toList(),
                ),
              ]),
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  const _StatChip({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: kWhite.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kWhite)),
      Text(label,  style: TextStyle(fontSize: 11, color: kWhite.withOpacity(0.6))),
    ]),
  );
}

class _GuestView extends StatelessWidget {
  final bool isAr;
  const _GuestView({required this.isAr});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(color: kRed.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_outlined, size: 44, color: kRed),
          ),
          const SizedBox(height: 20),
          Text(isAr ? 'سجّل دخول لعرض إنجازاتك 🏆' : 'Login to see your badges 🏆',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kDark)),
          const SizedBox(height: 8),
          Text(isAr ? 'اكسب نقاطاً وافتح الأوسمة بتقديم البلاغات'
                    : 'Earn points and unlock badges by submitting reports',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kGrey, height: 1.6)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: Text(isAr ? 'تسجيل الدخول' : 'Log In',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed('/signup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kBlue, side: const BorderSide(color: kBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? 'إنشاء حساب' : 'Create Account',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

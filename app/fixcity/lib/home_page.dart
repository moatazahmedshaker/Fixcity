import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'translations.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  User? _user;

  // Live data
  int _totalReports = 0;
  int _resolvedReports = 0;
  int _pendingReports = 0;
  List<Map<String, dynamic>> _recentReports = [];
  bool _statsLoading = true;
  bool _feedLoading = true;

  static const _green  = Color(0xFF2D6A4F);
  static const _greenLight = Color(0xFF52B788);
  static const _navy   = Color(0xFF0B1F3A);

  @override
  void initState() {
    super.initState();
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() => _user = data.session?.user);
    });
    _loadStats();
    _loadRecentReports();
  }

  Future<void> _loadStats() async {
    try {
      final all      = await _supabase.from('reports').select('id');
      final resolved = await _supabase.from('reports').select('id').eq('status', 'resolved');
      final pending  = await _supabase.from('reports').select('id').eq('status', 'pending');
      if (mounted) setState(() {
        _totalReports    = (all    as List).length;
        _resolvedReports = (resolved as List).length;
        _pendingReports  = (pending  as List).length;
        _statsLoading    = false;
      });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _loadRecentReports() async {
    try {
      final data = await _supabase
          .from('reports')
          .select('title, category, status, created_at, report_code')
          .order('created_at', ascending: false)
          .limit(4);
      if (mounted) setState(() {
        _recentReports = (data as List).cast<Map<String, dynamic>>();
        _feedLoading   = false;
      });
    } catch (_) {
      if (mounted) setState(() => _feedLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() { _statsLoading = true; _feedLoading = true; });
    await Future.wait([_loadStats(), _loadRecentReports()]);
  }

  void _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('snack_logout', lang: appLocale.value.languageCode)),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _toggleLang() {
    setState(() {
      appLocale.value = appLocale.value.languageCode == 'ar'
          ? const Locale('en')
          : const Locale('ar');
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':      return const Color(0xFFF59E0B);
      case 'in_progress':  return const Color(0xFF1A56DB);
      case 'resolved':     return _green;
      default:             return Colors.grey;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'cat_pothole':  return Icons.warning_amber_rounded;
      case 'cat_trash':    return Icons.delete_outline;
      case 'cat_lighting': return Icons.lightbulb_outline;
      default:             return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        color: _green,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: _navy,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: _navy,
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        RichText(text: TextSpan(
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                          children: [const TextSpan(text: 'Fix'), TextSpan(text: 'City', style: TextStyle(color: _greenLight))],
                        )),
                        const Spacer(),
                        _TopBarBtn(label: t('switch_lang', lang: lang), onTap: _toggleLang),
                        const SizedBox(width: 8),
                        _TopBarBtn(icon: Icons.admin_panel_settings_outlined, onTap: () => Navigator.of(context).pushNamed('/admin')),
                      ]),
                      const SizedBox(height: 16),
                      Text(t('welcome_title', lang: lang),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                      Text(t('welcome_subtitle', lang: lang),
                          style: const TextStyle(fontSize: 13, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Greeting card ──────────────────────────────────
                  if (_user != null) ...[
                    _GreetingCard(email: _user!.email ?? '', isAr: isAr, onLogout: _logout),
                    const SizedBox(height: 20),
                  ],

                  // ── Live stats bar ─────────────────────────────────
                  _LiveStatsBar(
                    total: _totalReports,
                    resolved: _resolvedReports,
                    pending: _pendingReports,
                    loading: _statsLoading,
                    isAr: isAr,
                  ),
                  const SizedBox(height: 24),

                  // ── Quick actions label ────────────────────────────
                  _SectionHeader(
                    label: isAr ? 'ماذا تريد أن تفعل؟' : 'What would you like to do?',
                  ),
                  const SizedBox(height: 12),

                  // ── Category quick-launch grid ─────────────────────
                  _CategoryGrid(isAr: isAr, lang: lang),
                  const SizedBox(height: 12),

                  // ── Action cards ───────────────────────────────────
                  _ActionCard(
                    icon: Icons.manage_search_outlined,
                    iconBg: const Color(0xFF1A56DB),
                    title: t('track_report', lang: lang),
                    subtitle: t('track_subtitle', lang: lang),
                    onTap: () => Navigator.of(context).pushNamed('/track'),
                  ),
                  const SizedBox(height: 12),
                  if (_user == null)
                    _ActionCard(
                      icon: Icons.login_outlined,
                      iconBg: const Color(0xFF7C3AED),
                      title: t('login', lang: lang),
                      subtitle: t('login_subtitle', lang: lang),
                      onTap: () => Navigator.of(context).pushNamed('/login'),
                    )
                  else
                    _ActionCard(
                      icon: Icons.folder_outlined,
                      iconBg: const Color(0xFFF59E0B),
                      title: t('my_reports', lang: lang),
                      subtitle: t('my_reports_subtitle', lang: lang),
                      onTap: () => Navigator.of(context).pushNamed('/my_reports'),
                    ),

                  const SizedBox(height: 28),

                  // ── Recent reports feed ────────────────────────────
                  _SectionHeader(
                    label: isAr ? 'أحدث البلاغات' : 'Latest Reports',
                    actionLabel: isAr ? 'تتبع بلاغ' : 'Track one',
                    onAction: () => Navigator.of(context).pushNamed('/track'),
                  ),
                  const SizedBox(height: 12),

                  if (_feedLoading)
                    _FeedSkeleton()
                  else if (_recentReports.isEmpty)
                    _EmptyFeed(isAr: isAr)
                  else
                    ..._recentReports.map((r) {
                      final status   = r['status'] as String? ?? 'pending';
                      final category = r['category'] as String? ?? 'cat_other';
                      final title    = r['title'] as String? ?? '';
                      final code     = r['report_code'] as String? ?? '';
                      final date     = DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now();
                      final statusColor = _statusColor(status);

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
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_categoryIcon(category), color: statusColor, size: 22),
                          ),
                          title: Text(title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(t(status, lang: lang),
                                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Text(code, style: TextStyle(fontSize: 10, color: Colors.grey.shade400, letterSpacing: 0.5)),
                            ]),
                            const SizedBox(height: 2),
                            Text('${date.day}/${date.month}/${date.year}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                          ]),
                        ),
                      );
                    }),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live Stats Bar ─────────────────────────────────────────────────────────

class _LiveStatsBar extends StatelessWidget {
  final int total, resolved, pending;
  final bool loading;
  final bool isAr;
  const _LiveStatsBar({required this.total, required this.resolved, required this.pending, required this.loading, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1F3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        _StatCell(value: total,    label: isAr ? 'إجمالي البلاغات' : 'Total Reports',  color: Colors.white,              loading: loading),
        _Divider(),
        _StatCell(value: resolved, label: isAr ? 'تم حلها'         : 'Resolved',        color: const Color(0xFF52B788),   loading: loading),
        _Divider(),
        _StatCell(value: pending,  label: isAr ? 'قيد الانتظار'    : 'Pending',         color: const Color(0xFFF59E0B),   loading: loading),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final bool loading;
  const _StatCell({required this.value, required this.label, required this.color, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          loading
              ? Container(width: 40, height: 22, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)))
              : Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: Colors.white10);
}

// ── Category Quick-Launch Grid ─────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final bool isAr;
  final String lang;
  const _CategoryGrid({required this.isAr, required this.lang});

  static const _cats = [
    {'key': 'cat_pothole',  'icon': Icons.warning_amber_rounded,  'color': Color(0xFFF59E0B)},
    {'key': 'cat_trash',    'icon': Icons.delete_outline,          'color': Color(0xFFEF4444)},
    {'key': 'cat_lighting', 'icon': Icons.lightbulb_outline,       'color': Color(0xFF6366F1)},
    {'key': 'cat_other',    'icon': Icons.more_horiz,              'color': Color(0xFF64748B)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(isAr ? 'بلّغ عن مشكلة' : 'Report a Problem',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0B1F3A))),
      const SizedBox(height: 10),
      Row(children: _cats.map((cat) {
        final icon  = cat['icon']  as IconData;
        final color = cat['color'] as Color;
        final key   = cat['key']   as String;
        return Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/report'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(t(key, lang: lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              ]),
            ),
          ),
        );
      }).toList()),
    ]);
  }
}

// ── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.label, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0B1F3A))),
      if (actionLabel != null)
        GestureDetector(
          onTap: onAction,
          child: Text(actionLabel!, style: const TextStyle(fontSize: 12, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600)),
        ),
    ]);
  }
}

// ── Feed Empty State ───────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final bool isAr;
  const _EmptyFeed({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(Icons.inbox_outlined, size: 28, color: Colors.grey.shade300),
        const SizedBox(width: 14),
        Text(isAr ? 'لا توجد بلاغات حتى الآن' : 'No reports yet — be the first!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]),
    );
  }
}

// ── Feed Skeleton ──────────────────────────────────────────────────────────

class _FeedSkeleton extends StatefulWidget {
  @override
  State<_FeedSkeleton> createState() => _FeedSkeletonState();
}

class _FeedSkeletonState extends State<_FeedSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _bone({double h = 12, double? w, double r = 6}) {
    return FadeTransition(
      opacity: _anim,
      child: Container(height: h, width: w, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(r))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(3, (_) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        FadeTransition(opacity: _anim, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _bone(h: 14, w: 180),
          const SizedBox(height: 8),
          _bone(h: 10, w: 110),
          const SizedBox(height: 4),
          _bone(h: 10, w: 70),
        ])),
      ]),
    )));
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _TopBarBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  const _TopBarBtn({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: icon != null
            ? Icon(icon, color: Colors.white, size: 18)
            : Text(label!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String email;
  final bool isAr;
  final VoidCallback onLogout;
  const _GreetingCard({required this.email, required this.isAr, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isAr ? 'مرحباً!' : 'Hello!', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
        ])),
        TextButton(
          onPressed: onLogout,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(isAr ? 'خروج' : 'Logout', style: const TextStyle(fontSize: 12)),
        ),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.iconBg, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: iconBg.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconBg, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0B1F3A))),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ])),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ]),
        ),
      ),
    );
  }
}

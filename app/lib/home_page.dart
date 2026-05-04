import 'theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'translations.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin, RouteAware {
  final _supabase = Supabase.instance.client;
  User? _user;

  int _totalReports    = 0;
  int _resolvedReports = 0;
  int _pendingReports  = 0;
  int _catPothole  = 0;
  int _catTrash    = 0;
  int _catLighting = 0;
  int _catSewage   = 0;
  int _catWater    = 0;
  int _catOther    = 0;
  bool _statsLoading = true;

  // Animated counter targets
  int _displayTotal    = 0;
  int _displayResolved = 0;
  int _displayPending  = 0;
  late AnimationController _counterCtrl;

  static const _red      = Color(0xFFCC0000);
  static const _redLight = Color(0xFF185FA5);
  static const _dark       = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _counterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() => _user = data.session?.user);
    });
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    // Called when returning to this page from another route
    _refresh();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _counterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final all  = await _supabase.from('reports').select('id, status, category');
      final list = (all as List).cast<Map<String, dynamic>>();
      if (!mounted) return;

      final total    = list.length;
      final resolved = list.where((r) => r['status'] == 'resolved').length;
      final pending  = list.where((r) => r['status'] == 'pending').length;

      setState(() {
        _totalReports    = total;
        _resolvedReports = resolved;
        _pendingReports  = pending;
        _catPothole      = list.where((r) => r['category'] == 'cat_pothole').length;
        _catTrash        = list.where((r) => r['category'] == 'cat_trash').length;
        _catLighting     = list.where((r) => r['category'] == 'cat_lighting').length;
        _catSewage       = list.where((r) => r['category'] == 'cat_sewage').length;
        _catWater        = list.where((r) => r['category'] == 'cat_water').length;
        _catOther        = list.where((r) => r['category'] == 'cat_other').length;
        _statsLoading    = false;
      });

      // Animate counters from 0 to actual values
      _counterCtrl.forward(from: 0);
      _counterCtrl.addListener(() {
        if (mounted) {
          setState(() {
            _displayTotal    = (_counterCtrl.value * total).round();
            _displayResolved = (_counterCtrl.value * resolved).round();
            _displayPending  = (_counterCtrl.value * pending).round();
          });
        }
      });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _statsLoading = true);
    await _loadStats();
  }

  void _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('snack_logout', lang: appLocale.value.languageCode)),
        backgroundColor: kRed,
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

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        color: kRed,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: kDark,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: kDark,
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        RichText(text: TextSpan(
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                          children: [const TextSpan(text: 'Fix'), TextSpan(text: 'City', style: TextStyle(color: kBlue))],
                        )),
                        const Spacer(),
                        _TopBarBtn(label: t('switch_lang', lang: lang), onTap: _toggleLang),
                        const SizedBox(width: 8),
                        _TopBarBtn(
                          icon: Icons.admin_panel_settings_outlined,
                          onTap: () => Navigator.of(context).pushNamed('/admin'),
                        ),
                        const SizedBox(width: 8),
                        _TopBarBtn(
                          icon: Icons.location_city_outlined,
                          onTap: () => Navigator.of(context).pushNamed('/governor'),
                        ),
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

                  // ── Live stats bar (animated) ───────────────────────
                  _LiveStatsBar(
                    total:    _statsLoading ? 0 : _displayTotal,
                    resolved: _statsLoading ? 0 : _displayResolved,
                    pending:  _statsLoading ? 0 : _displayPending,
                    loading:  _statsLoading,
                    isAr:     isAr,
                  ),
                  const SizedBox(height: 24),

                  // ── Quick actions label ────────────────────────────
                  _SectionHeader(label: isAr ? 'ماذا تريد أن تفعل؟' : 'What would you like to do?'),
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

                  // Login guard on My Reports
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
                      badge: _pendingReports > 0 ? _pendingReports : null,
                      onTap: () => Navigator.of(context).pushNamed('/my_reports'),
                    ),

                  const SizedBox(height: 28),

                  // ── Category breakdown ─────────────────────────────
                  _SectionHeader(label: isAr ? 'البلاغات حسب النوع' : 'Reports by Category'),
                  const SizedBox(height: 12),
                  _CategoryBreakdown(
                    pothole:  _catPothole,
                    trash:    _catTrash,
                    lighting: _catLighting,
                    sewage:   _catSewage,
                    water:    _catWater,
                    other:    _catOther,
                    total:    _totalReports,
                    loading:  _statsLoading,
                    isAr:     isAr,
                    lang:     lang,
                  ),

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
  final bool loading, isAr;
  const _LiveStatsBar({required this.total, required this.resolved, required this.pending, required this.loading, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        _StatCell(value: total,    label: isAr ? 'إجمالي البلاغات' : 'Total Reports', color: Colors.white,            loading: loading),
        _Div(),
        _StatCell(value: resolved, label: isAr ? 'تم حلها'         : 'Resolved',       color: const Color(0xFF185FA5), loading: loading),
        _Div(),
        _StatCell(value: pending,  label: isAr ? 'قيد الانتظار'    : 'Pending',        color: const Color(0xFFF59E0B), loading: loading),
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

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: Colors.white10);
}

// ── Category Quick-Launch Grid ─────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final bool isAr;
  final String lang;
  const _CategoryGrid({required this.isAr, required this.lang});

  static const _cats = [
    {'key': 'cat_pothole',  'icon': Icons.warning_amber_rounded, 'color': Color(0xFFF59E0B)},
    {'key': 'cat_trash',    'icon': Icons.delete_outline,         'color': Color(0xFFEF4444)},
    {'key': 'cat_lighting', 'icon': Icons.bolt_outlined,          'color': Color(0xFF6366F1)},
    {'key': 'cat_sewage',   'icon': Icons.water_damage_outlined,  'color': Color(0xFF8B5CF6)},
    {'key': 'cat_water',    'icon': Icons.water_drop_outlined,    'color': Color(0xFF0EA5E9)},
    {'key': 'cat_other',    'icon': Icons.more_horiz,             'color': Color(0xFF64748B)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(isAr ? 'بلّغ عن مشكلة' : 'Report a Problem',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
        children: _cats.map((cat) {
          final icon  = cat['icon']  as IconData;
          final color = cat['color'] as Color;
          final key   = cat['key']   as String;
          return GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/report', arguments: key),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(t(key, lang: lang),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    ]);
  }
}

// ── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)));
  }
}

// ── Category Breakdown ─────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final int pothole, trash, lighting, sewage, water, other, total;
  final bool loading, isAr;
  final String lang;
  const _CategoryBreakdown({
    required this.pothole, required this.trash, required this.lighting,
    required this.sewage, required this.water, required this.other,
    required this.total, required this.loading, required this.isAr, required this.lang,
  });

  static const _cats = [
    {'key': 'cat_pothole',  'icon': Icons.warning_amber_rounded, 'color': Color(0xFFF59E0B)},
    {'key': 'cat_trash',    'icon': Icons.delete_outline,         'color': Color(0xFFEF4444)},
    {'key': 'cat_lighting', 'icon': Icons.bolt_outlined,          'color': Color(0xFF6366F1)},
    {'key': 'cat_sewage',   'icon': Icons.water_damage_outlined,  'color': Color(0xFF8B5CF6)},
    {'key': 'cat_water',    'icon': Icons.water_drop_outlined,    'color': Color(0xFF0EA5E9)},
    {'key': 'cat_other',    'icon': Icons.more_horiz,             'color': Color(0xFF64748B)},
  ];

  @override
  Widget build(BuildContext context) {
    final counts = [pothole, trash, lighting, sewage, water, other];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(children: List.generate(_cats.length, (i) {
        final cat      = _cats[i];
        final icon     = cat['icon']  as IconData;
        final color    = cat['color'] as Color;
        final key      = cat['key']   as String;
        final count    = counts[i];
        final fraction = total > 0 ? count / total : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(t(key, lang: lang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                loading
                    ? Container(width: 24, height: 10, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)))
                    : Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: loading ? 0.0 : fraction),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  builder: (_, val, __) => LinearProgressIndicator(
                    value: val,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ])),
          ]),
        );
      })),
    );
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
        gradient: const LinearGradient(colors: [Color(0xFFCC0000), Color(0xFF185FA5)]),
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
  final int? badge;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.iconBg, required this.title, required this.subtitle, this.badge, required this.onTap});

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
            Stack(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: iconBg.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconBg, size: 26),
              ),
              if (badge != null)
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
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

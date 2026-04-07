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

  static const _green = Color(0xFF2D6A4F);
  static const _greenLight = Color(0xFF52B788);
  static const _navy = Color(0xFF0B1F3A);

  @override
  void initState() {
    super.initState();
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() => _user = data.session?.user);
    });
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

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: _navy,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(color: _navy),
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
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
                      _TopBarBtn(
                        icon: Icons.admin_panel_settings_outlined,
                        onTap: () => Navigator.of(context).pushNamed('/admin'),
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

          // ── Body ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // User greeting card
                if (_user != null) ...[
                  _GreetingCard(email: _user!.email ?? '', isAr: isAr, onLogout: _logout),
                  const SizedBox(height: 20),
                ],

                // Section label
                Text(isAr ? 'ماذا تريد أن تفعل؟' : 'What would you like to do?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5)),
                const SizedBox(height: 12),

                // Main action cards
                _ActionCard(
                  icon: Icons.report_problem_outlined,
                  iconBg: const Color(0xFF2D6A4F),
                  title: t('submit_report', lang: lang),
                  subtitle: t('report_subtitle', lang: lang),
                  badge: null,
                  onTap: () => Navigator.of(context).pushNamed('/report'),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.manage_search_outlined,
                  iconBg: const Color(0xFF1A56DB),
                  title: t('track_report', lang: lang),
                  subtitle: t('track_subtitle', lang: lang),
                  badge: null,
                  onTap: () => Navigator.of(context).pushNamed('/track'),
                ),
                const SizedBox(height: 12),
                if (_user == null)
                  _ActionCard(
                    icon: Icons.login_outlined,
                    iconBg: const Color(0xFF7C3AED),
                    title: t('login', lang: lang),
                    subtitle: t('login_subtitle', lang: lang),
                    badge: null,
                    onTap: () => Navigator.of(context).pushNamed('/login'),
                  )
                else
                  _ActionCard(
                    icon: Icons.folder_outlined,
                    iconBg: const Color(0xFFF59E0B),
                    title: t('my_reports', lang: lang),
                    subtitle: t('my_reports_subtitle', lang: lang),
                    badge: null,
                    onTap: () => Navigator.of(context).pushNamed('/my_reports'),
                  ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
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
  final String? badge;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.iconBg, required this.title, required this.subtitle, required this.badge, required this.onTap});

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
              Row(children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0B1F3A))),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.shade200)),
                    child: Text(badge!, style: TextStyle(fontSize: 10, color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
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



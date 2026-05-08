import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'main.dart';
import 'home_page.dart';
import 'my_reports_page.dart';
import 'notifications_page.dart';
import 'achievements_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with RouteAware {
  late int _currentIndex;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadUnread();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => setState(() {});

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadUnread() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);
      if (mounted) setState(() => _unreadCount = (res as List).length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        final lang = locale.languageCode;
        final isAr = lang == 'ar';

        final pages = [
          const HomePage(),
          const MyReportsPage(),
          const NotificationsPage(),
          const AchievementsPage(),
          const ProfilePage(),
          const SettingsPage(),
        ];

        return ValueListenableBuilder<bool>(
          valueListenable: isDarkMode,
          builder: (context, dark, _) {
            return Scaffold(
              extendBody: true,
              body: IndexedStack(key: ValueKey(lang), index: _currentIndex, children: pages),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, -2))],
                ),
                child: SafeArea(
                  child: SizedBox(
                    height: 62,
                    child: Row(
                      children: [
                        _NavItem(icon: Icons.home_outlined,          activeIcon: Icons.home,             label: isAr ? 'الرئيسية'  : 'Home',     index: 0, current: _currentIndex, dark: dark, onTap: (i) => setState(() => _currentIndex = i)),
                        _NavItem(icon: Icons.folder_outlined,        activeIcon: Icons.folder,           label: isAr ? 'بلاغاتي'   : 'Reports',  index: 1, current: _currentIndex, dark: dark, onTap: (i) => setState(() => _currentIndex = i)),
                        _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications,    label: isAr ? 'الإشعارات' : 'Alerts',   index: 2, current: _currentIndex, dark: dark, badge: _unreadCount, onTap: (i) { setState(() { _currentIndex = i; _unreadCount = 0; }); }),
                        _NavItem(icon: Icons.emoji_events_outlined,  activeIcon: Icons.emoji_events,     label: isAr ? 'الإنجازات' : 'Badges',   index: 3, current: _currentIndex, dark: dark, onTap: (i) => setState(() => _currentIndex = i)),
                        _NavItem(icon: Icons.person_outline,         activeIcon: Icons.person,           label: isAr ? 'حسابي'     : 'Profile',  index: 4, current: _currentIndex, dark: dark, onTap: (i) => setState(() => _currentIndex = i)),
                        _NavItem(icon: Icons.settings_outlined,      activeIcon: Icons.settings,         label: isAr ? 'الإعدادات' : 'Settings', index: 5, current: _currentIndex, dark: dark, onTap: (i) => setState(() => _currentIndex = i)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final int badge;
  final bool dark;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label,
      required this.index, required this.current, required this.onTap,
      this.badge = 0, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    final inactiveColor = dark ? Colors.white38 : Colors.grey.shade400;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? kRed : inactiveColor, size: 22),
            if (badge > 0)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  width: 13, height: 13,
                  decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                  child: Center(child: Text('$badge',
                      style: const TextStyle(color: kWhite, fontSize: 7, fontWeight: FontWeight.w800))),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 9,
              color: isActive ? kRed : inactiveColor,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
        ]),
      ),
    );
  }
}

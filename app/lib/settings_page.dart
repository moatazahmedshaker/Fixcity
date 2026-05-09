import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'main.dart';

// Global dark mode notifier
final ValueNotifier<bool> isDarkMode = ValueNotifier(false);

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';
    final user = Supabase.instance.client.auth.currentUser;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        final bgColor    = dark ? const Color(0xFF0D0D0D) : kBg;
        final cardColor  = dark ? const Color(0xFF1E1E1E) : kWhite;
        final textColor  = dark ? kWhite : kDark;
        final subColor   = dark ? Colors.grey.shade400 : kGrey;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: kBlue,
            title: Text(isAr ? 'الإعدادات' : 'Settings',
                style: const TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Language ──────────────────────────────────────────────
              _SectionHeader(label: isAr ? 'اللغة' : 'Language', dark: dark),
              const SizedBox(height: 10),
              _SettingsCard(color: cardColor, children: [
                _TapTile(
                  icon: Icons.language_outlined,
                  title: isAr ? 'العربية' : 'Arabic',
                  subtitle: isAr ? 'تبديل إلى العربية' : 'Switch to Arabic',
                  trailing: appLocale.value.languageCode == 'ar'
                      ? const Icon(Icons.check_circle, color: kRed, size: 20) : null,
                  textColor: textColor,
                  subColor: subColor,
                  onTap: () => appLocale.value = const Locale('ar'),
                ),
                _Divider(dark: dark),
                _TapTile(
                  icon: Icons.language_outlined,
                  title: 'English',
                  subtitle: 'Switch to English',
                  trailing: appLocale.value.languageCode == 'en'
                      ? const Icon(Icons.check_circle, color: kRed, size: 20) : null,
                  textColor: textColor,
                  subColor: subColor,
                  onTap: () => appLocale.value = const Locale('en'),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Account ───────────────────────────────────────────────
              if (user != null) ...[
                _SectionHeader(label: isAr ? 'الحساب' : 'Account', dark: dark),
                const SizedBox(height: 10),
                _SettingsCard(color: cardColor, children: [
                  _TapTile(
                    icon: Icons.logout_outlined,
                    title: isAr ? 'تسجيل الخروج' : 'Logout',
                    subtitle: isAr ? 'الخروج من حسابك' : 'Sign out of your account',
                    trailing: const Icon(Icons.chevron_right, color: kRed),
                    textColor: kRed,
                    subColor: subColor,
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                ]),
                const SizedBox(height: 20),
              ],

              // ── About ─────────────────────────────────────────────────
              _SectionHeader(label: isAr ? 'عن التطبيق' : 'About', dark: dark),
              const SizedBox(height: 10),
              _SettingsCard(color: cardColor, children: [
                _InfoTile(icon: Icons.info_outline, title: isAr ? 'الإصدار' : 'Version', value: '1.1.6', textColor: textColor, subColor: subColor),
                _Divider(dark: dark),
                _InfoTile(icon: Icons.school_outlined, title: isAr ? 'الجامعة' : 'University', value: 'Badr University in Cairo', textColor: textColor, subColor: subColor),
_Divider(dark: dark),
                _TapTile(
                  icon: Icons.code_outlined,
                  title: isAr ? 'المستودع' : 'Repository',
                  subtitle: 'github.com/moatazahmedshaker/Fixcity',
                  textColor: textColor,
                  subColor: subColor,
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 32),
              Center(child: Text('FixCity © 2025–2026',
                  style: TextStyle(fontSize: 12, color: subColor))),
              const SizedBox(height: 20),
            ]),
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool dark;
  const _SectionHeader({required this.label, required this.dark});
  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: dark ? Colors.grey.shade400 : kGrey));
}

class _SettingsCard extends StatelessWidget {
  final Color color;
  final List<Widget> children;
  const _SettingsCard({required this.color, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
    child: Column(children: children),
  );
}


class _TapTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget? trailing;
  final Color textColor, subColor;
  final VoidCallback onTap;
  const _TapTile({required this.icon, required this.title, required this.subtitle,
      this.trailing, required this.textColor, required this.subColor, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: kBlue, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: subColor)),
        ])),
        if (trailing != null) trailing!,
      ]),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color textColor, subColor;
  const _InfoTile({required this.icon, required this.title, required this.value,
      required this.textColor, required this.subColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, color: kBlue, size: 22),
      const SizedBox(width: 14),
      Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor))),
      Text(value, style: TextStyle(fontSize: 12, color: subColor)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  final bool dark;
  const _Divider({required this.dark});
  @override
  Widget build(BuildContext context) => Divider(
    height: 1, color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
    indent: 16, endIndent: 16,
  );
}

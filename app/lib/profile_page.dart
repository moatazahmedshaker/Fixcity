import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'main.dart';
import 'translations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _smsEnabled = true;

  @override
  void initState() {
    super.initState();
    // Only load if user is logged in
    if (_supabase.auth.currentUser != null) {
      _loadProfile();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) { setState(() => _loading = false); return; }
    try {
      final p = await _supabase.from('profiles').select().eq('id', user.id).single();
      final reports = await _supabase.from('reports').select('id').eq('user_id', user.id);
      if (mounted) setState(() {
        _profile = {
          ...p,
          'email': user.email,
          'report_count': (reports as List).length,
        };
        _smsEnabled = p['sms_enabled'] ?? true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _initials(String? name, String? email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return name[0].toUpperCase();
    }
    return email?.isNotEmpty == true ? email![0].toUpperCase() : '?';
  }

  Future<void> _editPhone(BuildContext context, bool isAr) async {
    final ctrl = TextEditingController(text: _profile?['phone'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'تعديل رقم الهاتف' : 'Edit Phone Number'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: InputDecoration(hintText: '01012345678'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('profiles').upsert({'id': user.id, 'phone': result});
      setState(() => _profile = {...?_profile, 'phone': result});
    }
  }

  Future<void> _editFullName(BuildContext context, bool isAr) async {
    final ctrl = TextEditingController(text: _profile?['full_name'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'تعديل الاسم' : 'Edit Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: isAr ? 'الاسم الكامل' : 'Full name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('profiles').upsert({'id': user.id, 'full_name': result});
      setState(() => _profile = {...?_profile, 'full_name': result});
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kDark,
        title: Text(isAr ? 'حسابي' : 'My Profile', style: const TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: kWhite, size: 20),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (mounted) Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kRed))
          : user == null
              ? _GuestView(isAr: isAr, icon: Icons.person_outline, titleAr: 'حسابي', titleEn: 'My Profile', subtitleAr: 'سجّل دخول للوصول إلى حسابك الشخصي', subtitleEn: 'Login to access your account')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    // Avatar
                    Container(
                      width: 90, height: 90,
                      decoration: const BoxDecoration(color: kBlue, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          _initials(_profile?['full_name'], user.email),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kWhite),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_profile?['full_name'] ?? user.email ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kDark)),
                    Text(user.email ?? '', style: TextStyle(fontSize: 13, color: kGrey)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(color: kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '⭐ ${_profile?['points'] ?? 0} ${isAr ? 'نقطة' : 'Points'}',
                        style: const TextStyle(fontSize: 13, color: kRed, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info card
                    _Card(children: [
                      _EditableRow(
                        icon: Icons.person_outline,
                        label: isAr ? 'الاسم' : 'Name',
                        value: _profile?['full_name'] ?? '-',
                        onTap: () => _editFullName(context, isAr),
                      ),
                      _EditableRow(
                        icon: Icons.phone_outlined,
                        label: isAr ? 'رقم الهاتف' : 'Phone',
                        value: _profile?['phone'] ?? (isAr ? 'اضغط للإضافة' : 'Tap to add'),
                        onTap: () => _editPhone(context, isAr),
                      ),
                      _InfoRow(icon: Icons.email_outlined,  label: isAr ? 'الإيميل' : 'Email', value: user.email ?? '-'),
                      _InfoRow(icon: Icons.report_outlined, label: isAr ? 'البلاغات'   : 'Reports', value: '${_profile?['report_count'] ?? 0}'),
                    ]),
                    const SizedBox(height: 16),

                    // Settings card
                    _Card(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          const Icon(Icons.sms_outlined, color: kBlue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(isAr ? 'إشعارات SMS' : 'SMS Notifications',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark))),
                          Switch(
                            value: _smsEnabled,
                            activeColor: kRed,
                            onChanged: (v) async {
                              setState(() => _smsEnabled = v);
                              try {
                                await _supabase.from('profiles').update({'sms_enabled': v}).eq('id', user.id);
                              } catch (_) {}
                            },
                          ),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _supabase.auth.signOut();
                          if (mounted) Navigator.of(context).pushReplacementNamed('/login');
                        },
                        icon: const Icon(Icons.logout_outlined, color: kRed, size: 18),
                        label: Text(isAr ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(color: kRed)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kRed),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ]),
                ),
    );
  }
}


class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
    child: Column(children: children),
  );
}

class _EditableRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  const _EditableRow({required this.icon, required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: kBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: kGrey)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
        ])),
        const Icon(Icons.edit_outlined, size: 16, color: kGrey),
      ]),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Icon(icon, color: kBlue, size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: kGrey)),
        Text(value,  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
      ]),
    ]),
  );
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
              decoration: BoxDecoration(color: kRed.withOpacity(0.08), shape: BoxShape.circle),
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

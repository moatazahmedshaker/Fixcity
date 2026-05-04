import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_page.dart';
import '../main.dart';
import '../theme.dart';

class GovernorLoginPage extends StatefulWidget {
  const GovernorLoginPage({super.key});
  @override
  State<GovernorLoginPage> createState() => _GovernorLoginPageState();
}

class _GovernorLoginPageState extends State<GovernorLoginPage> {
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool _loading   = false;
  bool _obscure   = true;

  Future<void> _login() async {
    // Sign out any existing citizen session first
    try { await Supabase.instance.client.auth.signOut(); } catch (_) {}
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';
    if (_email.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'الرجاء ملء جميع الحقول' : 'Please fill all fields'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(), password: _password.text.trim(),
      );
      if (res.user == null) throw Exception('Login failed');
      final profile = await Supabase.instance.client
          .from('profiles').select('is_governor').eq('id', res.user!.id).single();
      if (profile['is_governor'] != true) {
        await Supabase.instance.client.auth.signOut();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'هذا الحساب ليس حساب رئيس حي' : 'This account is not a governor account'),
          backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      if (mounted) Navigator.of(context).pushReplacementNamed('/governor/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${appLocale.value.languageCode == 'ar' ? 'فشل تسجيل الدخول' : 'Login failed'}: $e'),
        backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: kDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top),
            child: Column(children: [
              // Hero section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: kRed.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.location_city_outlined, color: kRed, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(isAr ? 'بوابة رئيس الحي' : 'Governor Portal',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kWhite)),
                  const SizedBox(height: 8),
                  Text(isAr ? 'تسجيل الدخول لإدارة بلاغات حيّك' : 'Login to manage your district reports',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                ]),
              ),

              // Form card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  FixField(
                    controller: _email,
                    label: isAr ? 'البريد الإلكتروني' : 'Email',
                    hint: isAr ? 'example@fixcity.gov' : 'example@fixcity.gov',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  FixField(
                    controller: _password,
                    label: isAr ? 'كلمة المرور' : 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18, color: kGrey),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const CircularProgressIndicator(color: kRed)
                      : FixGreenButton(
                          label: isAr ? 'دخول' : 'Login',
                          onPressed: _login,
                        ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/admin'),
                    child: Text(isAr ? 'تسجيل دخول الإدارة' : 'Admin Login',
                        style: const TextStyle(color: kGrey, fontSize: 13)),
                  ),
                ]),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}

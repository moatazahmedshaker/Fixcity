import 'theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'translations.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const _red   = Color(0xFFCC0000);
  static const _redLight = Color(0xFF185FA5);
  static const _dark = Color(0xFF1A1A2E);

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';
    final wide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: wide ? _wideLayout(isAr, lang) : _narrowLayout(isAr, lang),
      ),
    );
  }

  Widget _wideLayout(bool isAr, String lang) {
    return Row(children: [
      Expanded(child: FixHeroPanel(isAr: isAr)),
      Expanded(child: _formCard(isAr, lang)),
    ]);
  }

  Widget _narrowLayout(bool isAr, String lang) {
    return SingleChildScrollView(
      child: Column(children: [
        _formCard(isAr, lang),
      ]),
    );
  }

  Widget _formCard(bool isAr, String lang) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: Stack(children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [kRed, kBlue]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FixMobileLogo(isAr: isAr),
                  Text(isAr ? 'مرحباً بعودتك' : 'Welcome back',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kDark, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text(isAr ? 'سجّل الدخول للمتابعة' : 'Sign in to your FixCity account',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                  const SizedBox(height: 32),
                  FixField(controller: _emailController, label: t('email', lang: lang), hint: 'you@email.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  FixField(
                    controller: _passwordController,
                    label: t('password', lang: lang),
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: kRed))
                      : FixGreenButton(label: t('login', lang: lang), onPressed: _login),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(isAr ? 'ليس لديك حساب؟ ' : "Don't have an account? ",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/signup'),
                      child: Text(t('signup', lang: lang),
                          style: const TextStyle(color: kRed, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Shared Design Components ───────────────────────────────────────────────

class FixHeroPanel extends StatelessWidget {
  final bool isAr;
  const FixHeroPanel({super.key, required this.isAr});
  static const _red   = Color(0xFFCC0000);
  static const _redLight = Color(0xFF185FA5);
  static const _dark = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: kDark),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.location_pin, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            RichText(text: TextSpan(
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              children: [const TextSpan(text: 'Fix'), TextSpan(text: 'City', style: TextStyle(color: kBlue))],
            )),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.2),
                border: Border.all(color: kBlue.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: kBlue, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(isAr ? 'منصة الخدمات البلدية' : 'Municipal Services Platform',
                    style: const TextStyle(color: kBlue, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 20),
            RichText(text: TextSpan(
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -1),
              children: isAr
                  ? [const TextSpan(text: 'أبلغ.\nتابع.\n'), TextSpan(text: 'احلّ.', style: TextStyle(color: kBlue))]
                  : [const TextSpan(text: 'Report.\nTrack.\n'), TextSpan(text: 'Resolve.', style: TextStyle(color: kBlue))],
            )),
            const SizedBox(height: 20),
            Text(
              isAr ? 'ساعد في تحسين مدينتك من خلال الإبلاغ عن مشكلات البنية التحتية.' : 'Help improve your city by reporting infrastructure problems directly to the right authorities.',
              style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.7),
            ),
          ]),
          Row(children: [
            _Stat(num: '2.4k', label: isAr ? 'بلاغ محلول' : 'Resolved'),
            const SizedBox(width: 32),
            _Stat(num: '48h', label: isAr ? 'متوسط الاستجابة' : 'Avg. Response'),
            const SizedBox(width: 32),
            _Stat(num: '98%', label: isAr ? 'الرضا' : 'Satisfaction'),
          ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String num, label;
  const _Stat({required this.num, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(num, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38)),
    ]);
  }
}

class FixMobileLogo extends StatelessWidget {
  final bool isAr;
  const FixMobileLogo({super.key, required this.isAr});
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width > 700) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: const Color(0xFFCC0000), borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        RichText(text: const TextSpan(
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
          children: [TextSpan(text: 'Fix'), TextSpan(text: 'City', style: TextStyle(color: Color(0xFFCC0000)))],
        )),
      ]),
    );
  }
}

class FixField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final int maxLines;
  final VoidCallback? onTap;


  const FixField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.maxLines = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
      const SizedBox(height: 7),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: obscureText ? 1 : maxLines,
        onTap: onTap,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCC0000), width: 2)),
        ),
      ),
    ]);
  }
}

class FixGreenButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const FixGreenButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCC0000),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

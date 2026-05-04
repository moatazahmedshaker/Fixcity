import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'translations.dart';
import 'main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const _green = Color(0xFF2D6A4F);
  static const _greenLight = Color(0xFF52B788);

  Future<void> _signup() async {
    final isAr = appLocale.value.languageCode == 'ar';
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showError(t('fill_fields_error', lang: appLocale.value.languageCode));
      return;
    }
    // Validate phone number
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showError(isAr ? 'الرجاء إدخال رقم هاتف صحيح' : 'Please enter a valid phone number');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': _nameController.text.trim()},
      );
      // Store phone in profiles table
      if (res.user != null) {
        await _supabase.from('profiles').upsert({
          'id':    res.user!.id,
          'phone': phone,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'تم إنشاء الحساب! راجع بريدك الإلكتروني للتفعيل.'
              : 'Account created! Please check your email to verify.'),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.of(context).pushReplacementNamed('/login');
      }
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
    _nameController.dispose();
    _phoneController.dispose();
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
        child: wide
            ? Row(children: [
                Expanded(child: FixHeroPanel(isAr: isAr)),
                Expanded(child: _formCard(isAr, lang)),
              ])
            : SingleChildScrollView(child: _formCard(isAr, lang)),
      ),
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
              gradient: LinearGradient(colors: [_green, _greenLight]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FixMobileLogo(isAr: isAr),
                  Text(isAr ? 'إنشاء حساب جديد' : 'Create account',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0B1F3A), letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text(isAr ? 'انضم إلى فيكس سيتي وساهم في تحسين مدينتك' : 'Join FixCity and start making a difference.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                  const SizedBox(height: 24),

                  // Role selector
                  Row(children: [
                    Expanded(child: _RoleCard(icon: Icons.person_outline, title: isAr ? 'مواطن' : 'Citizen', subtitle: isAr ? 'تقديم بلاغات' : 'Report issues', selected: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _RoleCard(icon: Icons.admin_panel_settings_outlined, title: isAr ? 'مشرف' : 'City Admin', subtitle: isAr ? 'إدارة البلاغات' : 'Manage reports', selected: false)),
                  ]),
                  const SizedBox(height: 20),

                  FixField(controller: _nameController, label: t('full_name', lang: lang), hint: isAr ? 'الاسم الكامل' : 'Your full name', icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  FixField(
                    controller: _phoneController,
                    label: isAr ? 'رقم الهاتف *' : 'Phone Number *',
                    hint: isAr ? '01012345678' : '01012345678',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
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
                      ? const Center(child: CircularProgressIndicator(color: _green))
                      : FixGreenButton(label: isAr ? 'إنشاء حسابي' : 'Create My Account', onPressed: _signup),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(isAr ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/login'),
                      child: Text(t('login', lang: lang),
                          style: const TextStyle(color: _green, fontWeight: FontWeight.w600, fontSize: 13)),
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

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2D6A4F).withOpacity(0.05) : Colors.white,
        border: Border.all(color: selected ? const Color(0xFF2D6A4F) : Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Icon(icon, size: 24, color: selected ? const Color(0xFF2D6A4F) : Colors.grey),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF0B1F3A) : Colors.grey.shade600)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      ]),
    );
  }
}

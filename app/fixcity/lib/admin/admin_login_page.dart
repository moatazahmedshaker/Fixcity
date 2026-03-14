import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _obscure = true;
  String _errorMessage = '';

  static const _green = Color(0xFF2D6A4F);
  static const _navy = Color(0xFF0B1F3A);

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/admin/dashboard');
    } on AuthException catch (e) {
      _errorMessage = e.message.contains('Invalid login credentials')
          ? 'بيانات دخول غير صحيحة.'
          : 'فشل تسجيل الدخول. تأكد من البريد وكلمة المرور.';
    } catch (_) {
      _errorMessage = 'حدث خطأ غير متوقع.';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(children: [
              // Logo
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 16),
              const Text('FixCity Admin',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('لوحة تحكم المشرفين', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
              const SizedBox(height: 40),

              // Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Top accent
                  Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_green, Color(0xFF52B788)]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text('تسجيل الدخول',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _navy)),
                  const SizedBox(height: 4),
                  Text('للمشرفين المعتمدين فقط', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  const SizedBox(height: 24),

                  FixField(controller: _emailController, label: 'البريد الإلكتروني', hint: 'admin@fixcity.gov', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  FixField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage, style: TextStyle(fontSize: 12, color: Colors.red.shade600))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: _green))
                      : FixGreenButton(label: 'دخول لوحة التحكم', onPressed: _login),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('← العودة للتطبيق', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

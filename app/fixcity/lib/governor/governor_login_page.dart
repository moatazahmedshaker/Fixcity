import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GovernorLoginPage extends StatefulWidget {
  const GovernorLoginPage({super.key});
  @override
  State<GovernorLoginPage> createState() => _GovernorLoginPageState();
}

class _GovernorLoginPageState extends State<GovernorLoginPage> {
  final supabase = Supabase.instance.client;
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  static const _green = Color(0xFF2D6A4F);
  static const _navy  = Color(0xFF0B1F3A);

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (res.user == null) throw Exception('Login failed');

      final profile = await supabase
          .from('profiles')
          .select('is_governor, governor_district')
          .eq('id', res.user!.id)
          .single();

      if (profile['is_governor'] != true) {
        await supabase.auth.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('هذا الحساب ليس حساب رئيس حي'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/governor/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('فشل تسجيل الدخول: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: _green.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.location_city, color: _green, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('بوابة رئيس الحي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Text('تسجيل الدخول لإدارة بلاغات حيّك',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
            ]),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(28),
              child: Column(children: [
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email_outlined, color: _green),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outlined, color: _green),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 2)),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('دخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/admin'),
                  child: Text('تسجيل دخول الإدارة', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

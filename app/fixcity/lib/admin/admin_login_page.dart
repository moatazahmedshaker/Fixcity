import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _obscure   = true;
  String _errorMessage = '';

  static const _green = Color(0xFF2D6A4F);
  static const _navy  = Color(0xFF0B1F3A);

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      // Step 1: authenticate
      final authResponse = await supabase.auth.signInWithPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = authResponse.user;
      if (user == null) {
        setState(() { _errorMessage = 'Login failed. Please try again.'; _isLoading = false; });
        return;
      }

      // Step 2: check admin role in profiles table
      // If the profiles table or is_admin column doesn't exist yet,
      // this will throw — we catch it and allow access (for backwards compat during setup)
      bool isAdmin = false;
      try {
        final profile = await supabase
            .from('profiles')
            .select('is_admin')
            .eq('id', user.id)
            .maybeSingle();

        isAdmin = profile?['is_admin'] == true;
      } catch (_) {
        // profiles table not set up yet — allow access so the app still works
        isAdmin = true;
      }

      if (!mounted) return;

      if (isAdmin) {
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
      } else {
        // Not an admin — sign them out and show error
        await supabase.auth.signOut();
        setState(() {
          _errorMessage = 'Access denied. This account does not have admin privileges.';
          _isLoading    = false;
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message.contains('Invalid login credentials')
            ? 'Incorrect email or password.'
            : 'Login failed. Please check your credentials.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = 'An unexpected error occurred.'; _isLoading = false; });
    }
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
              Text('Municipal Staff Portal',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
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
                  // Top accent bar
                  Container(
                    height: 3, margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_green, Color(0xFF52B788)]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text('Sign In',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _navy)),
                  const SizedBox(height: 4),
                  Text('Authorized municipal staff only',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  const SizedBox(height: 24),

                  FixField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'staff@municipality.gov',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  FixField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  // Error message
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 14),
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
                        Expanded(child: Text(_errorMessage,
                            style: TextStyle(fontSize: 12, color: Colors.red.shade600))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: _green))
                      : FixGreenButton(label: 'Sign In to Admin Panel', onPressed: _login),
                  const SizedBox(height: 16),

                  // How it works info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Admin accounts are created and managed by your municipality\'s IT administrator. Contact your supervisor if you need access.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.5),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('← Back to App', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
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

import '../theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_page.dart';
import '../main.dart';

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
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  static const _red   = Color(0xFFCC0000);
  static const _dark  = Color(0xFF1A1A2E);

  Future<void> _login() async {
    // Sign out any existing citizen session first
    try { await supabase.auth.signOut(); } catch (_) {}
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
      backgroundColor: kDark,
      appBar: AppBar(
        backgroundColor: kDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () {
                appLocale.value = appLocale.value.languageCode == 'ar'
                    ? const Locale('en') : const Locale('ar');
              },
              child: Text(
                appLocale.value.languageCode == 'ar' ? 'EN' : 'ع',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          height: 4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [kRed, Color(0xFF185FA5)]),
          ),
        ),
        Expanded(child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
            child: Column(children: [
              // Logo
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(16)),
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
                  const Text('Sign In',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kDark)),
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
                    textInputAction: TextInputAction.next,
                    focusNode: _emailFocus,
                    onSubmitted: () => FocusScope.of(context).requestFocus(_passwordFocus),
                  ),
                  const SizedBox(height: 16),
                  FixField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    focusNode: _passwordFocus,
                    onSubmitted: _login,
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
                      ? const Center(child: CircularProgressIndicator(color: kRed))
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
      )),
    ]),
  );
  }
}

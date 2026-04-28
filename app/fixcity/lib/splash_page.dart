import 'package:flutter/material.dart';
import 'main.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;

  // Step 0 = language picker, Step 1+ = onboarding pages
  int _step = 0;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  static const _green      = Color(0xFF2D6A4F);
  static const _greenLight = Color(0xFF52B788);
  static const _navy       = Color(0xFF0B1F3A);

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.location_pin,
      titleAr: 'أبلغ بسهولة',       titleEn: 'Report Easily',
      subtitleAr: 'التقط صورة، حدد الموقع، وأرسل بلاغك في ثوانٍ',
      subtitleEn: 'Take a photo, pin the location, and submit in seconds',
      color: _green,
    ),
    _OnboardingData(
      icon: Icons.manage_search_outlined,
      titleAr: 'تابع بلاغاتك',      titleEn: 'Track Your Reports',
      subtitleAr: 'استخدم الكود الخاص بك لمتابعة حالة بلاغك لحظة بلحظة',
      subtitleEn: 'Use your unique code to follow your report status in real time',
      color: const Color(0xFF1A56DB),
    ),
    _OnboardingData(
      icon: Icons.check_circle_outline,
      titleAr: 'مدينتك أفضل',       titleEn: 'Better City',
      subtitleAr: 'مساهمتك تُحدث فرقًا حقيقيًا في حياة جميع المواطنين',
      subtitleEn: 'Your contribution makes a real difference for everyone in the city',
      color: _greenLight,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _logoController    = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _contentController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _logoScale    = CurvedAnimation(parent: _logoController,    curve: Curves.elasticOut).drive(Tween(begin: 0.0, end: 1.0));
    _logoOpacity  = CurvedAnimation(parent: _logoController,    curve: Curves.easeIn).drive(Tween(begin: 0.0, end: 1.0));
    _contentOpacity = CurvedAnimation(parent: _contentController, curve: Curves.easeIn).drive(Tween(begin: 0.0, end: 1.0));
    _contentSlide   = CurvedAnimation(parent: _contentController, curve: Curves.easeOut).drive(Tween(begin: const Offset(0, 0.3), end: Offset.zero));

    _logoController.forward().then((_) => _contentController.forward());
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _selectLanguage(String lang) {
    appLocale.value = Locale(lang);
    setState(() => _step = 1);
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _skip() => Navigator.of(context).pushReplacementNamed('/');

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: _step == 0
            ? _buildLanguagePicker()
            : _buildOnboarding(isAr),
      ),
    );
  }

  // ── Language Picker ────────────────────────────────────────────────────────

  Widget _buildLanguagePicker() {
    return FadeTransition(
      opacity: _contentOpacity,
      child: SlideTransition(
        position: _contentSlide,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.location_pin, color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 16),
                    RichText(text: TextSpan(
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
                      children: [
                        const TextSpan(text: 'Fix'),
                        TextSpan(text: 'City', style: TextStyle(color: _greenLight)),
                      ],
                    )),
                  ]),
                ),
              ),
              const SizedBox(height: 60),

              // Language prompt — shown in both languages
              const Text('Choose your language', style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const Text('اختر لغتك', style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 32),

              // English button
              _LangButton(
                flag: '🇬🇧',
                label: 'English',
                sublabel: 'Continue in English',
                onTap: () => _selectLanguage('en'),
              ),
              const SizedBox(height: 14),

              // Arabic button
              _LangButton(
                flag: '🇪🇬',
                label: 'العربية',
                sublabel: 'تابع باللغة العربية',
                onTap: () => _selectLanguage('ar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────

  Widget _buildOnboarding(bool isAr) {
    return Column(children: [
      // Top bar
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.location_pin, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            RichText(text: TextSpan(
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              children: [
                const TextSpan(text: 'Fix'),
                TextSpan(text: 'City', style: TextStyle(color: _greenLight)),
              ],
            )),
          ]),
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skip,
              child: Text(isAr ? 'تخطي' : 'Skip',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ),
        ]),
      ),

      // Pages
      Expanded(
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemCount: _pages.length,
          itemBuilder: (context, i) => _OnboardingPage(data: _pages[i], isAr: isAr),
        ),
      ),

      // Bottom controls
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(children: [
          // Dots
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pages.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8, height: 8,
              decoration: BoxDecoration(
                color: active ? _greenLight : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          })),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                _currentPage == _pages.length - 1
                    ? (isAr ? 'ابدأ الآن' : 'Get Started')
                    : (isAr ? 'التالي' : 'Next'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ── Language Button ────────────────────────────────────────────────────────

class _LangButton extends StatelessWidget {
  final String flag, label, sublabel;
  final VoidCallback onTap;
  const _LangButton({required this.flag, required this.label, required this.sublabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(sublabel, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
          ]),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16),
        ]),
      ),
    );
  }
}

// ── Onboarding Page ────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final bool isAr;
  const _OnboardingPage({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 140, height: 140,
          decoration: BoxDecoration(
            color: data.color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: data.color.withOpacity(0.3), width: 2),
          ),
          child: Icon(data.icon, size: 64, color: data.color),
        ),
        const SizedBox(height: 48),
        Text(isAr ? data.titleAr : data.titleEn,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        Text(isAr ? data.subtitleAr : data.subtitleEn,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6), height: 1.6)),
      ]),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String titleAr, titleEn, subtitleAr, subtitleEn;
  final Color color;
  const _OnboardingData({
    required this.icon, required this.titleAr, required this.titleEn,
    required this.subtitleAr, required this.subtitleEn, required this.color,
  });
}

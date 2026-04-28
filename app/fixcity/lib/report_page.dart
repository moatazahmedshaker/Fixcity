import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:random_string/random_string.dart';
import 'login_page.dart';
import 'translations.dart';
import 'main.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapController = MapController();

  static const _green  = Color(0xFF2D6A4F);
  static const _greenLight = Color(0xFF52B788);
  static const _navy   = Color(0xFF0B1F3A);

  // Anthropic API key — replace with your key or load from env
  static const _geminiKey = 'AIzaSyBbEvjMFSuIzk3uuy7ZO0kWBFjZIOtKT34';

  final List<String> _categories = ['cat_pothole', 'cat_trash', 'cat_lighting', 'cat_sewage', 'cat_water', 'cat_other'];
  String? _selectedCategory;
  Uint8List? _selectedImageData;
  XFile?    _selectedImageFile;
  LatLng _selectedLocation = const LatLng(30.0444, 31.2357);
  bool _isLoading       = false;
  bool _locationLoading = false;
  bool _aiLoading       = false;
  String? _aiSuggestion; // stores the suggested category key

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // ── AI Classification ────────────────────────────────────────────────────

  // Keyword-based fallback — works offline, no API needed
  String _keywordClassify(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'road|pothole|crack|pavement|asphalt|street damage|طريق|حفرة|رصيف|شقوق|تلف الطريق|مشاكل الطرق').hasMatch(t)) return 'cat_pothole';
    if (RegExp(r'trash|garbage|waste|litter|dump|smell|dirty|قمامة|نفايات|زبالة|قذارة|روائح|نظافة|مشاكل النظافة').hasMatch(t)) return 'cat_trash';
    if (RegExp(r'light|lamp|dark|electricity|power|bulb|إنارة|كهرباء|مصباح|ظلام|نور|تيار|مشاكل الكهرباء').hasMatch(t)) return 'cat_lighting';
    if (RegExp(r'sewage|sewer|drain|overflow|smell|صرف|مجاري|بالوعة|فيضان|مشاكل الصرف').hasMatch(t)) return 'cat_sewage';
    if (RegExp(r'water|pipe|leak|flood|مياه|ماء|تسريب|أنبوب|فيضان|مشاكل المياه').hasMatch(t)) return 'cat_water';
    return 'cat_other';
  }

  Future<void> _classifyWithAI() async {
    final lang        = appLocale.value.languageCode;
    final isAr        = lang == 'ar';
    final description = _descriptionController.text.trim();
    final title       = _titleController.text.trim();
    final combined    = '$title $description';

    if (description.isEmpty && title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'اكتب وصف المشكلة أولاً' : 'Write a description first'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    setState(() => _aiLoading = true);

    String matched = 'cat_other';
    bool usedAI    = false;

    // Try Gemini first
    try {
      final prompt = '''
You are a municipal issue classifier. Based on the following report, classify it into ONE of these categories:
- cat_pothole: road damage, potholes, cracks, broken pavement
- cat_trash: garbage, waste, littering, dump, smell, cleanliness
- cat_lighting: street lights, lamp, electricity, dark roads
- cat_other: anything else

Report title: "$title"
Report description: "$description"

Respond with ONLY the category key, nothing else. Example: cat_pothole
''';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'maxOutputTokens': 20, 'temperature': 0.1},
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body);
        final rawText = (data['candidates'][0]['content']['parts'][0]['text'] as String).trim().toLowerCase();
        for (final cat in _categories) {
          if (rawText.contains(cat)) { matched = cat; break; }
        }
        usedAI = true;
      } else {
        // API failed — use keyword fallback silently
        matched = _keywordClassify(combined);
      }
    } catch (_) {
      // CORS, network error, timeout — use keyword fallback silently
      matched = _keywordClassify(combined);
    }

    if (mounted) {
      setState(() {
        _aiSuggestion     = matched;
        _selectedCategory = matched;
        _aiLoading        = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(isAr
                ? 'اقتراح الذكاء الاصطناعي: ${t(matched, lang: lang)}'
                : 'AI suggested: ${t(matched, lang: lang)}'),
          ),
        ]),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ── Image & Location ─────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker     = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _selectedImageFile = pickedFile;
      _selectedImageData = await pickedFile.readAsBytes();
      setState(() {});
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_selectedLocation, 15.0);
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submitReport() async {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'الرجاء اختيار فئة' : 'Please select a category'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    if (_selectedImageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('fill_fields_error', lang: lang)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: _green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.send_outlined, color: _green, size: 28),
            ),
            const SizedBox(height: 16),
            Text(isAr ? 'تأكيد إرسال البلاغ' : 'Confirm Submission',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _navy)),
            const SizedBox(height: 8),
            Text(
              isAr ? 'هل أنت متأكد من إرسال هذا البلاغ؟' : 'Are you sure you want to submit this report?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ConfirmRow(label: isAr ? 'العنوان' : 'Title',    value: _titleController.text),
                _ConfirmRow(label: isAr ? 'الفئة'   : 'Category', value: t(_selectedCategory!, lang: lang)),
              ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  child: Text(isAr ? 'إرسال' : 'Submit'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);

    try {
      String reportCode = randomAlphaNumeric(10).toUpperCase();
      String fileName   = 'reports/$reportCode/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('files').uploadBinary(fileName, _selectedImageData!,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      String photoUrl = supabase.storage.from('files').getPublicUrl(fileName);
      await supabase.from('reports').insert({
        'report_code': reportCode,
        'title':       _titleController.text,
        'category':    _selectedCategory!,
        'description': _descriptionController.text,
        'photo_url':   photoUrl,
        'latitude':    _selectedLocation.latitude,
        'longitude':   _selectedLocation.longitude,
        'status':      'pending',
        'created_at':  DateTime.now().toIso8601String(),
        'user_id':     supabase.auth.currentUser?.id,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSuccessDialog(reportCode, lang);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${t('error_message', lang: lang)} $e'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String code, String lang) {
    final isAr = lang == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline, color: _green, size: 36),
            ),
            const SizedBox(height: 16),
            Text(isAr ? 'تم الإرسال بنجاح!' : 'Report Submitted!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _navy)),
            const SizedBox(height: 8),
            Text(isAr ? 'كود البلاغ الخاص بك:' : 'Your report code:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _greenLight),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _green, letterSpacing: 2)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(isAr ? 'تم النسخ' : 'Copied!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                  child: const Icon(Icons.copy_outlined, size: 18, color: _green),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Text(isAr ? 'احفظ هذا الكود لمتابعة بلاغك' : 'Save this code to track your report',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FixGreenButton(label: isAr ? 'حسناً' : 'Done', onPressed: () => Navigator.of(ctx).pop()),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(t('report_page_title', lang: lang),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const _ReportSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── Title ──────────────────────────────────────────
                  _SectionLabel(label: t('problem_title', lang: lang)),
                  const SizedBox(height: 8),
                  FixField(
                    controller: _titleController,
                    label: '',
                    hint: isAr ? 'مثال: حفرة في الطريق الرئيسي' : 'e.g. Large pothole on main road',
                    icon: Icons.title_outlined,
                  ),
                  const SizedBox(height: 20),

                  // ── Description ────────────────────────────────────
                  _SectionLabel(label: t('problem_desc', lang: lang)),
                  const SizedBox(height: 8),
                  FixField(
                    controller: _descriptionController,
                    label: '',
                    hint: isAr ? 'صف المشكلة بالتفصيل...' : 'Describe the problem in detail...',
                    icon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),

                  // ── AI Classify Button ─────────────────────────────
                  _AIClassifyButton(
                    isLoading: _aiLoading,
                    isAr: isAr,
                    onTap: _classifyWithAI,
                  ),
                  const SizedBox(height: 20),

                  // ── Category Grid ──────────────────────────────────
                  _SectionLabel(label: t('select_category', lang: lang)),
                  const SizedBox(height: 8),
                  _CategoryGrid(
                    categories: _categories,
                    selected: _selectedCategory,
                    aiSuggestion: _aiSuggestion,
                    lang: lang,
                    onSelect: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 20),

                  // ── Location ───────────────────────────────────────
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _SectionLabel(label: t('location_title', lang: lang)),
                    TextButton.icon(
                      onPressed: _locationLoading ? null : _getCurrentLocation,
                      icon: _locationLoading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _green))
                          : const Icon(Icons.my_location, size: 16, color: _green),
                      label: Text(isAr ? 'موقعي الحالي' : 'My location',
                          style: const TextStyle(fontSize: 12, color: _green)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 260,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedLocation,
                          initialZoom: 13.0,
                          onTap: (_, point) => setState(() => _selectedLocation = point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.fixcity.app',
                          ),
                          MarkerLayer(markers: [
                            Marker(
                              width: 50, height: 50,
                              point: _selectedLocation,
                              child: Container(
                                decoration: BoxDecoration(color: _green.withOpacity(0.15), shape: BoxShape.circle),
                                child: const Icon(Icons.location_pin, color: _green, size: 32),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      isAr ? 'اضغط على الخريطة لتحديد الموقع بدقة' : 'Tap on the map to pinpoint the exact location',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Photo ──────────────────────────────────────────
                  _SectionLabel(label: isAr ? 'إرفاق صورة' : 'Attach Photo'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: _selectedImageData != null ? null : 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedImageData != null ? _green : Colors.grey.shade300,
                          width: _selectedImageData != null ? 2 : 1.5,
                        ),
                      ),
                      child: _selectedImageData != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Stack(children: [
                                Image.memory(_selectedImageData!, width: double.infinity, fit: BoxFit.cover),
                                Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                                  ),
                                ),
                              ]),
                            )
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text(isAr ? 'انقر لاختيار صورة' : 'Tap to choose a photo',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Submit ─────────────────────────────────────────
                  FixGreenButton(label: t('submit_btn', lang: lang), onPressed: _submitReport),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
    );
  }
}

// ── AI Classify Button ─────────────────────────────────────────────────────

class _AIClassifyButton extends StatelessWidget {
  final bool isLoading;
  final bool isAr;
  final VoidCallback onTap;
  const _AIClassifyButton({required this.isLoading, required this.isAr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF0B1F3A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isLoading)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          else
            const Icon(Icons.auto_awesome, color: Color(0xFF52B788), size: 18),
          const SizedBox(width: 10),
          Text(
            isLoading
                ? (isAr ? 'جارٍ التصنيف بالذكاء الاصطناعي...' : 'AI is classifying...')
                : (isAr ? 'اقتراح الفئة بالذكاء الاصطناعي ✨' : 'Suggest Category with AI ✨'),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}

// ── Category Grid ──────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final String? aiSuggestion;
  final String lang;
  final ValueChanged<String> onSelect;
  const _CategoryGrid({required this.categories, required this.selected, required this.aiSuggestion, required this.lang, required this.onSelect});

  static const _meta = {
    'cat_pothole':  {'icon': Icons.warning_amber_rounded,  'color': Color(0xFFF59E0B)},
    'cat_trash':    {'icon': Icons.delete_outline,          'color': Color(0xFFEF4444)},
    'cat_lighting': {'icon': Icons.bolt_outlined,           'color': Color(0xFF6366F1)},
    'cat_sewage':   {'icon': Icons.water_damage_outlined,   'color': Color(0xFF8B5CF6)},
    'cat_water':    {'icon': Icons.water_drop_outlined,     'color': Color(0xFF0EA5E9)},
    'cat_other':    {'icon': Icons.more_horiz,              'color': Color(0xFF64748B)},
  };

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: categories.map((cat) {
        final isSelected   = selected == cat;
        final isAISuggested = aiSuggestion == cat;
        final icon  = _meta[cat]?['icon']  as IconData? ?? Icons.help_outline;
        final color = _meta[cat]?['color'] as Color?    ?? Colors.grey;

        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : (isAISuggested ? const Color(0xFF52B788) : Colors.grey.shade200),
                width: isSelected ? 2 : (isAISuggested ? 1.5 : 1.5),
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Stack(children: [
              // AI badge
              if (isAISuggested && !isSelected)
                Positioned(
                  top: 4, right: 4,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(color: Color(0xFF52B788), shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 8),
                  ),
                ),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: isSelected ? color : Colors.grey.shade400, size: 26),
                const SizedBox(height: 6),
                Text(t(cat, lang: lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : Colors.grey.shade500)),
              ]),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────

class _ReportSkeleton extends StatefulWidget {
  const _ReportSkeleton();
  @override
  State<_ReportSkeleton> createState() => _ReportSkeletonState();
}

class _ReportSkeletonState extends State<_ReportSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _bone({double h = 16, double? w, double r = 8}) {
    return FadeTransition(
      opacity: _anim,
      child: Container(height: h, width: w, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(r))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _bone(h: 14, w: 100),
        const SizedBox(height: 8),
        _bone(h: 50, r: 10),
        const SizedBox(height: 20),
        _bone(h: 14, w: 120),
        const SizedBox(height: 8),
        _bone(h: 100, r: 10),
        const SizedBox(height: 12),
        _bone(h: 48, r: 12),
        const SizedBox(height: 20),
        _bone(h: 14, w: 120),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _bone(h: 80, r: 12)),
          const SizedBox(width: 10),
          Expanded(child: _bone(h: 80, r: 12)),
          const SizedBox(width: 10),
          Expanded(child: _bone(h: 80, r: 12)),
          const SizedBox(width: 10),
          Expanded(child: _bone(h: 80, r: 12)),
        ]),
        const SizedBox(height: 20),
        _bone(h: 260, r: 16),
        const SizedBox(height: 20),
        _bone(h: 120, r: 12),
        const SizedBox(height: 32),
        Center(child: Column(children: [
          const CircularProgressIndicator(color: Color(0xFF2D6A4F)),
          const SizedBox(height: 12),
          Text(
            appLocale.value.languageCode == 'ar' ? 'جارٍ إرسال البلاغ...' : 'Submitting report...',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ])),
      ]),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) =>
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0B1F3A)));
}

class _ConfirmRow extends StatelessWidget {
  final String label, value;
  const _ConfirmRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF0B1F3A)), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

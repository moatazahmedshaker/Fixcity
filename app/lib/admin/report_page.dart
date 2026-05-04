import 'theme.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';

// ── District model ─────────────────────────────────────────────────────────

class District {
  final String nameAr;
  final String nameEn;
  final String governorName;
  final String governorPhone;
  const District({required this.nameAr, required this.nameEn, required this.governorName, required this.governorPhone});
}

const List<District> kDistricts = [
  District(nameAr: 'حي النزهة',       nameEn: 'Al Nuzha',       governorName: 'م. أحمد السيد',    governorPhone: '0100-000-0001'),
  District(nameAr: 'حي المعادي',      nameEn: 'Maadi',          governorName: 'م. خالد محمود',   governorPhone: '0100-000-0002'),
  District(nameAr: 'حي مصر الجديدة', nameEn: 'Heliopolis',     governorName: 'م. طارق علي',     governorPhone: '0100-000-0003'),
  District(nameAr: 'حي الزيتون',      nameEn: 'Al Zeitoun',     governorName: 'م. محمد حسن',     governorPhone: '0100-000-0004'),
  District(nameAr: 'حي عين شمس',      nameEn: 'Ain Shams',      governorName: 'م. عمرو إبراهيم', governorPhone: '0100-000-0005'),
  District(nameAr: 'حي التجمع الأول', nameEn: 'First Settlement',governorName: 'م. سامي رضا',    governorPhone: '0100-000-0006'),
  District(nameAr: 'حي بدر',          nameEn: 'Badr',            governorName: 'م. يوسف فاروق',  governorPhone: '0100-000-0007'),
  District(nameAr: 'حي الشروق',       nameEn: 'Al Shorouk',     governorName: 'م. هاني كمال',    governorPhone: '0100-000-0008'),
];

// ── Page ───────────────────────────────────────────────────────────────────

class ReportPage extends StatefulWidget {
  final String? initialCategory;
  const ReportPage({super.key, this.initialCategory});
  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _mapController = MapController();

  static const _red      = Color(0xFFCC0000);
  static const _redLight = Color(0xFF185FA5);
  static const _dark       = Color(0xFF1A1A2E);
  static const _geminiKey  = 'AIzaSyBbEvjMFSuIzk3uuy7ZO0kWBFjZIOtKT34';

  final List<String> _categories = ['cat_pothole', 'cat_trash', 'cat_lighting', 'cat_sewage', 'cat_water', 'cat_other'];
  String?   _selectedCategory;
  District? _selectedDistrict;
  Uint8List? _selectedImageData;
  XFile?     _selectedImageFile;
  LatLng _selectedLocation = const LatLng(30.0444, 31.2357);
  bool _isLoading       = false;
  bool _locationLoading = false;
  bool _aiLoading       = false;
  String? _aiSuggestion;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Pre-select category if passed from home grid
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also check route arguments (when pushed via pushNamed with arguments)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _selectedCategory == null) {
      setState(() => _selectedCategory = args);
    }
  }

  // ── AI Classification ─────────────────────────────────────────────────────

  String _keywordClassify(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'road|pothole|crack|pavement|asphalt|street damage|طريق|حفرة|رصيف|شقوق|تلف الطريق|مشاكل الطرق').hasMatch(t)) return 'cat_pothole';
    if (RegExp(r'trash|garbage|waste|litter|dump|smell|dirty|قمامة|نفايات|زبالة|قذارة|روائح|نظافة|مشاكل النظافة').hasMatch(t)) return 'cat_trash';
    if (RegExp(r'light|lamp|dark|electricity|power|bulb|إنارة|كهرباء|مصباح|ظلام|نور|تيار|مشاكل الكهرباء').hasMatch(t)) return 'cat_lighting';
    if (RegExp(r'sewage|sewer|drain|overflow|مجاري|بالوعة|فيضان|مشاكل الصرف').hasMatch(t)) return 'cat_sewage';
    if (RegExp(r'water|pipe|leak|flood|مياه|ماء|تسريب|أنبوب|مشاكل المياه').hasMatch(t)) return 'cat_water';
    return 'cat_other';
  }

  Future<void> _classifyWithAI() async {
    final lang        = appLocale.value.languageCode;
    final isAr        = lang == 'ar';
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
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

    try {
      final prompt = '''
You are a municipal issue classifier. Classify this report into ONE category:
- cat_pothole: road damage, potholes, cracks, broken pavement
- cat_trash: garbage, waste, littering, dump, cleanliness
- cat_lighting: street lights, lamp, electricity, dark roads
- cat_sewage: sewage, drain, overflow
- cat_water: water pipe, leak, flood
- cat_other: anything else

Report: "$description"

Respond with ONLY the category key. Example: cat_pothole
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
      } else {
        matched = _keywordClassify(description);
      }
    } catch (_) {
      matched = _keywordClassify(description);
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
          Expanded(child: Text(isAr
              ? 'اقتراح الذكاء الاصطناعي: ${t(matched, lang: lang)}'
              : 'AI suggested: ${t(matched, lang: lang)}')),
        ]),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ── Image & Location ──────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';
    // Show camera vs gallery choice
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(isAr ? 'اختر مصدر الصورة' : 'Choose photo source',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context, ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCC0000).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    const Icon(Icons.camera_alt_outlined, color: Color(0xFFCC0000), size: 32),
                    const SizedBox(height: 8),
                    Text(isAr ? 'الكاميرا' : 'Camera',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFCC0000))),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context, ImageSource.gallery),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    Icon(Icons.photo_library_outlined, color: Colors.grey.shade600, size: 32),
                    const SizedBox(height: 8),
                    Text(isAr ? 'المعرض' : 'Gallery',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  ]),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
    if (source == null) return;
    final picker     = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
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
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_selectedLocation, 15.0);
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  // ── SMS confirmation ──────────────────────────────────────────────────────

  Future<void> _sendSMSConfirmation(String phone, String reportCode, String lang) async {
    final isAr = lang == 'ar';
    final message = isAr
        ? 'FixCity: تم تقديم بلاغك بنجاح!\n'
          'كود البلاغ: $reportCode\n'
          'الفئة: ${t(_selectedCategory!, lang: lang)}\n'
          'الحي: ${_selectedDistrict!.nameAr}\n'
          'الحالة: قيد الانتظار\n'
          'احتفظ بهذا الكود لمتابعة بلاغك.'
        : 'FixCity: Your report was submitted!\n'
          'Report Code: $reportCode\n'
          'Category: ${t(_selectedCategory!, lang: lang)}\n'
          'District: ${_selectedDistrict!.nameEn}\n'
          'Status: Pending\n'
          'Keep this code to track your report.';

    try {
      final cleaned   = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final formatted = cleaned.startsWith('0') ? '+2$cleaned' : '+$cleaned';
      final encoded   = Uri.encodeComponent(message);
      // sms: URI scheme opens the native SMS app pre-filled
      final url = Uri.parse('sms:$formatted?body=$encoded');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('SMS failed: \$e');
    }
  }

  // ── WhatsApp confirmation ────────────────────────────────────────────────

  Future<void> _sendWhatsAppConfirmation(String phone, String reportCode, String lang) async {
    final isAr = lang == 'ar';
    final message = isAr
        ? '✅ *تم تقديم بلاغك بنجاح على FixCity*\n\n'
          '🔖 كود البلاغ: *$reportCode*\n'
          '📂 الفئة: ${t(_selectedCategory!, lang: lang)}\n'
          '🏙️ الحي: ${_selectedDistrict!.nameAr}\n'
          '📊 الحالة: قيد الانتظار ⏳\n\n'
          'احتفظ بهذا الكود لمتابعة بلاغك في التطبيق.'
        : '✅ *Your FixCity report was submitted successfully*\n\n'
          '🔖 Report Code: *$reportCode*\n'
          '📂 Category: ${t(_selectedCategory!, lang: lang)}\n'
          '🏙️ District: ${_selectedDistrict!.nameEn}\n'
          '📊 Status: Pending ⏳\n\n'
          'Keep this code to track your report in the app.';

    final encoded = Uri.encodeComponent(message);
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final waNumber = cleaned.startsWith('0') ? '2$cleaned' : cleaned;
    final url = Uri.parse('https://wa.me/$waNumber?text=' + encoded);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ── Phone bottom sheet ────────────────────────────────────────────────────

  Future<String?> _askForPhone(String lang) async {
    final isAr = lang == 'ar';
    final ctrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 30),
            ),
            const SizedBox(height: 16),
            Text(isAr ? 'رقم واتساب للتأكيد' : 'WhatsApp Confirmation',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'أدخل رقم هاتفك لاستلام تأكيد البلاغ عبر واتساب'
                  : 'Enter your phone number to receive a WhatsApp confirmation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '01012345678',
                prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFCC0000)),
                filled: true, fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCC0000), width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(isAr ? 'تخطي' : 'Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final phone = ctrl.text.trim();
                    if (phone.length < 10) return;
                    Navigator.of(ctx).pop(phone);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  child: Text(isAr ? 'إرسال تأكيد' : 'Send Confirmation'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

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
    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'الرجاء اختيار الحي' : 'Please select a district'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    if (_selectedImageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'الرجاء إرفاق صورة' : 'Please attach a photo'),
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
              decoration: BoxDecoration(color: kRed.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.send_outlined, color: kRed, size: 28),
            ),
            const SizedBox(height: 16),
            Text(isAr ? 'تأكيد إرسال البلاغ' : 'Confirm Submission',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kDark)),
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
                _ConfirmRow(label: isAr ? 'الفئة'   : 'Category', value: t(_selectedCategory!, lang: lang)),
                _ConfirmRow(label: isAr ? 'الحي'    : 'District',  value: isAr ? _selectedDistrict!.nameAr : _selectedDistrict!.nameEn),
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
                    backgroundColor: kRed,
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
      final reportCode = randomAlphaNumeric(10).toUpperCase();
      final fileName   = 'reports/$reportCode/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('files').uploadBinary(fileName, _selectedImageData!,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      final photoUrl = supabase.storage.from('files').getPublicUrl(fileName);
      // Add points for submitting a report
      try {
        final userId = supabase.auth.currentUser?.id;
        if (userId != null) {
          await supabase.rpc('increment_points', params: {'user_id': userId, 'pts': 10});
          // Insert notification
          await supabase.from('notifications').insert({
            'user_id':    userId,
            'title':      isAr ? 'تم تقديم بلاغك!' : 'Report Submitted!',
            'body':       isAr ? 'تم تسجيل بلاغك بنجاح. ستصلك تحديثات عبر هذا القسم.' : 'Your report has been received. You will get updates here.',
            'is_read':    false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {}
      await supabase.from('reports').insert({
        'report_code':     reportCode,
        'title':           isAr ? _selectedDistrict!.nameAr : _selectedDistrict!.nameEn,
        'category':        _selectedCategory!,
        'description':     _descriptionController.text,
        'photo_url':       photoUrl,
        'latitude':        _selectedLocation.latitude,
        'longitude':       _selectedLocation.longitude,
        'status':          'pending',
        'created_at':      DateTime.now().toIso8601String(),
        'user_id':         supabase.auth.currentUser?.id,
        'district':        _selectedDistrict!.nameAr,
        'governor_name':   _selectedDistrict!.governorName,
        'governor_phone':  _selectedDistrict!.governorPhone,
      });
      if (!mounted) return;

      // Check if user has a phone on file
      String? phone;
      try {
        final userId = supabase.auth.currentUser?.id;
        if (userId != null) {
          final profile = await supabase.from('profiles').select('phone').eq('id', userId).single();
          phone = profile['phone']?.toString();
        }
      } catch (_) {}

      // If no phone, ask for it now
      if ((phone == null || phone.isEmpty) && mounted) {
        phone = await _askForPhone(lang);
        // Save it for future use
        if (phone != null && phone.isNotEmpty) {
          try {
            final userId = supabase.auth.currentUser?.id;
            if (userId != null) {
              await supabase.from('profiles').upsert({'id': userId, 'phone': phone});
            }
          } catch (_) {}
        }
      }

      Navigator.of(context).pop();
      _showSuccessDialog(reportCode, lang);

      // Send SMS confirmation
      if (phone != null && phone.isNotEmpty && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _sendSMSConfirmation(phone, reportCode, lang);
      }
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
              child: const Icon(Icons.check_circle_outline, color: kRed, size: 36),
            ),
            const SizedBox(height: 16),
            Text(isAr ? 'تم الإرسال بنجاح!' : 'Report Submitted!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kDark)),
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
                Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kRed, letterSpacing: 2)),
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
                  child: const Icon(Icons.copy_outlined, size: 18, color: kRed),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: kDark,
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

                  // ── 1. Description ─────────────────────────────────
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

                  // AI button
                  _AIClassifyButton(isLoading: _aiLoading, isAr: isAr, onTap: _classifyWithAI),
                  const SizedBox(height: 20),

                  // Category grid
                  _SectionLabel(label: t('select_category', lang: lang)),
                  const SizedBox(height: 8),
                  _CategoryGrid(
                    categories: _categories,
                    selected: _selectedCategory,
                    aiSuggestion: _aiSuggestion,
                    lang: lang,
                    onSelect: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 24),

                  // ── 2. District ────────────────────────────────────
                  _SectionLabel(label: isAr ? 'اسم الحي' : 'District'),
                  const SizedBox(height: 8),
                  _DistrictDropdown(
                    selected: _selectedDistrict,
                    isAr: isAr,
                    onSelect: (d) => setState(() => _selectedDistrict = d),
                  ),
                  const SizedBox(height: 20),

                  // ── 3. Photo ───────────────────────────────────────
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
                          color: _selectedImageData != null ? kRed : Colors.grey.shade300,
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
                                    decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
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
                  const SizedBox(height: 24),

                  // ── 4. Location ────────────────────────────────────
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _SectionLabel(label: t('location_title', lang: lang)),
                    TextButton.icon(
                      onPressed: _locationLoading ? null : _getCurrentLocation,
                      icon: _locationLoading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kRed))
                          : const Icon(Icons.my_location, size: 16, color: kRed),
                      label: Text(isAr ? 'موقعي الحالي' : 'My location',
                          style: const TextStyle(fontSize: 12, color: kRed)),
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
                                decoration: BoxDecoration(color: kRed.withOpacity(0.15), shape: BoxShape.circle),
                                child: const Icon(Icons.location_pin, color: kRed, size: 32),
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
                      isAr ? 'اضغط على الخريطة لتحديد الموقع بدقة' : 'Tap the map to pinpoint the exact location',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
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

// ── District Dropdown ──────────────────────────────────────────────────────

class _DistrictDropdown extends StatelessWidget {
  final District? selected;
  final bool isAr;
  final ValueChanged<District> onSelect;
  const _DistrictDropdown({required this.selected, required this.isAr, required this.onSelect});

  static const _red   = Color(0xFFCC0000);
  static const _dark  = Color(0xFF1A1A2E);

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(children: [
                const Icon(Icons.location_city_outlined, color: kRed, size: 20),
                const SizedBox(width: 10),
                Text(isAr ? 'اختر الحي' : 'Select a District',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kDark)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: kDistricts.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
                itemBuilder: (_, i) {
                  final d = kDistricts[i];
                  final isSelected = selected == d;
                  return InkWell(
                    onTap: () {
                      onSelect(d);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      color: isSelected ? kRed.withOpacity(0.05) : Colors.transparent,
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(isAr ? d.nameAr : d.nameEn,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: isSelected ? kRed : kDark)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.person_outline, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(d.governorName, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            const SizedBox(width: 12),
                            Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(d.governorPhone, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                        ])),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: kRed, size: 20),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected != null ? kRed : Colors.grey.shade300,
            width: selected != null ? 2 : 1.5,
          ),
        ),
        child: Row(children: [
          Icon(Icons.location_city_outlined, color: selected != null ? kRed : Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: selected != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isAr ? selected!.nameAr : selected!.nameEn,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Icon(Icons.person_outline, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(selected!.governorName, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(width: 10),
                      Icon(Icons.phone_outlined, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(selected!.governorPhone, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ]),
                  ])
                : Text(isAr ? 'اختر الحي' : 'Select a district',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: selected != null ? kRed : Colors.grey.shade400, size: 22),
        ]),
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
          gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF1A3A5C)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF1A1A2E).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isLoading)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          else
            const Icon(Icons.auto_awesome, color: Color(0xFF185FA5), size: 18),
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
    'cat_pothole':  {'icon': Icons.warning_amber_rounded, 'color': Color(0xFFF59E0B)},
    'cat_trash':    {'icon': Icons.delete_outline,         'color': Color(0xFFEF4444)},
    'cat_lighting': {'icon': Icons.bolt_outlined,          'color': Color(0xFF6366F1)},
    'cat_sewage':   {'icon': Icons.water_damage_outlined,  'color': Color(0xFF8B5CF6)},
    'cat_water':    {'icon': Icons.water_drop_outlined,    'color': Color(0xFF0EA5E9)},
    'cat_other':    {'icon': Icons.more_horiz,             'color': Color(0xFF64748B)},
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
        final isSelected    = selected == cat;
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
                color: isSelected ? color : (isAISuggested ? const Color(0xFF185FA5) : Colors.grey.shade200),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Stack(children: [
              if (isAISuggested && !isSelected)
                Positioned(
                  top: 4, right: 4,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(color: Color(0xFF185FA5), shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 8),
                  ),
                ),
              // Centered icon + label
              Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, color: isSelected ? color : Colors.grey.shade400, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    t(cat, lang: lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.grey.shade500,
                    ),
                  ),
                ]),
              ),
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
        _bone(h: 14, w: 120),
        const SizedBox(height: 8),
        _bone(h: 100, r: 10),
        const SizedBox(height: 12),
        _bone(h: 48, r: 12),
        const SizedBox(height: 20),
        _bone(h: 14, w: 120),
        const SizedBox(height: 8),
        Row(children: List.generate(3, (_) => Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _bone(h: 80, r: 12),
        )))),
        const SizedBox(height: 20),
        _bone(h: 14, w: 100),
        const SizedBox(height: 8),
        _bone(h: 60, r: 12),
        const SizedBox(height: 20),
        _bone(h: 14, w: 100),
        const SizedBox(height: 8),
        _bone(h: 120, r: 12),
        const SizedBox(height: 20),
        _bone(h: 260, r: 16),
        const SizedBox(height: 32),
        Center(child: Column(children: [
          const CircularProgressIndicator(color: Color(0xFFCC0000)),
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
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)));
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
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A2E)), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

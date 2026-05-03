import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/problem.dart';
import '../main.dart';

class GovernorReportPage extends StatefulWidget {
  final String reportId;
  const GovernorReportPage({super.key, required this.reportId});
  @override
  State<GovernorReportPage> createState() => _GovernorReportPageState();
}

class _GovernorReportPageState extends State<GovernorReportPage> {
  final supabase = Supabase.instance.client;
  final _noteCtrl = TextEditingController();
  bool _uploading = false;
  bool _submitting = false;
  String? _fixPhotoUrl;
  String? _selectedStatus;

  static const _green = Color(0xFF2D6A4F);
  static const _navy  = Color(0xFF0B1F3A);

  Future<void> _pickAndUploadFixPhoto(String reportCode) async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes    = await file.readAsBytes();
      final fileName = 'fix_photos/$reportCode/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('files').uploadBinary(fileName, bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      final url = supabase.storage.from('files').getPublicUrl(fileName);
      setState(() => _fixPhotoUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(appLocale.value.languageCode == 'ar' ? 'تم رفع صورة الإصلاح ✓' : 'Fix photo uploaded ✓'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('فشل رفع الصورة: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submitUpdate(String reportId) async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(appLocale.value.languageCode == 'ar' ? 'الرجاء اختيار الحالة الجديدة' : 'Please select a new status'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_selectedStatus == 'resolved' && _fixPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(appLocale.value.languageCode == 'ar' ? 'يجب رفع صورة الإصلاح قبل تحديد الحالة كـ "تم الحل"' : 'Please upload a fix photo before marking as Resolved'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      final update = <String, dynamic>{
        'status': _selectedStatus,
        if (_fixPhotoUrl != null) 'fix_photo_url': _fixPhotoUrl,
        if (_selectedStatus == 'resolved') 'fixed_at': DateTime.now().toIso8601String(),
      };
      await supabase.from('reports').update(update).eq('id', reportId);

      if (_noteCtrl.text.trim().isNotEmpty) {
        await supabase.from('status_updates').insert({
          'report_id': reportId,
          'text':      _noteCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': 'رئيس الحي',
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(appLocale.value.languageCode == 'ar' ? 'تم تحديث البلاغ بنجاح ✓' : 'Report updated successfully ✓'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ));
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('فشل التحديث: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _statusLabel(String s) {
    final isAr = appLocale.value.languageCode == 'ar';
    if (isAr) {
      switch (s) {
        case 'pending':    return 'قيد الانتظار';
        case 'in_progress':return 'جارٍ العمل';
        case 'resolved':   return 'تم الحل';
        default:           return s;
      }
    } else {
      switch (s) {
        case 'pending':    return 'Pending';
        case 'in_progress':return 'In Progress';
        case 'resolved':   return 'Resolved';
        default:           return s;
      }
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':    return const Color(0xFFF59E0B);
      case 'in_progress':return const Color(0xFF1A56DB);
      case 'resolved':   return _green;
      default:           return Colors.grey;
    }
  }

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
        title: Text(isAr ? 'تفاصيل البلاغ' : 'Report Details', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: supabase.from('reports').select().eq('id', widget.reportId).single(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (!snap.hasData) return const Center(child: Text('لم يتم العثور على البلاغ'));

          final r = snap.data!;
          final problem = Problem.fromSupabase(r);
          _selectedStatus ??= problem.status;
          final existingFixPhoto = r['fix_photo_url'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _statusColor(problem.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _statusColor(problem.status).withOpacity(0.3)),
                ),
                child: Text(_statusLabel(problem.status),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _statusColor(problem.status))),
              ),
              const SizedBox(height: 16),

              // Details card
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  _Row(icon: Icons.tag,                  label: isAr ? 'الكود' : 'Code',     value: problem.reportCode),
                  _Div(),
                  _Row(icon: Icons.location_city,        label: isAr ? 'الحي' : 'District',      value: r['district'] ?? '-'),
                  _Div(),
                  _Row(icon: Icons.person_outline,       label: isAr ? 'رئيس الحي' : 'Governor', value: r['governor_name'] ?? '-'),
                  _Div(),
                  _Row(icon: Icons.phone_outlined,       label: isAr ? 'رقم الهاتف' : 'Phone', value: r['governor_phone'] ?? '-'),
                  _Div(),
                  _Row(icon: Icons.category_outlined,    label: isAr ? 'الفئة' : 'Category',     value: problem.category),
                  _Div(),
                  _Row(icon: Icons.description_outlined, label: isAr ? 'الوصف' : 'Description',     value: problem.description),
                  _Div(),
                  _Row(icon: Icons.calendar_today_outlined, label: isAr ? 'التاريخ' : 'Date',
                      value: '${problem.createdAt.year}/${problem.createdAt.month}/${problem.createdAt.day}'),
                ]),
              ),
              const SizedBox(height: 16),

              // Before photo
              if (problem.photoUrl != null) ...[
                Text(isAr ? 'صورة المشكلة (قبل)' : 'Problem Photo (Before)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(problem.photoUrl!, width: double.infinity, height: 200, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
              ],

              // Map
              Text(isAr ? 'الموقع' : 'Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navy)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 180,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(problem.location.latitude, problem.location.longitude),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.fixcity.app',
                      ),
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(problem.location.latitude, problem.location.longitude),
                          child: const Icon(Icons.location_pin, color: _green, size: 36),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Divider
              Container(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 24),

              // Governor action section
              Text(isAr ? 'إجراء رئيس الحي' : 'Governor Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _navy)),
              const SizedBox(height: 16),

              // Fix photo upload
              Text(isAr ? 'صورة الإصلاح (بعد)' : 'Fix Photo (After)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _navy)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _uploading ? null : () => _pickAndUploadFixPhoto(problem.reportCode),
                child: Container(
                  height: (_fixPhotoUrl ?? existingFixPhoto) != null ? null : 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_fixPhotoUrl ?? existingFixPhoto) != null ? _green : Colors.grey.shade300,
                      width: (_fixPhotoUrl ?? existingFixPhoto) != null ? 2 : 1.5,
                    ),
                  ),
                  child: (_fixPhotoUrl ?? existingFixPhoto) != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(children: [
                            Image.network(_fixPhotoUrl ?? existingFixPhoto!, width: double.infinity, fit: BoxFit.cover),
                            Positioned(
                              top: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.check, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('تم الرفع', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ),
                            Positioned(
                              bottom: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                child: const Icon(Icons.edit, color: Colors.white, size: 16),
                              ),
                            ),
                          ]),
                        )
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _uploading
                              ? const CircularProgressIndicator(color: _green, strokeWidth: 2)
                              : Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(_uploading ? (isAr ? 'جارٍ الرفع...' : 'Uploading...') : (isAr ? 'ارفع صورة بعد الإصلاح' : 'Upload after fix photo'),
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                        ]),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isAr ? 'ملاحظة (اختياري)' : 'Note (optional)',
                  hintText: isAr ? 'مثال: تم إرسال فريق الصيانة وإصلاح المشكلة' : 'e.g. Maintenance team dispatched and issue resolved',
                  prefixIcon: const Icon(Icons.edit_note_outlined, color: _green),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 2)),
                ),
              ),
              const SizedBox(height: 16),

              // Status dropdown
              Text(isAr ? 'تغيير الحالة إلى' : 'Change status to', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: ['pending', 'in_progress', 'resolved'].map((s) =>
                    DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
                onChanged: (v) => setState(() => _selectedStatus = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.swap_horiz_outlined, size: 18, color: Colors.grey),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 2)),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : () => _submitUpdate(widget.reportId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isAr ? 'حفظ التحديث' : 'Save Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 160),
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0B1F3A))),
          ),
        ]),
      ]),
    );
  }
}

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14);
}

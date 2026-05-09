import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/problem.dart';
import '../login_page.dart';
import '../main.dart';
import '../theme.dart';

class ReportDetailsPage extends StatefulWidget {
  final String reportId;
  const ReportDetailsPage({super.key, required this.reportId});
  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  final supabase      = Supabase.instance.client;
  final _updateCtrl   = TextEditingController();
  final _scrollCtrl   = ScrollController();
  final List<String> _statuses = ['pending', 'in_progress', 'resolved'];
  String? _selectedStatus;
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  String _statusLabel(String s, String lang) {
    final isAr = lang == 'ar';
    switch (s) {
      case 'pending':     return isAr ? 'قيد الانتظار' : 'Pending';
      case 'in_progress': return isAr ? 'جارٍ العمل'   : 'In Progress';
      case 'resolved':    return isAr ? 'تم الحل'       : 'Resolved';
      default:            return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':     return const Color(0xFFF59E0B);
      case 'in_progress': return kBlue;
      case 'resolved':    return kSuccess;
      default:            return kGrey;
    }
  }

  Future<void> _addStatusUpdate(String lang) async {
    final isAr = lang == 'ar';
    if (_updateCtrl.text.isEmpty || _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'الرجاء كتابة تحديث واختيار حالة' : 'Please write an update and select a status'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.from('status_updates').insert({
        'report_id':  widget.reportId,
        'text':       _updateCtrl.text,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': 'admin',
      });
      await supabase.from('reports')
          .update({'status': _selectedStatus})
          .eq('id', widget.reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'تم تحديث الحالة ✓' : 'Status updated ✓'),
        backgroundColor: kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${isAr ? 'فشل التحديث' : 'Update failed'}: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _notifyCitizen(String userId, String reportCode, String lang) async {
    final isAr = lang == 'ar';
    try {
      await supabase.from('notifications').insert({
        'user_id':    userId,
        'title':      isAr ? 'تحديث على بلاغك' : 'Update on your report',
        'body':       isAr
            ? 'تم تحديث حالة بلاغك رقم $reportCode'
            : 'Your report $reportCode has been updated',
        'report_id':  widget.reportId,
        'is_read':    false,
        'created_at': DateTime.now().toIso8601String(),
      });
      try { await supabase.rpc('increment_points', params: {'user_id': userId, 'pts': 10}); } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? '✅ تم إشعار المواطن' : '✅ Citizen notified'),
        backgroundColor: kSuccess, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${isAr ? 'فشل الإشعار' : 'Notify failed'}: $e'),
        backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _updateCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: kBg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: kDark,
        foregroundColor: kWhite,
        elevation: 0,
        title: Text(isAr ? 'تفاصيل البلاغ' : 'Report Details',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _reportData == null
          ? FutureBuilder<Map<String, dynamic>>(
              future: supabase.from('reports').select().eq('id', widget.reportId).single(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator(color: kRed));
                if (!snapshot.hasData)
                  return Center(child: Text(isAr ? 'لم يتم العثور على البلاغ' : 'Report not found'));
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _reportData = snapshot.data!);
                });
                return const Center(child: CircularProgressIndicator(color: kRed));
              },
            )
          : Builder(builder: (context) {
          final data    = _reportData!;
          final problem = Problem.fromSupabase(data);
          _selectedStatus ??= problem.status;
          final sc       = _statusColor(problem.status);

          return SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sc.withValues(alpha: 0.3)),
                ),
                child: Text(_statusLabel(problem.status, lang),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sc)),
              ),
              const SizedBox(height: 16),

              // Details card
              Container(
                decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  _Row(icon: Icons.tag,                  label: isAr ? 'الكود'   : 'Code',        value: problem.reportCode),
                  _Div(), _Row(icon: Icons.title_outlined,       label: isAr ? 'العنوان' : 'Title',       value: problem.title),
                  _Div(), _Row(icon: Icons.description_outlined, label: isAr ? 'الوصف'   : 'Description', value: problem.description),
                  _Div(), _Row(icon: Icons.category_outlined,    label: isAr ? 'الفئة'   : 'Category',    value: problem.category),
                  if ((data['district'] ?? '').toString().isNotEmpty) ...[
                    _Div(), _Row(icon: Icons.location_city_outlined, label: isAr ? 'الحي' : 'District', value: data['district']),
                  ],
                  _Div(), _Row(icon: Icons.calendar_today_outlined, label: isAr ? 'التاريخ' : 'Date',
                      value: '${problem.createdAt.year}/${problem.createdAt.month}/${problem.createdAt.day}'),
                ]),
              ),

              // Before photo
              if (problem.photoUrl != null) ...[
                const SizedBox(height: 16),
                Text(isAr ? 'صورة المشكلة' : 'Problem Photo',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDark)),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(16),
                    child: Image.network(problem.photoUrl!, height: 200, width: double.infinity, fit: BoxFit.cover)),
              ],

              // After fix photo
              if ((data['fix_photo_url'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(isAr ? 'صورة بعد الإصلاح' : 'After Fix Photo',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kSuccess)),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(16),
                    child: Image.network(data['fix_photo_url'], height: 200, width: double.infinity, fit: BoxFit.cover)),
              ],

              // Map
              const SizedBox(height: 16),
              Text(isAr ? 'الموقع' : 'Location',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kDark)),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(16),
                child: SizedBox(height: 180, child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(problem.location.latitude, problem.location.longitude),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                        subdomains: const ['a','b','c','d'], userAgentPackageName: 'com.fixcity.app'),
                    MarkerLayer(markers: [Marker(
                      point: LatLng(problem.location.latitude, problem.location.longitude),
                      child: const Icon(Icons.location_pin, color: kRed, size: 36),
                    )]),
                  ],
                )),
              ),

              const SizedBox(height: 24),

              // ── Update section ──────────────────────────────────────
              Text(isAr ? 'إضافة تحديث' : 'Add Update',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kDark)),
              const SizedBox(height: 16),

              FixField(
                controller: _updateCtrl,
                label: isAr ? 'نص التحديث' : 'Update text',
                hint: isAr ? 'مثال: تم إرسال فريق للموقع' : 'e.g. Maintenance team dispatched',
                icon: Icons.edit_note_outlined,
                maxLines: 3,
                onTap: _scrollToBottom,
              ),
              const SizedBox(height: 16),

              Text(isAr ? 'تغيير الحالة إلى' : 'Change status to',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
              const SizedBox(height: 7),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: _statuses.map((s) => DropdownMenuItem(value: s,
                    child: Text(_statusLabel(s, lang)))).toList(),
                onChanged: (v) => setState(() => _selectedStatus = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.swap_horiz_outlined, size: 18, color: kGrey),
                  filled: true, fillColor: kWhite,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kRed, width: 2)),
                ),
              ),
              const SizedBox(height: 16),

              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kRed))
                  : FixGreenButton(
                      label: isAr ? 'إضافة التحديث' : 'Submit Update',
                      onPressed: () => _addStatusUpdate(lang),
                    ),
              const SizedBox(height: 12),

              // Notify citizen button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final report = await supabase.from('reports')
                        .select('user_id, report_code').eq('id', widget.reportId).single();
                    final userId = report['user_id']?.toString() ?? '';
                    final code   = report['report_code']?.toString() ?? '';
                    if (userId.isNotEmpty) await _notifyCitizen(userId, code, lang);
                  },
                  icon: const Icon(Icons.notifications_active_outlined, size: 18),
                  label: Text(isAr ? '🔔 إشعار المواطن' : '🔔 Notify Citizen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBlue, side: const BorderSide(color: kBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(isAr ? 'سجل التحديثات' : 'Update History',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kDark)),
              const SizedBox(height: 12),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase.from('status_updates')
                    .stream(primaryKey: ['id'])
                    .eq('report_id', widget.reportId)
                    .order('updated_at', ascending: false),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kRed));
                  final updates = snap.data!;
                  if (updates.isEmpty) return Text(
                    isAr ? 'لا توجد تحديثات بعد.' : 'No updates yet.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  );
                  return Column(children: updates.map((u) {
                    final date = DateTime.parse(u['updated_at']);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u['text'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kDark)),
                          const SizedBox(height: 3),
                          Text('${date.year}/${date.month}/${date.day}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ])),
                      ]),
                    );
                  }).toList());
                },
              ),
              const SizedBox(height: 32),
            ]),
          );
        }),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon; final String label, value;
  const _Row({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: kGrey),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: kGrey)),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 100),
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
        ),
      ]),
    ]),
  );
}

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14);
}

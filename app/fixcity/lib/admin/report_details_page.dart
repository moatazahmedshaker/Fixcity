import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/problem.dart';
import '../login_page.dart';

class ReportDetailsPage extends StatefulWidget {
  final String reportId;
  const ReportDetailsPage({super.key, required this.reportId});
  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  final supabase = Supabase.instance.client;
  final _updateController = TextEditingController();
  final List<String> _statuses = ['pending', 'in_progress', 'resolved'];
  String? _selectedStatus;
  bool _isLoading = false;

  static const _green = Color(0xFF2D6A4F);
  static const _navy = Color(0xFF0B1F3A);

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'in_progress': return 'جارٍ العمل';
      case 'resolved': return 'تم الحل';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'in_progress': return const Color(0xFF1A56DB);
      case 'resolved': return _green;
      default: return Colors.grey;
    }
  }

  Future<void> _addStatusUpdate() async {
    if (_updateController.text.isEmpty || _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('الرجاء كتابة تحديث واختيار حالة'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.from('status_updates').insert({
        'report_id': int.tryParse(widget.reportId) ?? widget.reportId,
        'text': _updateController.text,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': 'admin',
      });
      await supabase.from('reports').update({'status': _selectedStatus}).eq('id', int.tryParse(widget.reportId) ?? widget.reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('تم تحديث الحالة بنجاح ✓'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      _updateController.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التحديث: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('تفاصيل البلاغ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('reports').select().eq('id', widget.reportId).single().then((d) => [d]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لم يتم العثور على البلاغ'));
          }
          final problem = Problem.fromSupabase(snapshot.data!.first);
          _selectedStatus ??= problem.status;

          return isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _DetailPanel(problem: problem, statusColor: _statusColor, statusLabel: _statusLabel)),
                  Container(width: 1, color: Colors.grey.shade200),
                  Expanded(flex: 2, child: _UpdatePanel(
                    reportId: widget.reportId,
                    controller: _updateController,
                    statuses: _statuses,
                    selectedStatus: _selectedStatus,
                    isLoading: _isLoading,
                    onStatusChanged: (v) => setState(() => _selectedStatus = v),
                    onSubmit: _addStatusUpdate,
                    statusLabel: _statusLabel,
                    supabase: supabase,
                  )),
                ])
              : SingleChildScrollView(child: Column(children: [
                  _DetailPanel(problem: problem, statusColor: _statusColor, statusLabel: _statusLabel),
                  _UpdatePanel(
                    reportId: widget.reportId,
                    controller: _updateController,
                    statuses: _statuses,
                    selectedStatus: _selectedStatus,
                    isLoading: _isLoading,
                    onStatusChanged: (v) => setState(() => _selectedStatus = v),
                    onSubmit: _addStatusUpdate,
                    statusLabel: _statusLabel,
                    supabase: supabase,
                  ),
                ]));
        },
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final Problem problem;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  const _DetailPanel({required this.problem, required this.statusColor, required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(problem.status);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(statusLabel(problem.status), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(height: 16),

        // Details card
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            _Row(icon: Icons.tag, label: 'الكود', value: problem.reportCode),
            _Div(),
            _Row(icon: Icons.title_outlined, label: 'العنوان', value: problem.title),
            _Div(),
            _Row(icon: Icons.description_outlined, label: 'الوصف', value: problem.description),
            _Div(),
            _Row(icon: Icons.category_outlined, label: 'الفئة', value: problem.category),
            _Div(),
            _Row(icon: Icons.calendar_today_outlined, label: 'التاريخ',
                value: '${problem.createdAt.year}/${problem.createdAt.month}/${problem.createdAt.day}'),
          ]),
        ),

        // Photo
        if (problem.photoUrl != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(problem.photoUrl!, height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
        ],

        // Map
        const SizedBox(height: 16),
        const Text('الموقع', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0B1F3A))),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(problem.location.latitude, problem.location.longitude),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(problem.location.latitude, problem.location.longitude),
                    child: const Icon(Icons.location_pin, color: Color(0xFF2D6A4F), size: 36),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ]),
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
  Widget build(BuildContext context) => Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14);
}

class _UpdatePanel extends StatelessWidget {
  final String reportId;
  final TextEditingController controller;
  final List<String> statuses;
  final String? selectedStatus;
  final bool isLoading;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onSubmit;
  final String Function(String) statusLabel;
  final SupabaseClient supabase;

  const _UpdatePanel({
    required this.reportId, required this.controller, required this.statuses,
    required this.selectedStatus, required this.isLoading, required this.onStatusChanged,
    required this.onSubmit, required this.statusLabel, required this.supabase,
  });

  static const _green = Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('إضافة تحديث', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0B1F3A))),
        const SizedBox(height: 16),

        FixField(controller: controller, label: 'نص التحديث', hint: 'مثال: تم إرسال فريق صيانة للموقع', icon: Icons.edit_note_outlined, maxLines: 3),
        const SizedBox(height: 16),

        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('تغيير الحالة إلى', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            value: selectedStatus,
            items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(statusLabel(s)))).toList(),
            onChanged: onStatusChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.swap_horiz_outlined, size: 18, color: Colors.grey),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _green, width: 2)),
            ),
          ),
        ]),

        const SizedBox(height: 20),
        isLoading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : FixGreenButton(label: 'إضافة التحديث', onPressed: onSubmit),

        const SizedBox(height: 24),
        const Text('سجل التحديثات', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0B1F3A))),
        const SizedBox(height: 12),

        StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase.from('status_updates').stream(primaryKey: ['id']).eq('report_id', reportId).order('updated_at', ascending: false),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _green));
            final updates = snapshot.data!;
            if (updates.isEmpty) return Text('لا توجد تحديثات بعد.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13));
            return Column(children: updates.map((u) {
              final date = DateTime.parse(u['updated_at']);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u['text'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text('${date.year}/${date.month}/${date.day}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ])),
                ]),
              );
            }).toList());
          },
        ),
      ]),
    );
  }
}

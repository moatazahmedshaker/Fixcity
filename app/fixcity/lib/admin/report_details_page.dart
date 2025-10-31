import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/problem.dart';

class ReportDetailsPage extends StatefulWidget {
  final String reportId;
  const ReportDetailsPage({Key? key, required this.reportId}) : super(key: key);

  @override
  _ReportDetailsPageState createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  final supabase = Supabase.instance.client;
  final _updateController = TextEditingController();
  
  final List<String> _statuses = ['جديد', 'قيد المراجعة', 'قيد التنفيذ', 'تم الحل'];
  String? _selectedStatus;
  bool _isLoading = false;

  Future<void> _addStatusUpdate() async {
    if (_updateController.text.isEmpty || _selectedStatus == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة تحديث واختيار حالة جديدة')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await supabase.from('status_updates').insert({
        'report_id': int.tryParse(widget.reportId) ?? widget.reportId,
        'text': _updateController.text,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': 'admin', 
      });

      await supabase.from('reports').update({
        'status': _selectedStatus,
      }).eq('id', widget.reportId); 

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الحالة بنجاح')),
      );
      _updateController.clear();
      
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحديث: ${e.toString()}')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل البلاغ'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('reports')
            .select() 
            .eq('id', widget.reportId) 
            .single() 
            .then((data) => [data]), 
            
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لم يتم العثور على البلاغ.'));
          }
          
          final problem = Problem.fromSupabase(snapshot.data!.first);
          _selectedStatus ??= problem.status; 

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('الكود:', problem.reportCode),
                      _buildDetailRow('العنوان:', problem.title),
                      _buildDetailRow('الوصف:', problem.description),
                      _buildDetailRow('الفئة:', problem.category),
                      _buildDetailRow('الحالة الحالية:', problem.status),
                      const SizedBox(height: 16),
                      if (problem.photoUrl != null)
                        Image.network(problem.photoUrl!, height: 300),
                      const SizedBox(height: 16),
                      Text('الموقع على الخريطة', style: Theme.of(context).textTheme.titleMedium),
                      Container(
                        height: 300,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(problem.location.latitude, problem.location.longitude),
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(problem.location.latitude, problem.location.longitude),
                                  child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تحديث الحالة', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _updateController,
                        decoration: const InputDecoration(
                          labelText: 'اكتب التحديث (مثال: تم إرسال فريق)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        items: _statuses.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() { _selectedStatus = newValue; });
                        },
                        decoration: const InputDecoration(
                          labelText: 'تغيير الحالة إلى',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addStatusUpdate,
                            child: const Text('إضافة تحديث'),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text('سجل التحديثات', style: Theme.of(context).textTheme.titleLarge),
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: supabase
                            .from('status_updates')
                            .stream(primaryKey: ['id']) 
                            .eq('report_id', widget.reportId) 
                            .order('updated_at', ascending: false),
                            
                          builder: (context, updatesSnapshot) {
                            if (!updatesSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                            final updates = updatesSnapshot.data!;

                            if (updates.isEmpty) return const Text('لا توجد تحديثات بعد.');

                            return ListView.builder(
                              itemCount: updates.length,
                              itemBuilder: (context, index) {
                                final update = updates[index];
                                final date = DateTime.parse(update['updated_at']);
                                final formattedDate = '${date.year}/${date.month}/${date.day}';
                                
                                return Card(
                                  child: ListTile(
                                    title: Text(update['text']),
                                    subtitle: Text('بتاريخ: $formattedDate'),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
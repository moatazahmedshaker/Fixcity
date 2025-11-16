import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/problem.dart'; 

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  TrackPageState createState() => TrackPageState();
}

class TrackPageState extends State<TrackPage> {
  final supabase = Supabase.instance.client;
  
  final _codeController = TextEditingController();

  Problem? _foundProblem;
  List<StatusUpdate> _updates = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _trackProblem() async {
    if (_codeController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundProblem = null;
      _updates = [];
    });

    String code = _codeController.text.trim().toUpperCase();

    try {
      final reportResponse = await supabase
          .from('reports')
          .select()
          .eq('report_code', code) 
          .limit(1)
          .single();

      _foundProblem = Problem.fromSupabase(reportResponse);

      final updatesResponse = await supabase
          .from('status_updates')
          .select()
          .eq('report_id', _foundProblem!.id!) 
          .order('updated_at', ascending: false);

      if (updatesResponse.isNotEmpty) {
        _updates = updatesResponse
            .map((data) => StatusUpdate.fromSupabase(data))
            .toList();
      }
    } on PostgrestException {
        _errorMessage = 'لم يتم العثور على بلاغ بهذا الكود.';
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء البحث: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('متابعة حالة البلاغ'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'أدخل كود المتابعة',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _trackProblem,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              else if (_foundProblem != null)
                _buildReportDetails()
              else
                const Center(child: Text('أدخل كوداً للبحث عن حالة البلاغ')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportDetails() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نتيجة التتبع',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildDetailRow('الكود:', _foundProblem!.reportCode),
            _buildDetailRow('الحالة الحالية:', _foundProblem!.status),
            _buildDetailRow('العنوان:', _foundProblem!.title),
            _buildDetailRow('الوصف:', _foundProblem!.description),
            if (_foundProblem!.photoUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.network(_foundProblem!.photoUrl!),
              ),
            const SizedBox(height: 24),
            Text('سجل التحديثات:',
                style: Theme.of(context).textTheme.titleLarge),
            _buildUpdatesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildUpdatesList() {
    if (_updates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text('لا توجد تحديثات بعد.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _updates.length,
      itemBuilder: (context, index) {
        final update = _updates[index];
        final formattedDate = '${update.updatedAt.year}/${update.updatedAt.month}/${update.updatedAt.day}';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(update.text),
            subtitle: Text('بتاريخ: $formattedDate'),
          ),
        );
      },
    );
  }
}
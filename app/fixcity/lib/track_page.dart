// lib/track_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/problem.dart'; 

class TrackPage extends StatefulWidget {
  const TrackPage({Key? key}) : super(key: key);

  @override
  _TrackPageState createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final _codeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      var query = await _firestore
          .collection('reports')
          .where('report_code', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _errorMessage = 'لم يتم العثور على بلاغ بهذا الكود';
        });
      } else {
        DocumentSnapshot problemDoc = query.docs.first;
        _foundProblem = Problem.fromJson(problemDoc);

        var updatesQuery = await problemDoc.reference
            .collection('updates')
            .orderBy('updated_at', descending: true)
            .get();

        if (updatesQuery.docs.isNotEmpty) {
          _updates = updatesQuery.docs
              .map((doc) =>
                  StatusUpdate.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء البحث. حاول مرة أخرى.';
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
            _buildUpdatesList(), // This was the missing call
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

  // THIS IS THE MISSING METHOD THAT YOU NEED TO ADD
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
        final date = update.updatedAt.toDate();
        final formattedDate = '${date.year}/${date.month}/${date.day}';

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
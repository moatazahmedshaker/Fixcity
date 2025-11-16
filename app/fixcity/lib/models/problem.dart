import 'package:cloud_firestore/cloud_firestore.dart';

class Problem {
  String? id;
  String reportCode;
  String title;
  String category;
  String description;
  String? photoUrl;
  GeoPoint location; 
  String status;
  Timestamp createdAt;
  String? userId;

  Problem({
    this.id,
    required this.reportCode,
    required this.title,
    required this.category,
    required this.description,
    this.photoUrl,
    required this.location,
    required this.status,
    required this.createdAt,
    this.userId,
  });
  factory Problem.fromSupabase(Map<String, dynamic> data) {
    return Problem(
      id: data['id']?.toString(), 
      reportCode: data['report_code'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photo_url'],
      location: GeoPoint(data['latitude'] ?? 0.0, data['longitude'] ?? 0.0), 
      status: data['status'] ?? 'جديد',
      createdAt: Timestamp.fromDate(DateTime.parse(data['created_at'])), 
      userId: data['user_id']?.toString(),
    );
  }
}
class StatusUpdate {
  String text;
  DateTime updatedAt;
  String? updatedBy; 
  StatusUpdate({
    required this.text,
    required this.updatedAt,
    this.updatedBy,
  });
  factory StatusUpdate.fromSupabase(Map<String, dynamic> data) {
    return StatusUpdate(
      text: data['text'] ?? '',
      updatedAt: DateTime.parse(data['updated_at']), 
      updatedBy: data['updated_by'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }
}
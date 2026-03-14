// No Firebase imports — this app uses Supabase only.

class LatLngPoint {
  final double latitude;
  final double longitude;
  const LatLngPoint(this.latitude, this.longitude);
}

class Problem {
  String? id;
  String reportCode;
  String title;
  String category;
  String description;
  String? photoUrl;
  LatLngPoint location;
  String status;
  DateTime createdAt;
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
      location: LatLngPoint(
        (data['latitude'] as num?)?.toDouble() ?? 0.0,
        (data['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      status: data['status'] ?? 'pending',
      createdAt: DateTime.parse(data['created_at']),
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
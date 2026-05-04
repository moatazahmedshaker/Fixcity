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
  Map<String, dynamic>? data; // raw row — used for fix_photo_url etc.

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
    this.data,
  });

  factory Problem.fromSupabase(Map<String, dynamic> map) {
    return Problem(
      id:          map['id']?.toString(),
      reportCode:  map['report_code'] ?? '',
      title:       map['title'] ?? '',
      category:    map['category'] ?? '',
      description: map['description'] ?? '',
      photoUrl:    map['photo_url'],
      location:    LatLngPoint(
        (map['latitude']  as num?)?.toDouble() ?? 0.0,
        (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      status:    map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
      userId:    map['user_id']?.toString(),
      data:      map,
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
      text:      data['text'] ?? '',
      updatedAt: DateTime.parse(data['updated_at']),
      updatedBy: data['updated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text':       text,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }
}

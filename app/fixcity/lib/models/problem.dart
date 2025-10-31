// lib/models/problem.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Problem {
  String? id; // The document ID from Firestore
  String reportCode; // The human-readable code like "OGJLZ4MQNY"
  String title;
  String category;
  String description;
  String? photoUrl;
  GeoPoint location; // Stores latitude and longitude
  String status;
  Timestamp createdAt;
  String? userId; // To link to a user later

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

  // A factory constructor to create a Problem from a Firestore document
  factory Problem.fromJson(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Problem(
      id: doc.id,
      reportCode: data['report_code'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photo_url'],
      location: data['location'] ?? GeoPoint(0, 0),
      status: data['status'] ?? 'جديد',
      createdAt: data['created_at'] ?? Timestamp.now(),
      userId: data['user_id'],
    );
  }

  // A method to convert a Problem object to a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'report_code': reportCode,
      'title': title,
      'category': category,
      'description': description,
      'photo_url': photoUrl,
      'location': location,
      'status': status,
      'created_at': createdAt,
      'user_id': userId,
    };
  }
}

class StatusUpdate {
  String text;
  Timestamp updatedAt;
  String? updatedBy; // Who made the update (e.g., "admin")

  StatusUpdate({
    required this.text,
    required this.updatedAt,
    this.updatedBy,
  });

  // Factory constructor from Firestore
  factory StatusUpdate.fromJson(Map<String, dynamic> data) {
    return StatusUpdate(
      text: data['text'] ?? '',
      updatedAt: data['updated_at'] ?? Timestamp.now(),
      updatedBy: data['updated_by'],
    );
  }

  // Method to convert to Map
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'updated_at': updatedAt,
      'updated_by': updatedBy,
    };
  }
}
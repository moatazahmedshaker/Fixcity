// lib/report_page.dart
import 'dart:typed_data'; // We use this instead of dart:io
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:random_string/random_string.dart'; 
import 'models/problem.dart'; 

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapController = MapController();

  final List<String> _categories = [
    'حفرة',
    'قمامة',
    'إنارة شوارع',
    'أخرى'
  ];
  String? _selectedCategory;

  // We change from File to Uint8List to support web
  Uint8List? _selectedImageData;
  XFile? _selectedImageFile; // To hold the file details

  LatLng _selectedLocation = const LatLng(30.0444, 31.2357); // Default: Cairo
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _selectedImageFile = pickedFile; // Store the file
      _selectedImageData = await pickedFile.readAsBytes(); // Read its data
      setState(() {});
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_selectedLocation, 15.0);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }
    if (_selectedImageData == null || _selectedImageFile == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إرفاق صورة للمشكلة')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}-${_selectedImageFile!.name}';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('reports/$fileName');
      
      // We use putData instead of putFile
      UploadTask uploadTask = storageRef.putData(_selectedImageData!);
      TaskSnapshot snapshot = await uploadTask;
      String photoUrl = await snapshot.ref.getDownloadURL();

      String reportCode = randomAlphaNumeric(10).toUpperCase();

      Problem newProblem = Problem(
        reportCode: reportCode,
        title: _titleController.text,
        category: _selectedCategory!,
        description: _descriptionController.text,
        photoUrl: photoUrl,
        location: GeoPoint(_selectedLocation.latitude, _selectedLocation.longitude),
        status: 'جديد', 
        createdAt: Timestamp.now(),
      );

      await FirebaseFirestore.instance
          .collection('reports')
          .add(newProblem.toJson());

      if (!context.mounted) return;
      Navigator.of(context).pop(); 
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تم إرسال البلاغ بنjاح'),
          content: Text('كود متابعة البلاغ الخاص بك هو: $reportCode'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); 
  }

  // Helper widget to display the image
  Widget _buildSelectedImage() {
    if (_selectedImageData != null) {
      return Container(
        padding: const EdgeInsets.only(top: 10),
        height: 150,
        child: Image.memory(_selectedImageData!), // Use Image.memory
      );
    } else if (_selectedImageFile != null && kIsWeb) {
      // On web, we can display using the blob URL
      return Container(
        padding: const EdgeInsets.only(top: 10),
        height: 150,
        child: Image.network(_selectedImageFile!.path),
      );
    } else {
      return Container(); // No image selected
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإبلاغ عن مشكلة'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'عنوان المشكلة',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        hint: const Text('اختر الفئة'),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'الرجاء اختيار فئة' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'وصف المشكلة',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'الحقل مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      Text('تحديد الموقع', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Container(
                        height: 300,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLocation,
                            initialZoom: 13.0,
                            onTap: (tapPosition, point) {
                              setState(() {
                                _selectedLocation = point;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 80.0,
                                  height: 80.0,
                                  point: _selectedLocation,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _pickImage,
                            child: const Text('إرفاق صورة'),
                          ),
                          const SizedBox(width: 10),
                          if (_selectedImageData != null)
                            const Icon(Icons.check, color: Colors.green)
                        ],
                      ),
                      _buildSelectedImage(), // Use the new helper widget
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitReport,
                          child: const Text('إرسال البلاغ'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
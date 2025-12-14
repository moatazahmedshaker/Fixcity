import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:random_string/random_string.dart'; 
import 'translations.dart';
import 'main.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  final supabase = Supabase.instance.client;
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapController = MapController();
  
  final List<String> _categories = [
    'cat_pothole',
    'cat_trash',
    'cat_lighting',
    'cat_other'
  ];
  String? _selectedCategory;

  Uint8List? _selectedImageData;
  XFile? _selectedImageFile; 

  LatLng _selectedLocation = const LatLng(30.0444, 31.2357);
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _selectedImageFile = pickedFile; 
      _selectedImageData = await pickedFile.readAsBytes(); 
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
    final lang = appLocale.value.languageCode;

    if (!_formKey.currentState!.validate()) {
      return; 
    }
    if (_selectedImageData == null || _selectedImageFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('fill_fields_error', lang: lang))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    final user = supabase.auth.currentUser;

    try {
      String reportCode = randomAlphaNumeric(10).toUpperCase();

      String fileName =
          'reports/$reportCode/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await supabase.storage.from('files').uploadBinary(
        fileName,
        _selectedImageData!,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      final publicUrlResponse = supabase.storage.from('files').getPublicUrl(fileName);
      String photoUrl = publicUrlResponse;

      await supabase.from('reports').insert({
        'report_code': reportCode,
        'title': _titleController.text,
        'category': _selectedCategory!,
        'description': _descriptionController.text,
        'photo_url': photoUrl,
        'latitude': _selectedLocation.latitude, 
        'longitude': _selectedLocation.longitude,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user?.id, 
      });

      if (!mounted) return;
      Navigator.of(context).pop(); 
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t('success_message', lang: lang)),
          content: Text('$reportCode'),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reportCode));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Code Copied'))
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t('error_message', lang: lang)} $e'))
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

  Widget _buildSelectedImage() {
    if (_selectedImageData != null) {
      return Container(
        padding: const EdgeInsets.only(top: 10),
        height: 150,
        child: Image.memory(_selectedImageData!), 
      );
    } else if (_selectedImageFile != null && kIsWeb) {
      return Container(
        padding: const EdgeInsets.only(top: 10),
        height: 150,
        child: Image.network(_selectedImageFile!.path),
      );
    } else {
      return const SizedBox.shrink(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLocale.value.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('report_page_title', lang: lang)),
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
                      decoration: InputDecoration(
                        labelText: t('problem_title', lang: lang),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? t('fill_fields_error', lang: lang) : null,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      hint: Text(t('select_category', lang: lang)),
                      items: _categories.map((String categoryKey) {
                        return DropdownMenuItem<String>(
                          value: categoryKey,
                          child: Text(t(categoryKey, lang: lang)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? t('fill_fields_error', lang: lang) : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: t('problem_desc', lang: lang),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (value) =>
                          value == null || value.isEmpty ? t('fill_fields_error', lang: lang) : null,
                    ),
                    const SizedBox(height: 16),
                    Text(t('location_title', lang: lang), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
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
                          child: Text(t('pick_image', lang: lang)),
                        ),
                        const SizedBox(width: 10),
                        if (_selectedImageData != null)
                          const Icon(Icons.check, color: Colors.green)
                      ],
                    ),
                    _buildSelectedImage(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitReport,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(t('submit_btn', lang: lang)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
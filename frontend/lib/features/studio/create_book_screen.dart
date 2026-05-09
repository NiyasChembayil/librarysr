import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../providers/book_provider.dart';
import 'book_management_screen.dart';

class CreateBookScreen extends ConsumerStatefulWidget {
  const CreateBookScreen({super.key});

  @override
  ConsumerState<CreateBookScreen> createState() => _CreateBookScreenState();
}

class _CreateBookScreenState extends ConsumerState<CreateBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  File? _coverImage;
  String? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ref.read(apiClientProvider).dio.get('core/categories/');
      setState(() {
        _categories = response.data is List ? response.data : (response.data['results'] ?? []);
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _coverImage = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formData = FormData.fromMap({
        'title': _titleController.text,
        'description': _descController.text,
        'category': _selectedCategoryId,
        'price': '0.00',
        'is_published': 'false',
        if (_coverImage != null)
          'cover': await MultipartFile.fromFile(
            _coverImage!.path, 
            filename: _coverImage!.path.split('/').last,
          ),
      });

      final response = await ref.read(apiClientProvider).dio.post('core/books/', data: formData);
      final newBook = response.data;
      
      // Refresh book list
      ref.read(bookProvider.notifier).fetchBooks();
      
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => BookManagementScreen(
            bookId: newBook['id'], 
            bookTitle: newBook['title']
          ))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create book: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        title: Text('New Masterpiece', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text('CREATE', style: GoogleFonts.inter(color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 140,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: _coverImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_coverImage!, fit: BoxFit.cover))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_rounded, color: Colors.white24, size: 40),
                              const SizedBox(height: 10),
                              Text('Add Cover', style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              _buildLabel('Book Title'),
              _buildTextField(_titleController, 'Enter a captivating title...', (v) => v!.isEmpty ? 'Required' : null),
              
              const SizedBox(height: 20),
              _buildLabel('Category / Genre'),
              _isLoadingCategories 
                ? const LinearProgressIndicator()
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E1E2E),
                        style: GoogleFonts.inter(color: Colors.white),
                        hint: Text('Select Genre', style: GoogleFonts.inter(color: Colors.white24)),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                        items: _categories.map((c) => DropdownMenuItem<String>(
                          value: c['id'].toString(),
                          child: Text(c['name'] ?? 'Unknown'),
                        )).toList(),
                      ),
                    ),
                  ),

              const SizedBox(height: 20),
              _buildLabel('Description'),
              _buildTextField(_descController, 'What is your story about?', (v) => v!.isEmpty ? 'Required' : null, maxLines: 5),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text('CONTINUE TO WORKSPACE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, String? Function(String?)? validator, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }
}

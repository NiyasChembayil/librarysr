import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';

class ChapterEditorScreen extends ConsumerStatefulWidget {
  final int bookId;
  final Map<String, dynamic>? chapter;
  final int nextOrder;

  const ChapterEditorScreen({super.key, required this.bookId, this.chapter, required this.nextOrder});

  @override
  ConsumerState<ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends ConsumerState<ChapterEditorScreen> {
  late QuillController _controller;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  File? _audioFile;
  bool _isSaving = false;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  void _initializeEditor() {
    if (widget.chapter != null) {
      _titleController.text = widget.chapter!['title'] ?? '';
      final content = widget.chapter!['content'] ?? '';
      
      try {
        final doc = Document.fromJson(jsonDecode(content));
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        final doc = Document()..insert(0, content);
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _controller = QuillController.basic();
    }

    _controller.addListener(_updateWordCount);
    _updateWordCount();
  }

  void _updateWordCount() {
    final plainText = _controller.document.toPlainText().trim();
    setState(() {
      _wordCount = plainText.isEmpty ? 0 : plainText.split(RegExp(r'\s+')).length;
    });
  }

  bool _isPickingAudio = false;

  Future<void> _pickAudio() async {
    if (_isPickingAudio) return;
    
    // Synchronously set to true to prevent double-taps before setState fires
    _isPickingAudio = true;
    setState(() {});

    try {
      // Using FileType.any avoids a known iOS simulator bug with FileType.audio/custom
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );
      
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!.toLowerCase();
        if (path.endsWith('.mp3') || path.endsWith('.wav') || path.endsWith('.m4a') || path.endsWith('.aac') || path.endsWith('.ogg')) {
          setState(() => _audioFile = File(result.files.single.path!));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a valid audio file (MP3, WAV, M4A)'), backgroundColor: Colors.orange));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('multiple_request')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio picker is loading. If it fails, please restart the app (Simulator bug).'), backgroundColor: Colors.orange),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not access audio files: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      _isPickingAudio = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a chapter title')));
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final contentJson = jsonEncode(_controller.document.toDelta().toJson());
      
      final formData = FormData.fromMap({
        'title': _titleController.text,
        'content': contentJson,
        'order': widget.chapter?['order'] ?? widget.nextOrder,
        if (_audioFile != null)
          'audio_file': await MultipartFile.fromFile(
            _audioFile!.path, 
            filename: _audioFile!.path.split('/').last,
          ),
      });

      final dio = ref.read(apiClientProvider).dio;
      if (widget.chapter != null) {
        await dio.patch('core/books/${widget.bookId}/chapters/${widget.chapter!['id']}/', data: formData);
      } else {
        await dio.post('core/books/${widget.bookId}/chapters/', data: formData);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          title: Text(
            widget.chapter == null ? 'New Chapter' : 'Edit Chapter',
            style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.black54),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$_wordCount words',
                  style: GoogleFonts.inter(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)))),
              )
            else
              TextButton(
                onPressed: _save,
                child: Text('SAVE', style: GoogleFonts.inter(color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: Column(
          children: [
            // Word-like Toolbar - Using QuillSimpleToolbar for v11.x
            QuillSimpleToolbar(
              controller: _controller,
              config: const QuillSimpleToolbarConfig(
                showSearchButton: false,
                showFontFamily: false,
                showFontSize: false,
                showColorButton: true,
                showBackgroundColorButton: false,
                showLink: true,
                showCodeBlock: false,
                showIndent: true,
                showListCheck: true,
                multiRowsDisplay: false,
              ),
            ),
            const Divider(height: 1, color: Colors.black12),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Chapter Title',
                            hintStyle: GoogleFonts.outfit(color: Colors.black12),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(width: 40, height: 2, color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
                        const SizedBox(height: 50),
                        
                        GestureDetector(
                          onTap: _pickAudio,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mic_rounded, color: Color(0xFF6C63FF), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _audioFile != null ? 'Audio Added' : (widget.chapter?['audio_file'] != null ? 'Update Audio' : 'Add Narration'),
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Adjusted Editor - Using QuillEditor.basic for v11.x
                        QuillEditor.basic(
                          controller: _controller,
                          config: const QuillEditorConfig(
                            scrollable: false,
                            padding: EdgeInsets.zero,
                            autoFocus: true,
                            expands: false,
                          ),
                          focusNode: _focusNode,
                          scrollController: _scrollController,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}

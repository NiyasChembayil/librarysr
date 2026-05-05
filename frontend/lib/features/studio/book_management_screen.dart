import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../providers/book_provider.dart';
import '../studio/chapter_editor_screen.dart';

class BookManagementScreen extends ConsumerStatefulWidget {
  final int bookId;
  final String bookTitle;

  const BookManagementScreen({super.key, required this.bookId, required this.bookTitle});

  @override
  ConsumerState<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends ConsumerState<BookManagementScreen> {
  bool _isLoading = true;
  bool _isPublishing = false;
  bool _isPublished = false;
  List<dynamic> _chapters = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch chapters
      final chResponse = await ref.read(apiClientProvider).dio.get('core/books/${widget.bookId}/chapters/');
      // Fetch book details to check published status
      final bookResponse = await ref.read(apiClientProvider).dio.get('core/books/${widget.bookId}/');
      
      setState(() {
        _chapters = chResponse.data is List ? chResponse.data : (chResponse.data['results'] ?? []);
        _isPublished = bookResponse.data['is_published'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _publishBook() async {
    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one chapter before publishing!')));
      return;
    }

    setState(() => _isPublishing = true);
    try {
      await ref.read(apiClientProvider).dio.patch('core/books/${widget.bookId}/', data: {
        'is_published': true,
      });
      setState(() {
        _isPublished = true;
        _isPublishing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your masterpiece is now LIVE! 🚀'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isPublishing = false);
    }
  }

  Future<void> _addOrEditChapter({Map<String, dynamic>? chapter}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterEditorScreen(
          bookId: widget.bookId,
          chapter: chapter,
          nextOrder: _chapters.length + 1,
        ),
      ),
    );

    if (result == true) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        title: Text(widget.bookTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isPublished)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _isPublishing ? null : _publishBook,
                icon: _isPublishing 
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.rocket_launch_rounded, size: 16),
                label: const Text('GO LIVE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF43E97B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF43E97B).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF43E97B), size: 14),
                  const SizedBox(width: 6),
                  Text('LIVE', style: GoogleFonts.inter(color: const Color(0xFF43E97B), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Chapters', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${_chapters.length} Total', style: GoogleFonts.inter(color: Colors.white38)),
                    ],
                  ),
                ),
                Expanded(
                  child: _chapters.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _chapters.length,
                          itemBuilder: (context, index) {
                            final ch = _chapters[index];
                            return _buildChapterTile(ch, index);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditChapter(),
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('ADD CHAPTER', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildChapterTile(Map<String, dynamic> ch, int index) {
    final bool hasAudio = ch['audio_file'] != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          'Chapter ${index + 1}: ${ch['title']}',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Text('${(ch['content'] ?? '').toString().length} characters', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            if (hasAudio) ...[
              const SizedBox(width: 10),
              const Icon(Icons.audiotrack_rounded, color: Color(0xFF43E97B), size: 14),
              const SizedBox(width: 4),
              Text('Audio added', style: GoogleFonts.inter(color: const Color(0xFF43E97B), fontSize: 12)),
            ],
          ],
        ),
        trailing: const Icon(Icons.edit_note_rounded, color: Colors.white24),
        onTap: () => _addOrEditChapter(chapter: ch),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_stories_rounded, size: 64, color: Colors.white10),
          const SizedBox(height: 20),
          Text('No chapters yet', style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Your story begins with the first word.', style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}

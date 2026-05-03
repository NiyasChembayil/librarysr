import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mention_provider.dart';
import '../../providers/book_provider.dart';
import '../../core/api_client.dart';
import '../../models/book_model.dart';
import '../../widgets/mention_overlay.dart';
import '../../widgets/mention_text_controller.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final MentionTextEditingController _textCtrl = MentionTextEditingController();
  bool _isPosting = false;
  int _charCount = 0;
  
  String _postType = 'UPDATE';
  List<BookModel> _myBooks = [];
  bool _isLoadingBooks = false;
  
  int? _selectedBookId;
  BookModel? _selectedBook;
  int? _selectedChapterId;
  bool _isLoadingChapters = false;
  
  String? _selectedAudioPath;
  String? _selectedAudioFileName;
  bool _isPickingFile = false;
  
  final List<TextEditingController> _pollOptionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  static const int _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      setState(() => _charCount = _textCtrl.text.length);
      _onTextChanged();
    });
    
    // Fetch authored books in background just in case they select QUOTE
    _fetchMyBooks();
  }
  
  Future<void> _fetchMyBooks() async {
    setState(() => _isLoadingBooks = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.get('core/books/?author=me');
      final List data = response.data is List ? response.data : (response.data['results'] ?? []);
      if (mounted) {
        setState(() {
          _myBooks = data.map((json) => BookModel.fromJson(json)).toList();
          _isLoadingBooks = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBooks = false);
    }
  }

  void _onBookSelected(int? bookId) async {
    setState(() {
      _selectedBookId = bookId;
      _selectedChapterId = null;
      _selectedBook = null;
      if (bookId != null) {
        _isLoadingChapters = true;
      }
    });
    
    if (bookId != null) {
      final book = await ref.read(currentBookProvider(bookId).future);
      if (mounted) {
        setState(() {
          _selectedBook = book;
          _isLoadingChapters = false;
          if (book != null && book.chapters.isNotEmpty) {
            _selectedChapterId = book.chapters.first.id;
          }
        });
      }
    }
  }

  /// Detects if the cursor is immediately after an @ token and triggers mention search.
  void _onTextChanged() {
    final text = _textCtrl.text;
    final cursor = _textCtrl.selection.baseOffset;
    if (cursor < 0) return;

    final textBeforeCursor = text.substring(0, cursor);
    final match = RegExp(r'@(\w*)$').firstMatch(textBeforeCursor);
    if (match != null) {
      final query = match.group(1) ?? '';
      ref.read(mentionProvider.notifier).search(query);
    } else {
      ref.read(mentionProvider.notifier).hide();
    }
  }

  /// Inserts the selected mention text in place of the partial @xxx token.
  void _insertMention(String id, String label) {
    final text = _textCtrl.text;
    final cursor = _textCtrl.selection.baseOffset.clamp(0, text.length);
    final textBeforeCursor = text.substring(0, cursor);

    final atIndex = textBeforeCursor.lastIndexOf('@');
    if (atIndex < 0) return;

    late String token;
    final cleanLabel = label.startsWith('@') ? label.substring(1) : label;
    if (cleanLabel.startsWith('[') && cleanLabel.endsWith(']')) {
      final title = cleanLabel.substring(1, cleanLabel.length - 1);
      token = '@[$id|$title]';
    } else {
      token = '@{$id|$cleanLabel}';
    }

    final newText =
        text.substring(0, atIndex) + token + ' ' + text.substring(cursor);
    final newCursor = atIndex + token.length + 1;

    _textCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    ref.read(mentionProvider.notifier).hide();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    for (var ctrl in _pollOptionCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _post() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something to post!')),
      );
      return;
    }
    
    if (_postType == 'QUOTE') {
      if (_selectedBookId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a book for the quote.')),
        );
        return;
      }
      if (_selectedChapterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a chapter for the quote.')),
        );
        return;
      }
    } else if (_postType == 'AUDIO') {
      if (_selectedAudioPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please attach an audio file.')),
        );
        return;
      }
    } else if (_postType == 'POLL') {
      if (_pollOptionCtrls.any((c) => c.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all poll options.')),
        );
        return;
      }
    }

    setState(() => _isPosting = true);
    try {
      if (_postType == 'POLL') {
        await ref.read(postFeedProvider.notifier).createPoll(
          text: text,
          question: text, 
          options: _pollOptionCtrls.map((c) => c.text.trim()).toList(),
        );
      } else {
        await ref.read(postFeedProvider.notifier).createPost(
          text: text,
          postType: _postType,
          bookId: _postType == 'QUOTE' ? _selectedBookId : null,
          chapterId: _postType == 'QUOTE' ? _selectedChapterId : null,
          audioFilePath: _postType == 'AUDIO' ? _selectedAudioPath : null,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final username = authState.profile?.username ?? 'You';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Post',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _isPosting ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Post',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Post Type Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildTypeChip('UPDATE', Icons.edit_note_rounded, 'Update'),
                _buildTypeChip('QUOTE', Icons.format_quote_rounded, 'Quote'),
                _buildTypeChip('AUDIO', Icons.mic_external_on_rounded, 'Audio'),
                _buildTypeChip('POLL', Icons.poll_rounded, 'Poll'),
              ],
            ),
          ),
          
          if (_postType == 'QUOTE')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('Select Book', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  if (_isLoadingBooks)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                    )
                  else if (_myBooks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: Text('No books in your library.', style: TextStyle(color: Colors.redAccent)),
                    )
                  else
                    DropdownButton<int>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E1E2E),
                      value: _selectedBookId,
                      hint: const Text('Choose a book', style: TextStyle(color: Colors.white54)),
                      underline: const SizedBox(),
                      items: _myBooks.map((book) => DropdownMenuItem(
                        value: book.id,
                        child: Text(book.title, style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: _onBookSelected,
                    ),
                    
                  if (_selectedBookId != null) ...[
                    const Divider(color: Colors.white12),
                    const Text('Select Chapter', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    if (_isLoadingChapters)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      )
                    else if (_selectedBook != null && _selectedBook!.chapters.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Text('No chapters found.', style: TextStyle(color: Colors.redAccent)),
                      )
                    else if (_selectedBook != null)
                      DropdownButton<int>(
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E1E2E),
                        value: _selectedChapterId,
                        hint: const Text('Choose a chapter', style: TextStyle(color: Colors.white54)),
                        underline: const SizedBox(),
                        items: _selectedBook!.chapters.map((chapter) => DropdownMenuItem(
                          value: chapter.id,
                          child: Text(chapter.title, style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedChapterId = val),
                      ),
                  ]
                ],
              ),
            ),
            
          if (_postType == 'AUDIO')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.audiotrack_rounded, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectedAudioFileName != null
                        ? Text(
                            _selectedAudioFileName!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const Text(
                            'Select an audio file (mp3, m4a, wav)',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                  ),
                  if (_selectedAudioFileName != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                      onPressed: () => setState(() {
                        _selectedAudioPath = null;
                        _selectedAudioFileName = null;
                      }),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 36),
                      ),
                      onPressed: _isPickingFile ? null : () async {
                        setState(() => _isPickingFile = true);
                        try {
                          final result = await fp.FilePicker.pickFiles(
                            type: fp.FileType.audio,
                          );
                          if (result != null && result.files.single.path != null) {
                            setState(() {
                              _selectedAudioPath = result.files.single.path;
                              _selectedAudioFileName = result.files.single.name;
                            });
                          }
                        } finally {
                          if (mounted) setState(() => _isPickingFile = false);
                        }
                      },
                      child: const Text('Browse'),
                    ),
                ],
              ),
            ),
            
          if (_postType == 'POLL')
            _buildPollEditor(),
            
          // ── Mention dropdown sits above the scroll area ──────────
          Consumer(
            builder: (context, ref, _) {
              final visible = ref.watch(mentionProvider).isVisible;
              if (!visible) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: MentionOverlay(
                  onMentionSelected: _insertMention,
                ),
              );
            },
          ),
          // ── Scrollable compose body ──────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row + text field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          autofocus: true,
                          maxLines: null,
                          maxLength: _maxChars,
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 16, 
                            height: 1.5,
                            fontStyle: _postType == 'QUOTE' ? FontStyle.italic : FontStyle.normal,
                          ),
                          decoration: InputDecoration(
                            hintText: _postType == 'QUOTE' ? "Paste or write your favorite quote..." : "What's on your mind?",
                            hintStyle: TextStyle(
                                color: Colors.grey[600], fontSize: 15, height: 1.5),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Char count
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_charCount / $_maxChars',
                      style: TextStyle(
                        color: _charCount > _maxChars * 0.9
                            ? Colors.red
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, IconData icon, String label) {
    final isSelected = _postType == type;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? const Color(0xFF6C63FF) : Colors.white54,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _postType = type);
      },
      selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
      backgroundColor: const Color(0xFF1E1E2E),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      side: BorderSide(
        color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.08),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildPollEditor() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Poll Options',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._pollOptionCtrls.asMap().entries.map((entry) {
            int idx = entry.key;
            var ctrl = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Option ${idx + 1}',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  if (_pollOptionCtrls.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      onPressed: () =>
                          setState(() => _pollOptionCtrls.removeAt(idx)),
                    ),
                ],
              ),
            );
          }).toList(),
          if (_pollOptionCtrls.length < 5)
            TextButton.icon(
              onPressed: () =>
                  setState(() => _pollOptionCtrls.add(TextEditingController())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Option'),
              style:
                  TextButton.styleFrom(foregroundColor: const Color(0xFF6C63FF)),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/post_provider.dart';
import '../../providers/reading_progress_provider.dart';
import '../../providers/my_books_provider.dart';
import '../../providers/ambient_audio_provider.dart';
import '../../models/book_model.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final int bookId;
  final String title;
  final List<ChapterModel> chapters;
  final int initialChapterIndex;
  final String? recommendedMood;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.title,
    required this.chapters,
    this.initialChapterIndex = 0,
    this.recommendedMood,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late PageController _pageController;
  int _currentChapterIndex = 0;
  double _fontSize = 18.0;
  Color _backgroundColor = const Color(0xFF0F0F1E);
  Color _textColor = Colors.white70;
  bool _isLoadingPrefs = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _loadPreferences();

    // Auto-play recommended mood for this category
    if (widget.recommendedMood != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ambientAudioProvider.notifier).setMood(widget.recommendedMood);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    // Stop ambient audio when leaving reader
    ref.read(ambientAudioProvider.notifier).setMood(null);
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
      final themeIndex = prefs.getInt('reader_theme_index') ?? 0;
      if (themeIndex == 1) {
        _backgroundColor = Colors.white;
        _textColor = Colors.black87;
      } else if (themeIndex == 2) {
        _backgroundColor = const Color(0xFFF4ECD8);
        _textColor = const Color(0xFF5D4037);
      }
      
      // Load bookmark for this specific book
      final bookmark = prefs.getInt('bookmark_${widget.bookId}');
      if (bookmark != null && bookmark < widget.chapters.length) {
        _currentChapterIndex = bookmark;
      }
      
      _pageController = PageController(initialPage: _currentChapterIndex);
      _isLoadingPrefs = false;
    });
    
    // Attempt to restore scroll position after a short delay for the current chapter
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        final scrollPos = prefs.getDouble('bookmark_scroll_${widget.bookId}_$_currentChapterIndex');
        if (scrollPos != null) {
          _scrollController.jumpTo(scrollPos);
        }
      }
    });

    _scrollController.addListener(() {
      // Save scroll position as you read
      if (_scrollController.hasClients) {
        prefs.setDouble('bookmark_scroll_${widget.bookId}_$_currentChapterIndex', _scrollController.offset);
      }
    });
  }

  Future<void> _saveBookmark(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bookmark_${widget.bookId}', index);
  }

  Future<void> _saveThemePreference(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_theme_index', index);
  }

  Future<void> _saveFontSizePreference(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_font_size', size);
  }

  void _changeTheme(Color bg, Color text, int index) {
    setState(() {
      _backgroundColor = bg;
      _textColor = text;
    });
    _saveThemePreference(index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.chapters.isNotEmpty 
              ? widget.chapters[_currentChapterIndex].title 
              : widget.title, 
          style: TextStyle(color: _textColor, fontSize: 16)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
        actions: [
          IconButton(
            onPressed: () => _showMoodsSheet(context),
            icon: Consumer(builder: (context, ref, _) {
              final ambientState = ref.watch(ambientAudioProvider);
              return Icon(
                ambientState.currentMood != null ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                color: ambientState.isPlaying ? const Color(0xFF6C63FF) : _textColor,
              );
            }),
            tooltip: 'Ambient Moods',
          ),
          IconButton(
            onPressed: () => _showSettingsSheet(context),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: widget.chapters.isEmpty
          ? Center(child: Text("No content available", style: TextStyle(color: _textColor)))
          : PageView.builder(
              controller: _pageController,
              itemCount: widget.chapters.length,
              onPageChanged: (index) {
                setState(() => _currentChapterIndex = index);
                _saveBookmark(index);
                ref.read(readingProgressProvider.notifier).updateProgress(widget.bookId, index);
                
                // Auto-move to FINISHED shelf when last chapter is reached
                if (index == widget.chapters.length - 1) {
                  ref.read(myBooksProvider.notifier).updateShelf(widget.bookId, status: 'FINISHED');
                  // Trigger automated milestone post
                  _autoShareMilestone();
                }
              },
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  controller: index == _currentChapterIndex ? _scrollController : null,
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContent(widget.chapters[index].content),
                      if (index == widget.chapters.length - 1) ...[
                        const SizedBox(height: 60),
                        _buildFinishCelebration(),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(30),
              height: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Appearance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Font Size', style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          IconButton(onPressed: () {
                            setState(() => _fontSize--);
                            _saveFontSizePreference(_fontSize);
                          }, icon: const Icon(Icons.remove_circle_outline)),
                          Text('${_fontSize.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () {
                            setState(() => _fontSize++);
                            _saveFontSizePreference(_fontSize);
                          }, icon: const Icon(Icons.add_circle_outline)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text('Theme', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 15),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _themeCircle(const Color(0xFF0F0F1E), Colors.white70, 'Dark', 0),
                      _themeCircle(Colors.white, Colors.black87, 'Light', 1),
                      _themeCircle(const Color(0xFFF4ECD8), const Color(0xFF5D4037), 'Sepia', 2),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _themeCircle(Color bg, Color text, String label, int index) {
    bool isSelected = _backgroundColor == bg;
    return GestureDetector(
      onTap: () {
        _changeTheme(bg, text, index);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.withValues(alpha: 0.3), width: 3),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: isSelected ? const Color(0xFF6C63FF) : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildContent(String content) {
    String text;
    try {
      final jsonData = jsonDecode(content);
      List<dynamic> ops = [];
      
      if (jsonData is Map && jsonData.containsKey('ops')) {
        ops = jsonData['ops'] as List<dynamic>;
      } else if (jsonData is List) {
        ops = jsonData;
      } else {
        text = content;
        return _buildPlainText(text);
      }
      
      text = ops.map((op) => op['insert']?.toString() ?? '').join();
    } catch (e) {
      text = content;
    }

    return _buildPlainText(text);
  }

  Widget _buildPlainText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: _fontSize,
        color: _textColor,
        height: 1.8,
      ),
    );
  }

  Widget _buildFinishCelebration() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withValues(alpha: 0.2),
            const Color(0xFFFF6584).withValues(alpha: 0.2)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text(
            'Congratulations!',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "You've finished '${widget.title}'",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _shareMilestone,
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share Milestone to Feed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showReviewDialog(context),
            icon: const Icon(Icons.rate_review_rounded),
            label: const Text('Review Now'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _autoShareMilestone() async {
    final prefs = await SharedPreferences.getInstance();
    final sharedKey = 'milestone_shared_${widget.bookId}';
    if (prefs.getBool(sharedKey) ?? false) return;

    final text = "I just finished reading '${widget.title}' on Srishty! 📖✨";
    try {
      await ref.read(postFeedProvider.notifier).createPost(
            text: text,
            postType: 'MILESTONE',
            bookId: widget.bookId,
          );
      await prefs.setBool(sharedKey, true);
      debugPrint("✅ Automated milestone shared for book ${widget.bookId}");
    } catch (e) {
      debugPrint("❌ Failed to auto-share milestone: $e");
    }
  }

  void _shareMilestone() async {
    final text = "I just finished reading '${widget.title}'! 📖✨";
    try {
      await ref.read(postFeedProvider.notifier).createPost(
            text: text,
            postType: 'MILESTONE',
            bookId: widget.bookId,
          );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('milestone_shared_${widget.bookId}', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milestone shared to feed! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share milestone: $e')),
        );
      }
    }
  }

  void _showReviewDialog(BuildContext context) {
    final reviewCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Write a Review', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reviewCtrl,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'What did you think of this story?',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6C63FF))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              // Create a post with the review
              ref.read(postFeedProvider.notifier).createPost(
                text: "My Review for '${widget.title}':\n\n${reviewCtrl.text}",
                postType: 'REVIEW',
                bookId: widget.bookId,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review shared to feed! 🌟')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Post Review', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMoodsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Consumer(builder: (context, ref, _) {
          final ambientState = ref.watch(ambientAudioProvider);
          final notifier = ref.read(ambientAudioProvider.notifier);
          
          return Container(
            padding: const EdgeInsets.all(30),
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Reading Moods', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (ambientState.currentMood != null)
                      TextButton(
                        onPressed: () => notifier.setMood(null),
                        child: const Text('Stop', style: TextStyle(color: Colors.redAccent)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 100,
                  child: ambientState.isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: ambientState.availableSounds.length + 1,
                        itemBuilder: (context, index) {
                          if (index == ambientState.availableSounds.length) {
                            // Only allow adding if less than 3 user sounds exist
                            final userSoundsCount = ambientState.availableSounds.where((s) => !s.isSystem).length;
                            if (userSoundsCount >= 3) return const SizedBox.shrink();
                            
                            return _addMoodButton(context, ref);
                          }
                          final sound = ambientState.availableSounds[index];
                          return _moodItem(ref, sound);
                        },
                      ),
                ),
                const SizedBox(height: 30),
                const Text('Mood Volume', style: TextStyle(fontSize: 16, color: Colors.white70)),
                Slider(
                  value: ambientState.volume,
                  onChanged: (val) => notifier.setVolume(val),
                  activeColor: const Color(0xFF6C63FF),
                  inactiveColor: Colors.white10,
                ),
                const Spacer(),
                const Center(
                  child: Text(
                    'Perfect for deep focus reading',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _addMoodButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showAddMoodDialog(context, ref),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10, style: BorderStyle.none, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 30, color: Colors.white54),
            SizedBox(height: 8),
            Text('Add Custom', style: TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showAddMoodDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '🎵');
    String? selectedFilePath;
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Custom Mood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Name (e.g. Jazz)', hintStyle: TextStyle(color: Colors.white24)),
              ),
              TextField(
                controller: emojiCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Emoji', hintStyle: TextStyle(color: Colors.white24)),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                  if (result != null) {
                    setState(() {
                      selectedFilePath = result.files.single.path;
                      selectedFileName = result.files.single.name;
                      if (nameCtrl.text.isEmpty) {
                        nameCtrl.text = selectedFileName!.split('.').first;
                      }
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(selectedFilePath == null ? Icons.library_music_rounded : Icons.check_circle_rounded, color: const Color(0xFF6C63FF)),
                      const SizedBox(height: 8),
                      Text(
                        selectedFileName ?? 'Pick Music from Gallery',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
              onPressed: () async {
                if (selectedFilePath != null && nameCtrl.text.isNotEmpty) {
                  try {
                    await ref.read(ambientAudioProvider.notifier).addCustomSound(
                      nameCtrl.text, emojiCtrl.text, selectedFilePath!
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moodItem(WidgetRef ref, AmbientSoundModel sound) {
    final ambientState = ref.watch(ambientAudioProvider);
    final isSelected = ambientState.currentMoodId == sound.name;
    
    return GestureDetector(
      onLongPress: sound.isSystem ? null : () {
        // Show delete option for custom sounds
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            title: const Text('Delete Custom Mood?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
              TextButton(
                onPressed: () {
                  ref.read(ambientAudioProvider.notifier).deleteCustomSound(sound.id);
                  Navigator.pop(context);
                }, 
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent))
              ),
            ],
          ),
        );
      },
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(ambientAudioProvider.notifier).setMood(isSelected ? null : sound.name);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(sound.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(sound.name, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            if (!sound.isSystem)
               const Icon(Icons.person_outline_rounded, size: 10, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

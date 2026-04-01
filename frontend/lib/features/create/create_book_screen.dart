import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../providers/navigation_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/book_model.dart';

class CreateBookScreen extends ConsumerStatefulWidget {
  const CreateBookScreen({super.key});

  @override
  ConsumerState<CreateBookScreen> createState() => _CreateBookScreenState();
}

class _CreateBookScreenState extends ConsumerState<CreateBookScreen> {
  int _currentStep = 0;
  XFile? _coverImage;
  final ImagePicker _picker = ImagePicker();
  
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  final List<quill.QuillController> _pageControllers = [];
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _addNewPage();
  }

  void _addNewPage() {
    final controller = quill.QuillController.basic();
    // Auto-pagination listener
    controller.addListener(() {
      final text = controller.document.toPlainText();
      // Using ~2500 characters as a standard page limit
      if (text.length > 2500 && _pageControllers.indexOf(controller) == _pageControllers.length - 1) {
        _addNewPage();
      }
    });
    setState(() {
      _pageControllers.add(controller);
    });
    // If not the first page, navigate to it
    if (_pageControllers.length > 1) {
      Future.microtask(() {
        _pageController.animateToPage(
          _pageControllers.length - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _removePage(int index) {
    if (_pageControllers.length <= 1) return;
    setState(() {
      _pageControllers[index].dispose();
      _pageControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    for (var c in _pageControllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _exitStudio() {
    ref.read(navigationProvider.notifier).state = 0; // Back to Home
  }

  Future<void> _pickImage() async {
    try {
      final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
      if (selected != null) {
        setState(() {
          _coverImage = selected;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Text('Author Studio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_currentStep > 0)
                    IconButton(onPressed: () => setState(() => _currentStep--), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
                  IconButton(onPressed: _exitStudio, icon: const Icon(Icons.close_rounded, color: Colors.white54)),
                ],
              ),
            ),
            _buildStepper(),
            Expanded(
              child: _buildCurrentStep(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stepIndicator(0, 'Details'),
          _stepContainer(),
          _stepIndicator(1, 'Writing'),
          _stepContainer(),
          _stepIndicator(2, 'Publish'),
        ],
      ),
    );
  }

  Widget _stepIndicator(int step, String label) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? const Color(0xFF6C63FF) : Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : Center(child: Text('${step + 1}', style: const TextStyle(fontSize: 12))),
        ),
      ],
    );
  }

  Widget _stepContainer() => Expanded(child: Container(height: 2, color: Colors.grey[800]));

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildDetailsStep();
      case 1: return _buildWritingStep();
      case 2: return _buildPublishStep();
      default: return const SizedBox();
    }
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('Book Title', 'Enter a catchy title...', _titleController),
          const SizedBox(height: 20),
          _buildTextField('Category', 'e.g. Science Fiction, Romance...', _categoryController),
          const SizedBox(height: 20),
          const Text('Book Cover', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                image: _coverImage != null
                    ? DecorationImage(
                        image: FileImage(File(_coverImage!.path)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _coverImage == null
                  ? const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.white54)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField('Description', 'What is your story about?', _descController, maxLines: 5),
        ],
      ),
    );
  }

  Widget _buildWritingStep() {
    return Column(
      children: [
        // Shared Toolbar
        quill.QuillSimpleToolbar(
          controller: _pageControllers[_currentPageIndex],
          config: quill.QuillSimpleToolbarConfig(
            headerStyleType: quill.HeaderStyleType.buttons,
            showAlignmentButtons: true,
            showSmallButton: false,
            showInlineCode: false,
            showLink: true,
            showCodeBlock: false,
            showSubscript: false,
            showSuperscript: false,

          ),
        ),
        
        // Page Info & Manual Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Text(
                'Page ${_currentPageIndex + 1} of ${_pageControllers.length}',
                style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addNewPage,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Page'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF6C63FF)),
              ),
              if (_pageControllers.length > 1)
                IconButton(
                  onPressed: () => _removePage(_currentPageIndex),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                ),
            ],
          ),
        ),

        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pageControllers.length,
            onPageChanged: (index) => setState(() => _currentPageIndex = index),
            itemBuilder: (context, index) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: quill.QuillEditor.basic(
                    controller: _pageControllers[index],
                    config: quill.QuillEditorConfig(
                      placeholder: 'Once upon a time...',
                      expands: true,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPublishStep() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 100, color: Color(0xFF6C63FF)),
          const SizedBox(height: 20),
          const Text('Almost Ready!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Review your details and publish your masterwork to the Bookify community.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 40),
          _buildToggleOption('Enable AI Voice Generation', true),
          _buildToggleOption('Make it Paid', false),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption(String label, bool value) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: (v) {},
      activeTrackColor: const Color(0xFF6C63FF).withValues(alpha: 0.5),
      activeThumbColor: const Color(0xFF6C63FF),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 120,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 70,
        borderRadius: 20,
        blur: 10,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)]),
        borderGradient: LinearGradient(colors: [const Color(0xFF6C63FF), const Color(0xFF00D2FF)]),
        child: InkWell(
          onTap: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              // Publish logic
              final authState = ref.read(authProvider);
              
              // Map all pages to plain text for now, or JSON if you prefer
              final pagesData = _pageControllers.map((c) => c.document.toPlainText()).toList();
              
              final newBook = BookModel(
                id: DateTime.now().millisecondsSinceEpoch,
                title: _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
                authorName: authState.profile?.username ?? 'Anomymous',
                coverUrl: _coverImage?.path ?? '',
                description: pagesData.isNotEmpty ? pagesData.first.substring(0, 200 > pagesData.first.length ? pagesData.first.length : 200) : '',
                price: 0.0,
                likesCount: 0,
                totalReads: 0,
                chapters: [],
                pages: pagesData,
              );

              ref.read(bookProvider.notifier).addBook(newBook);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Book published successfully!')),
              );
              // Exit Studio and go back to Home
              ref.read(navigationProvider.notifier).state = 0;
            }
          },
          child: Center(
            child: Text(
              _currentStep < 2 ? 'Next' : 'Publish Book',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

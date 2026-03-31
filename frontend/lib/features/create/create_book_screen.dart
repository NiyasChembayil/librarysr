import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class CreateBookScreen extends StatefulWidget {
  const CreateBookScreen({super.key});

  @override
  State<CreateBookScreen> createState() => _CreateBookScreenState();
}

class _CreateBookScreenState extends State<CreateBookScreen> {
  int _currentStep = 0;

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
          _buildTextField('Book Title', 'Enter a catchy title...'),
          const SizedBox(height: 20),
          _buildTextField('Category', 'e.g. Science Fiction, Romance...'),
          const SizedBox(height: 20),
          const Text('Book Cover', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 200,
              width: 150,
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24, style: BorderStyle.solid)),
              child: const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField('Description', 'What is your story about?', maxLines: 5),
        ],
      ),
    );
  }

  Widget _buildWritingStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: TextField(
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: 'Start writing your masterwork here...',
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
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

  Widget _buildTextField(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book published successfully!')));
              Navigator.pop(context);
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

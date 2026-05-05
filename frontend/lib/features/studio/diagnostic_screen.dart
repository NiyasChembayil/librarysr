import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class DiagnosticScreen extends StatelessWidget {
  const DiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QuillEditor.basic(
        configurations: const QuillEditorConfigurations(),
      ),
    );
  }
}

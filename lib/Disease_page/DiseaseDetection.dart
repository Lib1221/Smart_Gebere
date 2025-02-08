import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Smart Gebere',
      home: ImageAnalyzer(),
    ),
  );
}

class ImageAnalyzer extends StatefulWidget {
  @override
  State<ImageAnalyzer> createState() => ImageAnalyzerState();
}

class ImageAnalyzerState extends State<ImageAnalyzer> {
  Uint8List? _imageBytes;
  String generatedText = '';
  late GenerativeModel? _model;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  void _initializeModel() {
    const String apiKey = '';

    if (apiKey.isEmpty) {
      setState(() {
        generatedText = "API Key is missing. Please set it in the code.";
      });
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  }

  void _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;

        setState(() {
          _imageBytes = file.bytes;
        });
      }
    } catch (e) {
      setState(() {
        generatedText = "Error selecting file: $e";
      });
    }
  }

  void _generateDiseaseInfo() async {
    if (_imageBytes == null) {
      setState(() {
        generatedText = "Please select an image first.";
      });
      return;
    }

    if (_model == null) {
      setState(() {
        generatedText = "Model is not initialized. Check your API key.";
      });
      return;
    }

    String prompt = """
      Analyze the provided plant leaf image and provide the following details:
      
      **Disease Name:** 
      **Local Name:** (Amharic and Afan Oromo)
      **Symptoms:** 
      **Possible Causes:** 
      **Precautions:** 
      **Treatment Options:** 
      
      If the image quality is poor or no disease is detected, indicate that clearly.
    """;

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', _imageBytes!),
      ]),
    ];

    try {
      final response = await _model!.generateContent(content);
      setState(() {
        generatedText = response.text ?? "No response generated.";
      });
      _showBottomSheet();
    } catch (e) {
      setState(() {
        generatedText = "Failed to generate response: $e";
      });
    }
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Markdown(
            data: generatedText,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              p: const TextStyle(fontSize: 16.0),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Gebere'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_imageBytes != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  image: DecorationImage(
                    image: MemoryImage(_imageBytes!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.image),
              label: const Text('Select or Capture Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16.0),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _generateDiseaseInfo,
              child: const Text('Detect Disease'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
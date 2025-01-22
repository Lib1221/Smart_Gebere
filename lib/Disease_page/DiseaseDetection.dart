import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class DiseaseDetection extends StatefulWidget {
  const DiseaseDetection({super.key});

  @override
  State<DiseaseDetection> createState() => _DiseaseDetectionState();
}

class _DiseaseDetectionState extends State<DiseaseDetection> {
  final apiService = ApiService();
  File? _selectedImage;
  String diseaseName = '';
  String diseasePrecautions = '';
  bool detecting = false;
  bool precautionLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile =
        await ImagePicker().pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        diseaseName = '';
        diseasePrecautions = '';
      });
    }
  }

  Future<void> detectDisease() async {
    if (_selectedImage == null) {
      _showErrorSnackBar('Please select or capture an image first.');
      return;
    }

    setState(() {
      detecting = true;
    });

    try {
      diseaseName = await apiService.analyzeImageGemini(image: _selectedImage!);
      setState(() {});
      _showSuccessDialog(diseaseName);
    } catch (error) {
      _showErrorSnackBar(error.toString());
    } finally {
      setState(() {
        detecting = false;
      });
    }
  }

  Future<void> showPrecautions() async {
    if (diseaseName.isEmpty) {
      _showErrorSnackBar('Please detect a disease first.');
      return;
    }

    setState(() {
      precautionLoading = true;
    });

    try {
      if (diseasePrecautions.isEmpty) {
        diseasePrecautions =
            await apiService.sendMessageGemini(userMessage: diseaseName);
      }
      _showSuccessDialog(diseasePrecautions);
    } catch (error) {
      _showErrorSnackBar(error.toString());
    } finally {
      setState(() {
        precautionLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  void _showSuccessDialog(String content) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      title: diseaseName.isEmpty ? 'Precautions' : 'Detected Disease',
      desc: content,
      btnOkText: 'Got it',
      btnOkColor: Colors.green,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disease Detection"),
        centerTitle: true,
        backgroundColor: Colors.green.shade400,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  margin: const EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _selectedImage == null
                      ? Center(
                          child: Text(
                            'No image selected',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: kIsWeb
                              ? Image.network(
                                  _selectedImage!.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                ),
                const SizedBox(height: 10),
                diseaseName.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          'Detected Disease: $diseaseName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 18),
                    elevation: 5,
                    shadowColor: Colors.green.shade700,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Open Gallery',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 18),
                    elevation: 5,
                    shadowColor: Colors.blue.shade700,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Start Camera',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (detecting)
                  const SpinKitWave(color: Colors.green, size: 30)
                else
                  ElevatedButton(
                    onPressed: detectDisease,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 18),
                      elevation: 5,
                      shadowColor: Colors.green.shade800,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Detect Disease',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (diseaseName.isNotEmpty)
                  precautionLoading
                      ? const SpinKitWave(color: Colors.blue, size: 30)
                      : ElevatedButton(
                          onPressed: showPrecautions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 18),
                            elevation: 5,
                            shadowColor: Colors.blue.shade800,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Text(
                                'Show Precautions',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
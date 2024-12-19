import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_gebere/Disease_page/api_service.dart';

class Diseasedetection extends StatefulWidget {
  const Diseasedetection({super.key});

  @override
  State<Diseasedetection> createState() => _DiseaseDetectionstate();
}

class _DiseaseDetectionstate extends State<Diseasedetection> {
  final apiService = ApiService();
  File? _selectedImage;
  String diseaseName = '';
  String diseasePrecautions = '';
  bool detecting = false;
  bool precautionLoading = false;

  /// Picks an image from the specified source (gallery or camera)
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
      diseaseName = await apiService.sendImageToGPT4Vision(image: _selectedImage!);
    } catch (error) {
      _showErrorSnackBar(error.toString());
    } finally {
      setState(() {
        detecting = false;
      });
    }
  }

  /// Fetches precautions for the detected disease
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
        diseasePrecautions = await apiService.sendMessageGPT(diseaseName: diseaseName);
      }
      _showSuccessDialog(diseaseName, diseasePrecautions);
    } catch (error) {
      _showErrorSnackBar(error.toString());
    } finally {
      setState(() {
        precautionLoading = false;
      });
    }
  }

  /// Displays an error message in a SnackBar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  /// Displays a success dialog with disease precautions
  void _showSuccessDialog(String title, String content) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      title: title,
      desc: content,
      btnOkText: 'Got it',
      btnOkColor: Colors.green,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const SizedBox(height: 20),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.2,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(50.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child:ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    const Spacer(), // Push buttons to the bottom
                  ],
                ),
              ],
            ),
          ),
          // Bottom Buttons


          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade300,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('OPEN GALLERY', style: TextStyle(color: Colors.white)),
                      SizedBox(width: 10),
                      Icon(Icons.image, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade300,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('START CAMERA', style: TextStyle(color: Colors.white)),
                      SizedBox(width: 10),
                      Icon(Icons.camera_alt, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (detecting)
                  SpinKitWave(color: Colors.green.shade300, size: 30)
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade300,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: detectDisease,
                    child: const Text(
                      'DETECT',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 10),
                if (diseaseName.isNotEmpty)
                  precautionLoading
                      ? const SpinKitWave(color: Colors.blue, size: 30)
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: showPrecautions,
                          child: const Text(
                            'PRECAUTION',
                            style: TextStyle(color: Colors.white),
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

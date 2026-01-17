import 'package:flutter/material.dart';
import 'package:get/get.dart';

class THelperFunction{
  static Color? getColor(String value){
    //product specific color adn here and it will mathc the attribute colors and show

    if (value == 'Green'){
      return Colors.green;
    }else if (value == 'Red'){
      return Colors.red; 
    }else if (value == 'Blue'){
      return Colors.blue;
    }else if (value == 'Yellow'){
      return Colors.yellow;
    }else if (value == 'Black'){
      return Colors.black;  
    }else if (value == 'White'){
      return Colors.white;
    }else if (value == 'Orange'){
      return Colors.orange;
    }else if (value == 'Purple'){
      return Colors.purple;
    }else if (value == 'Pink'){
      return Colors.pink;
    }else if (value == 'Brown'){
      return Colors.brown;
    }else{
      return null;
    }
  }

  static void showSnackBar(String message){
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      )
    );
  }

  static void showAlert (String title, String message){
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK')
          )
        ]
      )
    );
  }

  static void navigateToScreen(BuildContext){
    Navigator.push(
      Get.context!,
      MaterialPageRoute(
        builder: (context) => const SizedBox()
      )
    );
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  } 

  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

}
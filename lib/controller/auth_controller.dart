// lib/controller/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/services/auth_service.dart';
import 'package:chewata/models/user_model.dart';

class AuthController extends GetxController {
  // Singleton instance
  static AuthController get instance => Get.find();

  // Form controllers for login
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();

  // Form controllers for signup
  final TextEditingController signupFullNameController =
      TextEditingController();
  final TextEditingController signupEmailController = TextEditingController();
  final TextEditingController signupBirthDateController =
      TextEditingController();
  final TextEditingController signupPasswordController =
      TextEditingController();
  final TextEditingController signupConfirmPasswordController =
      TextEditingController();

  // Form keys
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  // Selected birthdate
  Rx<DateTime?> selectedBirthDate = Rx<DateTime?>(null);

  // Auth service
  final AuthService _authService = AuthService.instance;

  // Expose current user as the underlying AuthService userModel (Rx<UserModel?>)
  Rx<UserModel?> get currentUser => _authService.userModel;

  // Handle login
  Future<void> login() async {
    if (loginFormKey.currentState!.validate()) {
      final email = loginEmailController.text.trim();
      final password = loginPasswordController.text.trim();

      final userCredential = await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential != null) {
        // Clear sensitive form data
        clearLoginForm();

        // Successfully logged in
        Get.offAllNamed('/home');
      }
    }
  }

  // Handle signup
  Future<void> signup() async {
    if (signupFormKey.currentState!.validate() &&
        selectedBirthDate.value != null) {
      final email = signupEmailController.text.trim();
      final password = signupPasswordController.text.trim();
      final fullName = signupFullNameController.text.trim();
      final birthDate = selectedBirthDate.value!;

      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        birthDate: birthDate,
      );

      if (userCredential != null) {
        // Clear sensitive form data
        clearSignupForm();

        // Successfully signed up
        Get.offAllNamed('/home');
      }
    } else if (selectedBirthDate.value == null) {
      Get.snackbar('Error', 'Please select your birth date');
    }
  }

  // Clear login form
  void clearLoginForm() {
    loginEmailController.clear();
    loginPasswordController.clear();
  }

  // Clear signup form
  void clearSignupForm() {
    signupFullNameController.clear();
    signupEmailController.clear();
    signupBirthDateController.clear();
    signupPasswordController.clear();
    signupConfirmPasswordController.clear();
    selectedBirthDate.value = null;
  }

  // Clear all forms
  void clearAllForms() {
    clearLoginForm();
    clearSignupForm();
  }

  // Handle logout
  void logout() async {
    await _authService.logout();
    clearAllForms();
    Get.offAllNamed('/auth');
  }

  // Set selected birth date
  void setSelectedBirthDate(DateTime date) {
    selectedBirthDate.value = date;
    signupBirthDateController.text = "${date.day}/${date.month}/${date.year}";
  }

  @override
  void onClose() {
    // Dispose all controllers
    loginEmailController.dispose();
    loginPasswordController.dispose();
    signupFullNameController.dispose();
    signupEmailController.dispose();
    signupBirthDateController.dispose();
    signupPasswordController.dispose();
    signupConfirmPasswordController.dispose();
    super.onClose();
  }
}

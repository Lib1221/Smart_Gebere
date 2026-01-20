import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewata/models/user_model.dart';
import 'package:chewata/services/auth_service.dart';

class AccountController extends GetxController {
  static AccountController get instance => Get.find();

  final AuthService _authService = AuthService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Rx variables for user data
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;

  // Form controllers for personal information
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Selected birthdate
  Rx<DateTime?> selectedBirthDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    // Listen to changes in AuthService's userModel
    ever(_authService.userModel, _handleUserModelChange);
    loadUserData();
  }

  // Add this method to handle user model changes from AuthService
  void _handleUserModelChange(UserModel? userModel) {
    if (userModel != null) {
      user.value = userModel;
      // Update form controllers when userModel changes
      _updateFormControllers();
    } else {
      user.value = null;
    }
  }

  // Add a method to update form controllers
  void _updateFormControllers() {
    if (user.value != null) {
      fullNameController.text = user.value!.fullName;
      selectedBirthDate.value = user.value!.birthDate;
      birthDateController.text =
          "${user.value!.birthDate.day}/${user.value!.birthDate.month}/${user.value!.birthDate.year}";
    }
  }

  Future<void> loadUserData() async {
    isLoading.value = true;
    try {
      // Get current user data
      final currentUser = _authService.firebaseUser.value;
      if (currentUser != null) {
        user.value = await _authService.getUserDataFromFirestore(
          currentUser.uid,
        );

        // Populate form controllers with current data
        _updateFormControllers();
      }
    } catch (e) {
      print('Error loading user data: $e');
      Get.snackbar('Error', 'Failed to load user data');
    } finally {
      isLoading.value = false;
    }
  }

  // Add a method to refresh user data
  Future<void> refreshUserData() async {
    // Only refresh if not currently loading
    if (!isLoading.value) {
      await loadUserData();
    }
  }

  // Clear user data when logging out
  void clearUserData() {
    user.value = null;
    fullNameController.clear();
    birthDateController.clear();
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    selectedBirthDate.value = null;
  }

  void setSelectedBirthDate(DateTime date) {
    selectedBirthDate.value = date;
    birthDateController.text = "${date.day}/${date.month}/${date.year}";
  }

  Future<bool> updatePersonalInfo() async {
    if (fullNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Name cannot be empty');
      return false;
    }

    if (selectedBirthDate.value == null) {
      Get.snackbar('Error', 'Please select your birth date');
      return false;
    }

    isUpdating.value = true;
    try {
      final userId = _authService.firebaseUser.value?.uid;
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return false;
      }

      // Update user data in Firestore
      await _firestore.collection('users').doc(userId).update({
        'fullName': fullNameController.text.trim(),
        'birthDate': selectedBirthDate.value!.toIso8601String(),
      });

      // Refresh user data
      await loadUserData();

      Get.snackbar('Success', 'Personal information updated successfully');
      return true;
    } catch (e) {
      print('Error updating personal info: $e');
      Get.snackbar('Error', 'Failed to update personal information');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> updatePassword() async {
    // Restrict password change for demo/test account
    final currentAuthUser = _authService.firebaseUser.value;
    final String? email = currentAuthUser?.email?.toLowerCase();
    if (email == 'abel@gmail.com') {
      // Show a clear, blocking alert and abort
      Get.defaultDialog(
        title: 'Password change disabled',
        middleText:
            'Password changes are disabled for the demo account (abel@gmail.com). Please sign in with your own account to change the password.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
      return false;
    }

    if (currentPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      Get.snackbar('Error', 'All password fields are required');
      return false;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      Get.snackbar('Error', 'New passwords do not match');
      return false;
    }

    isUpdating.value = true;
    try {
      // Get current user
      final currentUser = _authService.firebaseUser.value;
      if (currentUser == null) {
        Get.snackbar('Error', 'User not authenticated');
        return false;
      }

      // Create credential with current password
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPasswordController.text,
      );

      // Reauthenticate user
      await currentUser.reauthenticateWithCredential(credential);

      // Update password
      await currentUser.updatePassword(newPasswordController.text);

      // Clear password fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.snackbar('Success', 'Password updated successfully');
      return true;
    } catch (e) {
      print('Error updating password: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password') {
          Get.snackbar('Error', 'Current password is incorrect');
        } else {
          Get.snackbar('Error', 'Failed to update password: ${e.message}');
        }
      } else {
        Get.snackbar('Error', 'Failed to update password');
      }
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  @override
  void onClose() {
    // Dispose form controllers
    fullNameController.dispose();
    birthDateController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

import 'package:chewata/screen/auth/auth_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingController extends GetxController {
  static OnBoardingController get instance => Get.find();

  ///variables
  final pageController = PageController();
  Rx<int> currentIndex = 0.obs;

  ///
  /// updage current index when page scorll
  void updatePageIndicator(index) {
    currentIndex.value = index;
  }

  //Jump to the specifice dot selected page.
  void dotNavigationClick(index) {
    currentIndex.value = index;
    pageController.jumpToPage(index);
  }

  ///update current index & jump to next page
  void nextPage() {
    if (currentIndex.value == 2) {
      // Navigate to LoginScreen and remove OnBoardingScreen from the stack
      _completeOnboardingAndGoToAuth();
    } else {
      currentIndex.value += 1; // Increment the current index
      pageController.animateToPage(
        currentIndex.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  ///update current index & jump to the last page
  void skipPage() {
    currentIndex.value = 2;
    pageController.jumpToPage(2);
  }

  // Persist that onboarding has been seen and navigate to Auth
  Future<void> _completeOnboardingAndGoToAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (_) {}
    Get.off(() => const AuthScreen());
  }
}

import 'package:chewata/services/setting_service.dart';
import 'package:get/get.dart';
import 'package:chewata/services/auth_service.dart';

class PrivacySettingsController extends GetxController {
  final SettingsService _settingsService = SettingsService.instance;
  final AuthService _authService = AuthService.instance;

  final RxBool isLoading = false.obs;

  // Reactive variables to track current settings
  final RxBool showOnlineStatus = true.obs;
  final RxBool enableNotifications = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadCurrentSettings();
  }

  void loadCurrentSettings() {
    final user = _authService.userModel.value;
    if (user != null) {
      print(
        'Loading settings - showOnlineStatus: ${user.showOnlineStatus}, enableNotifications: ${user.enableNotifications}',
      );
      showOnlineStatus.value = user.showOnlineStatus;
      enableNotifications.value = user.enableNotifications;
    } else {
      print('User model is null when loading settings');
    }
  }

  Future<bool> updateOnlineStatusVisibility(bool show) async {
    isLoading.value = true;
    try {
      print('Updating showOnlineStatus to: $show');
      final result = await _settingsService.updateOnlineStatusVisibility(show);
      if (result) {
        showOnlineStatus.value = show;
        print('Successfully updated showOnlineStatus to: $show');
      } else {
        print('Failed to update showOnlineStatus');
      }
      return result;
    } catch (e) {
      print('Error in controller: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateNotificationPreference(bool enable) async {
    isLoading.value = true;
    try {
      final result = await _settingsService.updateNotificationPreference(
        enable,
      );
      if (result) {
        enableNotifications.value = enable;
      }
      return result;
    } catch (e) {
      print('Error in controller: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

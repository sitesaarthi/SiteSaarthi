import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------
/// General Settings Model
/// ---------------------------
class GeneralSettingsData {
  final String language;
  final String startupScreen;
  final String syncMode;
  final bool lowDataMode;
  final bool autoUpdateProjectData;
  final TimeOfDay workStart;
  final TimeOfDay workEnd;

  GeneralSettingsData({
    required this.language,
    required this.startupScreen,
    required this.syncMode,
    required this.lowDataMode,
    required this.autoUpdateProjectData,
    required this.workStart,
    required this.workEnd,
  });
}

/// ---------------------------
/// Chat Settings Model
/// ---------------------------
class ChatSettingsData {
  final String chatTheme; // Light / Dark / System
  final String wallpaper; // Default / Solid Color / Site Photos
  final double chatFontScale; // 0.9 -> 1.2

  final bool lockScreenPreview;
  final bool showLastSeen;
  final bool typingIndicator;

  final bool autoDownloadMedia;
  final bool voiceAutoPlay;
  final bool cloudBackup;

  ChatSettingsData({
    required this.chatTheme,
    required this.wallpaper,
    required this.chatFontScale,
    required this.lockScreenPreview,
    required this.showLastSeen,
    required this.typingIndicator,
    required this.autoDownloadMedia,
    required this.voiceAutoPlay,
    required this.cloudBackup,
  });
}

class NotificationSettingsData {
  // Message Alerts
  final bool chatNotifications;
  final bool groupNotifications;
  final bool muteProjects;
  final String notificationSound; // Default / Silent / Beep / Bell
  final bool vibration;

  // Site Alerts
  final bool materialLeakageAlerts;
  final bool lowStockAlerts;
  final bool labourAbsenceAlerts;
  final bool delayRiskAlerts;
  final bool paymentApprovalAlerts;

  // Call Alerts
  final bool incomingCallNotifications;
  final bool videoCallNotifications;
  final bool silentDuringMeetings;

  NotificationSettingsData({
    required this.chatNotifications,
    required this.groupNotifications,
    required this.muteProjects,
    required this.notificationSound,
    required this.vibration,
    required this.materialLeakageAlerts,
    required this.lowStockAlerts,
    required this.labourAbsenceAlerts,
    required this.delayRiskAlerts,
    required this.paymentApprovalAlerts,
    required this.incomingCallNotifications,
    required this.videoCallNotifications,
    required this.silentDuringMeetings,
  });
}

class AccessibilitySettingsData {
  final double fontScale; // 0.9 -> 1.25
  final bool highContrast;
  final bool boldText;
  final String colorBlindMode; // Off / Protanopia / Deuteranopia / Tritanopia
  final bool readAloudEnabled;
  final double readSpeed; // 0.5 -> 2.0
  final double textSpacing; // 0.0 -> 2.0
  final double buttonScale; // 0.9 -> 1.2

  AccessibilitySettingsData({
    required this.fontScale,
    required this.highContrast,
    required this.boldText,
    required this.colorBlindMode,
    required this.readAloudEnabled,
    required this.readSpeed,
    required this.textSpacing,
    required this.buttonScale,
  });
}

class CallSettingsData {
  final String defaultCallType; // Voice / Video
  final String cameraSelection; // Front / Rear
  final double micSensitivity;  // 0.0 -> 1.0

  final bool noiseCancellation;
  final bool lowBandwidthMode;
  final bool callRecording;

  final bool speakerAutoOn;
  final String callQuality; // Low / Medium / HD

  CallSettingsData({
    required this.defaultCallType,
    required this.cameraSelection,
    required this.micSensitivity,
    required this.noiseCancellation,
    required this.lowBandwidthMode,
    required this.callRecording,
    required this.speakerAutoOn,
    required this.callQuality,
  });
}



class AppSettingsStore {
  // ✅ Global notifiers used in MaterialApp
  static final ValueNotifier<double> fontScale = ValueNotifier<double>(1.0);
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  /// load global settings at startup
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // global font
    fontScale.value = prefs.getDouble("fontScale") ?? 1.0;

    // global theme
    final theme = prefs.getString("themeMode") ?? "light";
    themeMode.value = _stringToThemeMode(theme);
  }

  // ---------------------------
  // ✅ GLOBAL setters
  // ---------------------------
  static Future<void> setFontScale(double value) async {
    fontScale.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("fontScale", value);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("themeMode", _themeModeToString(mode));
  }

  // ---------------------------
  // ✅ GENERAL SETTINGS
  // ---------------------------
  static Future<GeneralSettingsData> loadGeneralSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final language = prefs.getString("language") ?? "English";
    final startupScreen = prefs.getString("startupScreen") ?? "Dashboard";
    final syncMode = prefs.getString("syncMode") ?? "Wi-Fi only";

    final lowDataMode = prefs.getBool("lowDataMode") ?? false;
    final autoUpdateProjectData =
        prefs.getBool("autoUpdateProjectData") ?? true;

    final wsH = prefs.getInt("workStartH") ?? 9;
    final wsM = prefs.getInt("workStartM") ?? 0;
    final weH = prefs.getInt("workEndH") ?? 18;
    final weM = prefs.getInt("workEndM") ?? 0;

    return GeneralSettingsData(
      language: language,
      startupScreen: startupScreen,
      syncMode: syncMode,
      lowDataMode: lowDataMode,
      autoUpdateProjectData: autoUpdateProjectData,
      workStart: TimeOfDay(hour: wsH, minute: wsM),
      workEnd: TimeOfDay(hour: weH, minute: weM),
    );
  }

  static Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", value);
  }

  static Future<void> setStartupScreen(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("startupScreen", value);
  }

  static Future<void> setSyncMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("syncMode", value);
  }

  static Future<void> setLowDataMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("lowDataMode", value);
  }

  static Future<void> setAutoUpdateProjectData(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("autoUpdateProjectData", value);
  }

  static Future<void> setWorkingHours(TimeOfDay start, TimeOfDay end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("workStartH", start.hour);
    await prefs.setInt("workStartM", start.minute);
    await prefs.setInt("workEndH", end.hour);
    await prefs.setInt("workEndM", end.minute);
  }

  // ---------------------------
  // ✅ CHAT SETTINGS
  // ---------------------------
  static Future<ChatSettingsData> loadChatSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return ChatSettingsData(
      chatTheme: prefs.getString("chatTheme") ?? "System",
      wallpaper: prefs.getString("chatWallpaper") ?? "Default",
      chatFontScale: prefs.getDouble("chatFontScale") ?? 1.0,
      lockScreenPreview: prefs.getBool("lockPreview") ?? true,
      showLastSeen: prefs.getBool("lastSeen") ?? true,
      typingIndicator: prefs.getBool("typingIndicator") ?? true,
      autoDownloadMedia: prefs.getBool("autoDownloadMedia") ?? true,
      voiceAutoPlay: prefs.getBool("voiceAutoPlay") ?? true,
      cloudBackup: prefs.getBool("chatBackup") ?? false,
    );
  }

  static Future<void> setChatTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("chatTheme", value);
  }

  static Future<void> setChatWallpaper(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("chatWallpaper", value);
  }

  static Future<void> setChatFontScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("chatFontScale", value);
  }

  static Future<void> setLockPreview(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("lockPreview", value);
  }

  static Future<void> setLastSeen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("lastSeen", value);
  }

  static Future<void> setTypingIndicator(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("typingIndicator", value);
  }

  static Future<void> setAutoDownloadMedia(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("autoDownloadMedia", value);
  }

  static Future<void> setVoiceAutoPlay(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("voiceAutoPlay", value);
  }

  static Future<void> setChatBackup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("chatBackup", value);
  }

  // ---------------------------
  // helpers
  // ---------------------------
  static ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case "dark":
        return ThemeMode.dark;
      case "system":
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return "dark";
      case ThemeMode.system:
        return "system";
      case ThemeMode.light:
      default:
        return "light";
    }
  }

  // ---------------------------
// ✅ NOTIFICATION SETTINGS
// ---------------------------
  static Future<NotificationSettingsData> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return NotificationSettingsData(
      // Message alerts
      chatNotifications: prefs.getBool("n_chat") ?? true,
      groupNotifications: prefs.getBool("n_group") ?? true,
      muteProjects: prefs.getBool("n_mute_projects") ?? false,
      notificationSound: prefs.getString("n_sound") ?? "Default",
      vibration: prefs.getBool("n_vibration") ?? true,

      // Site alerts
      materialLeakageAlerts: prefs.getBool("n_material_leak") ?? true,
      lowStockAlerts: prefs.getBool("n_low_stock") ?? true,
      labourAbsenceAlerts: prefs.getBool("n_labour_absence") ?? true,
      delayRiskAlerts: prefs.getBool("n_delay_risk") ?? true,
      paymentApprovalAlerts: prefs.getBool("n_payment_approval") ?? true,

      // Call alerts
      incomingCallNotifications: prefs.getBool("n_incoming_call") ?? true,
      videoCallNotifications: prefs.getBool("n_video_call") ?? true,
      silentDuringMeetings: prefs.getBool("n_silent_meetings") ?? false,
    );
  }

  static Future<void> setChatNotifications(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_chat", v);
  }

  static Future<void> setGroupNotifications(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_group", v);
  }

  static Future<void> setMuteProjects(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_mute_projects", v);
  }

  static Future<void> setNotificationSound(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("n_sound", v);
  }

  static Future<void> setVibration(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_vibration", v);
  }

  static Future<void> setMaterialLeakageAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_material_leak", v);
  }

  static Future<void> setLowStockAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_low_stock", v);
  }

  static Future<void> setLabourAbsenceAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_labour_absence", v);
  }

  static Future<void> setDelayRiskAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_delay_risk", v);
  }

  static Future<void> setPaymentApprovalAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_payment_approval", v);
  }

  static Future<void> setIncomingCallNotifications(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_incoming_call", v);
  }

  static Future<void> setVideoCallNotifications(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_video_call", v);
  }

  static Future<void> setSilentDuringMeetings(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("n_silent_meetings", v);
  }

  // ---------------------------
// ✅ ACCESSIBILITY SETTINGS
// ---------------------------
  static Future<AccessibilitySettingsData> loadAccessibilitySettings() async {
    final prefs = await SharedPreferences.getInstance();

    return AccessibilitySettingsData(
      fontScale: prefs.getDouble("a_fontScale") ??
          (prefs.getDouble("fontScale") ?? 1.0),
      highContrast: prefs.getBool("a_highContrast") ?? false,
      boldText: prefs.getBool("a_boldText") ?? false,
      colorBlindMode: prefs.getString("a_colorBlindMode") ?? "Off",
      readAloudEnabled: prefs.getBool("a_readAloud") ?? false,
      readSpeed: prefs.getDouble("a_readSpeed") ?? 1.0,
      textSpacing: prefs.getDouble("a_textSpacing") ?? 0.0,
      buttonScale: prefs.getDouble("a_buttonScale") ?? 1.0,
    );
  }

  static Future<void> setAccessibilityFontScale(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("a_fontScale", v);

    // ✅ also sync with global app fontScale
    await setFontScale(v);
  }

  static Future<void> setHighContrast(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("a_highContrast", v);
  }

  static Future<void> setBoldText(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("a_boldText", v);
  }

  static Future<void> setColorBlindMode(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("a_colorBlindMode", v);
  }

  static Future<void> setReadAloudEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("a_readAloud", v);
  }

  static Future<void> setReadSpeed(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("a_readSpeed", v);
  }

  static Future<void> setTextSpacing(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("a_textSpacing", v);
  }

  static Future<void> setButtonScale(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("a_buttonScale", v);
  }
  // ---------------------------
// ✅ CALL SETTINGS
// ---------------------------
static Future<CallSettingsData> loadCallSettings() async {
  final prefs = await SharedPreferences.getInstance();

  return CallSettingsData(
    defaultCallType: prefs.getString("c_defaultType") ?? "Voice",
    cameraSelection: prefs.getString("c_camera") ?? "Front",
    micSensitivity: prefs.getDouble("c_mic") ?? 0.6,
    noiseCancellation: prefs.getBool("c_noise") ?? true,
    lowBandwidthMode: prefs.getBool("c_lowbw") ?? false,
    callRecording: prefs.getBool("c_record") ?? false,
    speakerAutoOn: prefs.getBool("c_speaker") ?? true,
    callQuality: prefs.getString("c_quality") ?? "HD",
  );
}

static Future<void> setDefaultCallType(String v) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("c_defaultType", v);
}

static Future<void> setCameraSelection(String v) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("c_camera", v);
}

static Future<void> setMicSensitivity(double v) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble("c_mic", v);
}

static Future<void> setNoiseCancellation(bool v) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("c_noise", v);
}

static Future<void> setLowBandwidthMode(bool v) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("c_lowbw", v);
}

static Future<void> setCallRecording(bool v) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("c_record", v);
}

static Future<void> setSpeakerAutoOn(bool v) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("c_speaker", v);
}

static Future<void> setCallQuality(String v) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("c_quality", v);
}

}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _privacyPolicyAcceptedKey = 'privacy_policy_accepted';
  static const String _darkModeKey = 'dark_mode';
  static const String _themeColorKey = 'theme_color';
  static const String _imageQualityKey = 'image_quality';
  static const String _autoSaveResultsKey = 'auto_save_results';
  static const String _autoDeleteUploadsKey = 'auto_delete_uploads';
  static const String _saveHistoryKey = 'save_history';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _uploadSizeLimitKey = 'upload_size_limit';
  static const String _languageKey = 'language';

  bool _privacyPolicyAccepted = false;
  bool _darkMode = false;
  String _themeColor = 'default';
  String _imageQuality = 'medium';
  bool _autoSaveResults = false;
  bool _autoDeleteUploads = true;
  bool _saveHistory = true;
  bool _notificationsEnabled = true;
  String _uploadSizeLimit = '1024';
  String _language = 'en';

  // Getters
  bool get privacyPolicyAccepted => _privacyPolicyAccepted;
  bool get darkMode => _darkMode;
  String get themeColor => _themeColor;
  String get imageQuality => _imageQuality;
  bool get autoSaveResults => _autoSaveResults;
  bool get autoDeleteUploads => _autoDeleteUploads;
  bool get saveHistory => _saveHistory;
  bool get notificationsEnabled => _notificationsEnabled;
  String get uploadSizeLimit => _uploadSizeLimit;
  String get language => _language;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _privacyPolicyAccepted = prefs.getBool(_privacyPolicyAcceptedKey) ?? false;
    _darkMode = prefs.getBool(_darkModeKey) ?? false;
    _themeColor = prefs.getString(_themeColorKey) ?? 'default';
    _imageQuality = prefs.getString(_imageQualityKey) ?? 'medium';
    _autoSaveResults = prefs.getBool(_autoSaveResultsKey) ?? false;
    _autoDeleteUploads = prefs.getBool(_autoDeleteUploadsKey) ?? true;
    _saveHistory = prefs.getBool(_saveHistoryKey) ?? true;
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    _uploadSizeLimit = prefs.getString(_uploadSizeLimitKey) ?? '1024';
    _language = prefs.getString(_languageKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setPrivacyPolicyAccepted(bool value) async {
    _privacyPolicyAccepted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyPolicyAcceptedKey, value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    notifyListeners();
  }

  Future<void> setThemeColor(String value) async {
    _themeColor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeColorKey, value);
    notifyListeners();
  }

  Future<void> setImageQuality(String value) async {
    _imageQuality = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imageQualityKey, value);
    notifyListeners();
  }

  Future<void> setAutoSaveResults(bool value) async {
    _autoSaveResults = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveResultsKey, value);
    notifyListeners();
  }

  Future<void> setAutoDeleteUploads(bool value) async {
    _autoDeleteUploads = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoDeleteUploadsKey, value);
    notifyListeners();
  }

  Future<void> setSaveHistory(bool value) async {
    _saveHistory = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_saveHistoryKey, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setUploadSizeLimit(String value) async {
    _uploadSizeLimit = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uploadSizeLimitKey, value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep privacy policy acceptance and login status
    await prefs.remove(_imageQualityKey);
    await prefs.remove(_autoSaveResultsKey);
    await prefs.remove(_saveHistoryKey);
    await prefs.remove(_uploadSizeLimitKey);
    
    // Reset to defaults
    _imageQuality = 'medium';
    _autoSaveResults = false;
    _saveHistory = true;
    _uploadSizeLimit = '1024';
    
    notifyListeners();
  }
}


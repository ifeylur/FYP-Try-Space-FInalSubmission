import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:try_space/Providers/SettingsProvider.dart';
import 'package:try_space/Providers/UserProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:try_space/Utilities/Auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '1.0.0';
  final Auth _auth = Auth();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      debugPrint('Error loading app version: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = const [
      Color(0xFFFF5F6D),
      Color(0xFFFFC371),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Appearance Settings'),
                _buildDarkModeToggle(settingsProvider),
                _buildLanguageSelector(settingsProvider),
                _buildThemeColorPicker(settingsProvider),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Image Quality Settings'),
                _buildImageQualitySlider(settingsProvider),
                _buildAutoSaveToggle(settingsProvider),
                _buildUploadSizeLimit(settingsProvider),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Privacy Settings'),
                _buildAutoDeleteToggle(settingsProvider),
                _buildSaveHistoryToggle(settingsProvider),
                _buildClearDataButton(settingsProvider),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Notification Settings'),
                _buildProcessingNotificationsToggle(settingsProvider),
                _buildAppUpdatesToggle(settingsProvider),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Account Settings'),
                _buildEditProfileButton(),
                _buildChangePasswordButton(),
                _buildDeleteAccountButton(),
                
                const SizedBox(height: 24),
                _buildSectionHeader('About'),
                _buildAppVersion(_appVersion),
                _buildPrivacyPolicyLink(),
                _buildTermsOfServiceLink(),
                _buildContactSupportLink(),
                _buildRateAppButton(),
                
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(SettingsProvider provider) {
    return _buildSettingTile(
      title: 'Dark Mode',
      trailing: Switch(
        value: provider.darkMode,
        onChanged: (value) => provider.setDarkMode(value),
        activeColor: Colors.white,
      ),
    );
  }

  Widget _buildLanguageSelector(SettingsProvider provider) {
    return _buildSettingTile(
      title: 'Language',
      trailing: DropdownButton<String>(
        value: provider.language,
        dropdownColor: const Color(0xFFFF5F6D),
        style: const TextStyle(color: Colors.white),
        underline: Container(),
        items: const [
          DropdownMenuItem(value: 'en', child: Text('English')),
        ],
        onChanged: (value) {
          if (value != null) provider.setLanguage(value);
        },
      ),
    );
  }

  Widget _buildThemeColorPicker(SettingsProvider provider) {
    final colors = ['default', 'blue', 'green', 'purple', 'orange'];
    return _buildSettingTile(
      title: 'Theme Color',
      trailing: DropdownButton<String>(
        value: provider.themeColor,
        dropdownColor: const Color(0xFFFF5F6D),
        style: const TextStyle(color: Colors.white),
        underline: Container(),
        items: colors.map((color) {
          return DropdownMenuItem(
            value: color,
            child: Text(color[0].toUpperCase() + color.substring(1)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) provider.setThemeColor(value);
        },
      ),
    );
  }

  Widget _buildImageQualitySlider(SettingsProvider provider) {
    final qualityMap = {'low': 'Low', 'medium': 'Medium', 'high': 'High'};
    return _buildSettingTile(
      title: 'Image Quality: ${qualityMap[provider.imageQuality] ?? 'Medium'}',
      trailing: DropdownButton<String>(
        value: provider.imageQuality,
        dropdownColor: const Color(0xFFFF5F6D),
        style: const TextStyle(color: Colors.white),
        underline: Container(),
        items: qualityMap.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) provider.setImageQuality(value);
        },
      ),
    );
  }

  Widget _buildAutoSaveToggle(SettingsProvider provider) {
    return _buildSettingTile(
      title: 'Auto-save Results',
      trailing: Switch(
        value: provider.autoSaveResults,
        onChanged: (value) => provider.setAutoSaveResults(value),
        activeColor: Colors.white,
      ),
    );
  }

  Widget _buildUploadSizeLimit(SettingsProvider provider) {
    final sizeMap = {'512': '512px', '768': '768px', '1024': '1024px'};
    return _buildSettingTile(
      title: 'Upload Size Limit: ${sizeMap[provider.uploadSizeLimit] ?? '1024px'}',
      trailing: DropdownButton<String>(
        value: provider.uploadSizeLimit,
        dropdownColor: const Color(0xFFFF5F6D),
        style: const TextStyle(color: Colors.white),
        underline: Container(),
        items: sizeMap.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) provider.setUploadSizeLimit(value);
        },
      ),
    );
  }

  Widget _buildAutoDeleteToggle(SettingsProvider provider) {
    return _buildSettingTile(
      title: 'Auto-delete Uploaded Images',
      trailing: Switch(
        value: provider.autoDeleteUploads,
        onChanged: (value) => provider.setAutoDeleteUploads(value),
        activeColor: Colors.white,
      ),
    );
  }

  Widget _buildSaveHistoryToggle(SettingsProvider provider) {
    return _buildSettingTile(
      title: 'Save History',
      trailing: Switch(
        value: provider.saveHistory,
        onChanged: (value) => provider.setSaveHistory(value),
        activeColor: Colors.white,
      ),
    );
  }

  Widget _buildClearDataButton(SettingsProvider provider) {
    return _buildSettingTile(
      title: 'Clear All Data',
      trailing: const Icon(Icons.delete_outline, color: Colors.white),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear All Data'),
            content: const Text(
              'This will delete all cached images and history. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await provider.clearAllData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data cleared')),
                  );
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProcessingNotificationsToggle(SettingsProvider provider) {
    return _buildSettingTile(
      title: 'Processing Complete Notifications',
      trailing: Switch(
        value: provider.notificationsEnabled,
        onChanged: (value) => provider.setNotificationsEnabled(value),
        activeColor: Colors.white,
      ),
    );
  }

  Widget _buildAppUpdatesToggle(SettingsProvider provider) {
    return _buildSettingTile(
      title: 'App Updates Notifications',
      trailing: Switch(
        value: provider.notificationsEnabled,
        onChanged: (value) => provider.setNotificationsEnabled(value),
        activeColor: Colors.white,
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return _buildSettingTile(
      title: 'Edit Profile',
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
      onTap: () => Navigator.pushNamed(context, '/editprofile'),
    );
  }

  Widget _buildChangePasswordButton() {
    return _buildSettingTile(
      title: 'Change Password',
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
      onTap: () => Navigator.pushNamed(context, '/changepassword'),
    );
  }

  Widget _buildDeleteAccountButton() {
    return _buildSettingTile(
      title: 'Delete Account',
      trailing: const Icon(Icons.delete_outline, color: Colors.red),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delete account feature coming soon')),
                  );
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppVersion(String version) {
    return _buildSettingTile(
      title: 'App Version',
      trailing: Text(version, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildPrivacyPolicyLink() {
    return _buildSettingTile(
      title: 'Privacy Policy',
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy Policy page coming soon')),
        );
      },
    );
  }

  Widget _buildTermsOfServiceLink() {
    return _buildSettingTile(
      title: 'Terms of Service',
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terms of Service page coming soon')),
        );
      },
    );
  }

  Widget _buildContactSupportLink() {
    return _buildSettingTile(
      title: 'Contact Support',
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
      onTap: () async {
        final email = 'support@tryspace.app';
        final uri = Uri.parse('mailto:$email');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email: $email')),
          );
        }
      },
    );
  }

  Widget _buildRateAppButton() {
    return _buildSettingTile(
      title: 'Rate App',
      trailing: const Icon(Icons.star_outline, color: Colors.white),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rate app feature coming soon')),
        );
      },
    );
  }
}


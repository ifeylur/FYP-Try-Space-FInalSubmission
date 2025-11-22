import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:try_space/Providers/SettingsProvider.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing by back button
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Try-Space!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Before you begin, please review our Privacy Policy:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'What We Collect:',
                    [
                      'Images you upload for virtual try-on',
                      'Basic account information (email, name)',
                      'Usage analytics to improve our service',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'What We DON\'T Do:',
                    [
                      '✗ We never store your uploaded photos permanently',
                      '✗ We never share your images with third parties',
                      '✗ We never use your photos for training AI models',
                      '✗ We never sell your personal data',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Image Processing:',
                    [
                      'Images are processed securely on our servers',
                      'All uploaded images are automatically deleted after 24 hours',
                      'Processing happens in real-time and results are delivered instantly',
                      'You can delete your images immediately after processing',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Your Rights:',
                    [
                      'You can request data deletion at any time',
                      'You can export your data',
                      'You can delete your account completely',
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Open privacy policy link
                          launchUrl(Uri.parse('https://tryspace.app/privacy'));
                        },
                        child: const Text('View Full Privacy Policy'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Open terms of service link
                          launchUrl(Uri.parse('https://tryspace.app/terms'));
                        },
                        child: const Text('View Terms of Service'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'By continuing, you agree to our Privacy Policy and Terms of Service.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You must accept to use the app'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            // Close app or show login blocked
                            Future.delayed(const Duration(seconds: 2), () {
                              // You can exit the app here if needed
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final settingsProvider = Provider.of<SettingsProvider>(
                              context,
                              listen: false,
                            );
                            await settingsProvider.setPrivacyPolicyAccepted(true);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFFFF5F6D),
                          ),
                          child: const Text('Accept & Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                item,
                style: const TextStyle(fontSize: 14),
              ),
            )),
      ],
    );
  }
}


import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: April 2026',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection('1. Information We Collect', '''
Dhukuti is a financial investment management app. We collect the following information to provide our services:

• Account Information: Name, phone number, and email address provided during registration
• Transaction Data: Investment amounts, transaction history, and portfolio holdings
• Device Information: Device type, operating system, and app version for analytics
• Usage Data: How you interact with the app, features accessed, and crash reports
            '''),
            _buildSection('2. How We Use Your Information', '''
We use the collected information solely for the following purposes:

• To process and record your investment transactions
• To maintain and display your portfolio holdings and performance
• To send transaction notifications and account updates
• To improve app functionality and user experience
• To ensure compliance with applicable financial regulations
• To provide customer support
            '''),
            _buildSection('3. Data Storage and Security', '''
• All user data is stored securely in Firebase Cloud Firestore
• Authentication is handled by Firebase Authentication services
• Data is encrypted both in transit and at rest
• We implement industry-standard security measures to protect your information
• Access to user data is restricted to authorized personnel only
• Regular security audits are conducted to maintain data integrity
            '''),
            _buildSection('4. Third-Party Services', '''
Dhukuti uses the following third-party services:

• Firebase (Google): Backend services including Cloud Firestore for data storage and Firebase Authentication for user authentication

We do not share your personal or financial information with any third parties for marketing or advertising purposes. Firebase services collect anonymized usage data according to Google's privacy policy.
            '''),
            _buildSection("5. Children's Privacy", '''
Dhukuti is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we become aware that we have collected personal information from a child under 13 without verification of parental consent, we will take steps to delete that information promptly. If you are a parent or guardian and believe your child has provided us with personal information, please contact us at support@dhukuti.com.
            '''),
            _buildSection('6. Changes to This Policy', '''
We may update this Privacy Policy from time to time to reflect changes in our practices or legal requirements. Any changes will be posted on this page with an updated revision date. We encourage you to review this policy periodically. Continued use of the app after any changes constitutes acceptance of the updated policy.
            '''),
            _buildSection('7. Contact Us', '''
If you have any questions about this Privacy Policy or our data practices, please contact us at:

support@dhukuti.com
            '''),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google Play Store Compliance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildComplianceItem('No third-party data sharing'),
                  _buildComplianceItem("Children's privacy addressed"),
                  _buildComplianceItem('Local and cloud data storage with Firebase Firestore'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content.trim(),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
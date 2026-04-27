import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    final horizontalPadding = screenWidth * 0.04;
    final sectionSpacing = isSmallScreen ? 16.0 : 24.0;
    final titleSize = screenWidth < 350 ? 20.0 : 24.0;
    final sectionTitleSize = screenWidth < 350 ? 16.0 : 18.0;
    final bodySize = screenWidth < 350 ? 13.0 : 14.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: screenWidth * 0.15,
                    color: Colors.teal,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    'Last updated: April 2026',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: bodySize,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sectionSpacing),
            _buildSection(
              '1. Information We Collect',
              '''
Dhukuti is a financial investment management app. We collect the following information to provide our services:

• Account Information: Name, phone number, and email address provided during registration
• Transaction Data: Investment amounts, transaction history, and portfolio holdings
• Device Information: Device type, operating system, and app version for analytics
• Usage Data: How you interact with the app, features accessed, and crash reports
              ''',
              sectionTitleSize,
              bodySize,
            ),
            _buildSection(
              '2. How We Use Your Information',
              '''
We use the collected information solely for the following purposes:

• To process and record your investment transactions
• To maintain and display your portfolio holdings and performance
• To send transaction notifications and account updates
• To improve app functionality and user experience
• To ensure compliance with applicable financial regulations
• To provide customer support
              ''',
              sectionTitleSize,
              bodySize,
            ),
            _buildSection(
              '3. Data Storage and Security',
              '''
• All user data is stored securely in Firebase Cloud Firestore
• Authentication is handled by Firebase Authentication services
• Data is encrypted both in transit and at rest
• We implement industry-standard security measures to protect your information
• Access to user data is restricted to authorized personnel only
• Regular security audits are conducted to maintain data integrity
              ''',
              sectionTitleSize,
              bodySize,
            ),
            _buildSection(
              '4. Third-Party Services',
              '''
Dhukuti uses the following third-party services:

• Firebase (Google): Backend services including Cloud Firestore for data storage and Firebase Authentication for user authentication

We do not share your personal or financial information with any third parties for marketing or advertising purposes. Firebase services collect anonymized usage data according to Google's privacy policy.
              ''',
              sectionTitleSize,
              bodySize,
            ),
            _buildSection(
              "5. Children's Privacy",
              '''
Dhukuti is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we become aware that we have collected personal information from a child under 13 without verification of parental consent, we will take steps to delete that information promptly. If you are a parent or guardian and believe your child has provided us with personal information, please contact us at support@dhukuti.com.
              ''',
              sectionTitleSize,
              bodySize,
            ),
            _buildSection(
              '6. Changes to This Policy',
              '''
We may update this Privacy Policy from time to time to reflect changes in our practices or legal requirements. Any changes will be posted on this page with an updated revision date. We encourage you to review this policy periodically. Continued use of the app after any changes constitutes acceptance of the updated policy.
              ''',
              sectionTitleSize,
              bodySize,
            ),
            _buildSection(
              '7. Contact Us',
              '''
If you have any questions about this Privacy Policy or our data practices, please contact us at:

support@dhukuti.com
              ''',
              sectionTitleSize,
              bodySize,
            ),
            SizedBox(height: sectionSpacing),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Colors.green.shade700,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Google Play Store Compliance',
                        style: TextStyle(
                          fontSize: sectionTitleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  _buildComplianceItem(
                    'No third-party data sharing',
                    bodySize,
                  ),
                  _buildComplianceItem(
                    "Children's privacy addressed",
                    bodySize,
                  ),
                  _buildComplianceItem(
                    'Data stored in Firebase Cloud Firestore',
                    bodySize,
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, double titleSize, double bodySize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.trim(),
            style: TextStyle(fontSize: bodySize, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceItem(String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }
}
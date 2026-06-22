import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF374151),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                '1. Information We Collect',
                'We collect information you provide directly to us, including:\n'
                    '- Name and email address (required for account creation)\n'
                    '- Profile photo (optional)\n'
                    '- Location data (country, province, city)\n'
                    '- Professional information (for photographer accounts)\n'
                    '- Portfolio photos and content you upload\n'
                    '- Messages and communications with other users\n'
                    '- Booking information and transaction history\n\n'
                    'We do NOT collect your interactions with the app for advertising purposes without your explicit consent. We do not sell your personal data to third parties.',
              ),
              _buildSection(
                '2. How We Use Your Information',
                'We use your information to:\n'
                    '- Provide, maintain, and improve the App\n'
                    '- Enable connections between clients and photographers\n'
                    '- Process bookings and payments\n'
                    '- Send service-related notifications\n'
                    '- Ensure platform safety and enforce our Terms of Service\n'
                    '- Respond to your inquiries and support requests',
              ),
              _buildSection(
                '3. Data Sharing',
                'We may share your information:\n'
                    '- With other users as necessary for the App\'s functionality (e.g., sharing your profile with potential clients)\n'
                    '- With service providers who assist in operating the App (e.g., Firebase cloud services)\n'
                    '- When required by law or to protect rights and safety\n\n'
                    'We do NOT share your data with advertisers or data brokers.',
              ),
              _buildSection(
                '4. Email Privacy',
                'Your email address is used solely for account authentication and service-related communications. We do not share your email address with other users or third parties. Other users on the platform will not see your email address.',
              ),
              _buildSection(
                '5. Data Collection for Advertising',
                'We do not collect interactions with the app for advertising purposes without your explicit consent. The App does not currently serve targeted advertisements based on user behavior. Any future advertising features will be opt-in only.',
              ),
              _buildSection(
                '6. Data Security',
                'We implement appropriate security measures to protect your personal information. Your data is stored securely using Firebase services with industry-standard encryption. However, no method of electronic storage is 100% secure.',
              ),
              _buildSection(
                '7. Data Retention',
                'We retain your information for as long as your account is active or as needed to provide you services. You may request deletion of your account and associated data at any time through the App\'s account deletion feature.',
              ),
              _buildSection(
                '8. Your Rights',
                'You have the right to:\n'
                    '- Access your personal data\n'
                    '- Correct inaccurate data\n'
                    '- Delete your account and data\n'
                    '- Opt out of non-essential communications\n'
                    '- Request a copy of your data',
              ),
              _buildSection(
                '9. Children\'s Privacy',
                'The App is not intended for use by children under 13. We do not knowingly collect personal information from children under 13.',
              ),
              _buildSection(
                '10. Changes to Privacy Policy',
                'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
              ),
              _buildSection(
                '11. Contact Us',
                'If you have questions about this Privacy Policy, please contact us through the App Store review process or the support channels provided within the App.',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFFC62828),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Last Updated: June 2026',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

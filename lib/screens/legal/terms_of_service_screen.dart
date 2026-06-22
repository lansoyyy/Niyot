import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen>
    with SingleTickerProviderStateMixin {
  bool _accepted = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B0000), Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Terms of Service',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please review and accept to continue',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        '1. Acceptance of Terms',
                        'By accessing or using the Niyot platform ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App. These terms apply to all users, including photographers, videographers, clients, and businesses.',
                      ),
                      _buildSection(
                        '2. User-Generated Content',
                        'Users may post content including but not limited to profiles, portfolios, reviews, messages, and photos. You retain ownership of your content but grant Niyot a non-exclusive, worldwide license to display and distribute it within the App.\n\nYou are solely responsible for the content you post. You agree not to post content that is:\n- Illegal, harmful, threatening, abusive, harassing, or defamatory\n- Sexually explicit or pornographic\n- Discriminatory based on race, religion, gender, sexual orientation, or disability\n- Infringing on intellectual property rights\n- Spam, scam, or misleading',
                      ),
                      _buildSection(
                        '3. Content Moderation',
                        'Niyot provides users with tools to report objectionable content and block abusive users. We reserve the right to review reported content and take appropriate action, including content removal, account suspension, or permanent termination.\n\nUsers may flag objectionable content through the in-app reporting feature. Users may block other users, which will immediately remove that user\'s content from the blocking user\'s feed and prevent further interaction.',
                      ),
                      _buildSection(
                        '4. Blocking & Reporting',
                        'If you block a user:\n- Their content will be immediately removed from your feed\n- They will not be able to message you\n- Their profile will not appear in your search results\n- The block will be reported to our moderation team for review\n\nIf you report content or a user, our team will review the report and take appropriate action within a reasonable timeframe.',
                      ),
                      _buildSection(
                        '5. User Conduct',
                        'Users must:\n- Provide accurate and truthful information\n- Respect the rights and privacy of other users\n- Not engage in harassment, stalking, or abusive behavior\n- Not use the App for any illegal purpose\n- Not attempt to circumvent any security features\n- Not impersonate other individuals or entities',
                      ),
                      _buildSection(
                        '6. Account Termination',
                        'Niyot reserves the right to suspend or terminate accounts that violate these terms or engage in behavior deemed harmful to the community. Users may delete their account at any time through the app settings.',
                      ),
                      _buildSection(
                        '7. Disclaimer of Warranties',
                        'The App is provided "as is" without warranties of any kind, either express or implied. Niyot does not guarantee the quality, safety, or legality of services provided by photographers or any content posted by users.',
                      ),
                      _buildSection(
                        '8. Limitation of Liability',
                        'Niyot shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App or interactions with other users.',
                      ),
                      _buildSection(
                        '9. Changes to Terms',
                        'We reserve the right to modify these terms at any time. Continued use of the App after changes constitutes acceptance of the new terms. Users will be notified of material changes.',
                      ),
                      _buildSection(
                        '10. Contact',
                        'For questions about these Terms, please contact us through the App Store review process or the support channels provided within the App.',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _accepted,
                            onChanged: (v) =>
                                setState(() => _accepted = v ?? false),
                            activeColor: const Color(0xFFC62828),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _accepted = !_accepted),
                            child: Text(
                              'I have read and agree to the Terms of Service and Privacy Policy.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF374151),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _accepted
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE0E0E0),
                          disabledForegroundColor: const Color(0xFF9E9E9E),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Accept & Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

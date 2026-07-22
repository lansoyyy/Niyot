import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/philippines_locations.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/app_profile_avatar.dart';
import '../../widgets/common/service_offer_selector.dart';
import '../../widgets/location/ph_location_dropdowns.dart';
import '../main/main_screen.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/privacy_policy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.popOnSuccess = false});

  /// When true, pops with `true` after register instead of replacing with MainScreen.
  final bool popOnSuccess;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _socialUrlController = TextEditingController();
  final _videoReelUrlController = TextEditingController();
  final _authService = AuthService();
  String _country = PhilippinesLocations.countryName;
  String _province = '';
  String _city = '';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  int _selectedRole = 0; // 0 = Photographer/Videographer, 1 = Client
  /// 0 = account form, 1 = service offers (photographers only).
  int _step = 0;
  final Set<String> _selectedOffers = {};
  File? _profileImage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _socialUrlController.dispose();
    _videoReelUrlController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFB71C1C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _validateAccountForm() {
    if (!_formKey.currentState!.validate()) return false;
    if (_province.isEmpty || _city.isEmpty) {
      _showError('Please select province and city.');
      return false;
    }
    if (!_acceptedTerms) {
      _showError('Please accept the Terms of Service and Privacy Policy.');
      return false;
    }
    return true;
  }

  void _onPrimaryPressed() {
    if (_isLoading) return;

    // Clients finish on step 0. Photographers continue to offers step.
    if (_step == 0 && _selectedRole == 0) {
      if (!_validateAccountForm()) return;
      FocusScope.of(context).unfocus();
      setState(() => _step = 1);
      return;
    }

    if (_step == 1 && _selectedOffers.isEmpty) {
      _showError('Please select at least one service you offer.');
      return;
    }

    if (_step == 0 && !_validateAccountForm()) return;

    _register();
  }

  void _register() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    try {
      await _authService.registerWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        role: _selectedRole == 0 ? 'photographer' : 'client',
        profileImage: _profileImage,
        country: _country.trim(),
        city: _city.trim(),
        province: _province.trim(),
        serviceTypes:
            _selectedRole == 0 ? _selectedOffers.toList() : const [],
        socialUrl: _selectedRole == 0
            ? _socialUrlController.text.trim()
            : '',
        videoReelUrl: _selectedRole == 0
            ? _videoReelUrlController.text.trim()
            : '',
      );
      if (mounted) {
        if (widget.popOnSuccess) {
          Navigator.of(context).pop(true);
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScreen(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      _showError(AuthService.parseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onBack() {
    if (_step == 1) {
      setState(() => _step = 0);
      return;
    }
    Navigator.of(context).pop();
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
          onPressed: _onBack,
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
            child: Form(
              key: _formKey,
              child: _step == 0
                  ? _buildAccountStep()
                  : _buildOffersStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffersStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you offer?',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select all that apply.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF7A7A7A),
          ),
        ),
        const SizedBox(height: 28),
        ServiceOfferSelector(
          selected: _selectedOffers,
          onChanged: (next) => setState(() {
            _selectedOffers
              ..clear()
              ..addAll(next);
          }),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(label: 'Create Account'),
      ],
    );
  }

  Widget _buildAccountStep() {
    final isPhotographer = _selectedRole == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Join thousands of creatives on Niyot',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF7A7A7A),
          ),
        ),
        const SizedBox(height: 28),
        // Profile image picker
        Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          SizedBox(
                            width: 96,
                            height: 96,
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                      width: 96,
                                      height: 96,
                                    )
                                  : AppProfileAvatar(
                                      displayName: _nameController.text,
                                      size: 96,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC62828),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Tap to add profile photo (optional)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Role selector
                  Text(
                    'I am a...',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.camera_alt_rounded,
                          label: 'Photographer /\nVideographer',
                          isSelected: _selectedRole == 0,
                          onTap: () => setState(() => _selectedRole = 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.person_search_rounded,
                          label: 'Client /\nBusiness',
                          isSelected: _selectedRole == 1,
                          onTap: () => setState(() {
                            _selectedRole = 1;
                            _selectedOffers.clear();
                          }),
                        ),
                      ),
                    ],
                ),
                  const SizedBox(height: 24),
                  _buildLabel('Full Name'),
                  const SizedBox(height: 8),
                  _buildFormField(
                    controller: _nameController,
                    hint: 'John Doe',
                    icon: Icons.person_outline_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required';
                      if (v.trim().length < 2) return 'Name is too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('Email Address'),
                  const SizedBox(height: 8),
                  _buildFormField(
                    controller: _emailController,
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      final re = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!re.hasMatch(v.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  _buildFormField(
                    controller: _passwordController,
                    hint: 'Min. 8 characters',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF9E9E9E),
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('Confirm Password'),
                  const SizedBox(height: 8),
                  _buildFormField(
                    controller: _confirmPasswordController,
                    hint: 'Re-enter your password',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF9E9E9E),
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm your password';
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  PhLocationDropdowns(
                    country: _country,
                    province: _province,
                    city: _city,
                    onCountryChanged: (c) => setState(() => _country = c),
                    onProvinceChanged: (p) => setState(() {
                      _province = p;
                      _city = '';
                    }),
                    onCityChanged: (c) => setState(() => _city = c),
                  ),
                  if (isPhotographer) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Your Links (optional)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFormField(
                      controller: _socialUrlController,
                      hint: 'Your social link (Instagram or Facebook)',
                      icon: Icons.radio_button_checked,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    _buildFormField(
                      controller: _videoReelUrlController,
                      hint: 'Your video link (YouTube or Vimeo)',
                      icon: Icons.videocam_outlined,
                      keyboardType: TextInputType.url,
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Terms
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _acceptedTerms,
                          onChanged: (v) =>
                              setState(() => _acceptedTerms = v ?? false),
                        activeColor: const Color(0xFFC62828),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                     const SizedBox(width: 10),
                     Expanded(
                       child: RichText(
                         text: TextSpan(
                           style: GoogleFonts.poppins(
                             fontSize: 13,
                             color: const Color(0xFF7A7A7A),
                           ),
                           children: [
                             const TextSpan(text: 'I agree to the '),
                             TextSpan(
                               text: 'Terms of Service',
                               style: GoogleFonts.poppins(
                                 fontSize: 13,
                                 fontWeight: FontWeight.w600,
                                 color: const Color(0xFFC62828),
                               ),
                               recognizer: TapGestureRecognizer()
                                 ..onTap = () {
                                   Navigator.of(context).push(
                                     MaterialPageRoute(
                                       builder: (_) =>
                                           const TermsOfServiceScreen(),
                                     ),
                                   );
                                 },
                             ),
                             const TextSpan(text: ' and '),
                             TextSpan(
                               text: 'Privacy Policy',
                               style: GoogleFonts.poppins(
                                 fontSize: 13,
                                 fontWeight: FontWeight.w600,
                                 color: const Color(0xFFC62828),
                               ),
                               recognizer: TapGestureRecognizer()
                                 ..onTap = () {
                                   Navigator.of(context).push(
                                     MaterialPageRoute(
                                       builder: (_) =>
                                           const PrivacyPolicyScreen(),
                                     ),
                                   );
                                 },
                             ),
                           ],
                         ),
                       ),
                     ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildPrimaryButton(
                  label: isPhotographer ? 'Continue' : 'Create Account',
                ),
                const SizedBox(height: 24),
                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF7A7A7A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
  }

  Widget _buildPrimaryButton({required String label}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onPrimaryPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style:
            GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1F2937)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFFBDBDBD),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          errorStyle: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFFB71C1C),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFEBEE)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC62828)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFC62828)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFFC62828)
                    : const Color(0xFF7A7A7A),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/philippines_locations.dart';
import '../../models/photographer_model.dart';
import '../../models/user_model.dart';
import '../../services/messaging_service.dart';
import '../../services/photographer_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common/app_profile_avatar.dart';
import '../../widgets/location/ph_location_dropdowns.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();
  String _country = PhilippinesLocations.countryName;
  String _province = '';
  String _city = '';

  final _specialtyOptions = const [
    'Portrait',
    'Wedding',
    'Event',
    'Commercial',
    'Fashion',
    'Travel',
    'Newborn',
    'Product',
  ];

  final Set<String> _selectedSpecialties = {};

  UserModel? _user;
  PhotographerModel? _photographer;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _parseLocationString(String? raw) {
    _country = PhilippinesLocations.countryName;
    _province = '';
    _city = '';
    if (raw == null || raw.trim().isEmpty) return;
    final parts = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 3) {
      _city = parts[0];
      _province = parts[1];
      final c0 = parts[2];
      if (PhilippinesLocations.countries.contains(c0)) {
        _country = c0;
      }
    } else if (parts.length == 2) {
      _city = parts[0];
      _province = parts[1];
    } else {
      _city = parts[0];
    }
    if (_province.isNotEmpty &&
        !PhilippinesLocations.provinces.contains(_province)) {
      _province = 'Other / Not listed';
      _city = 'Other';
    }
    final cities = PhilippinesLocations.citiesForProvince(_province);
    if (_province.isNotEmpty &&
        _city.isNotEmpty &&
        cities.isNotEmpty &&
        !cities.contains(_city)) {
      _city = cities.first;
    }
  }

  Future<void> _loadProfile() async {
    final user = await UserService().fetchCurrentUser();
    PhotographerModel? photographer;
    if (user?.isPhotographer == true) {
      photographer = await PhotographerService().getPhotographerById(user!.uid);
    }

    if (!mounted) return;

    _user = user;
    _photographer = photographer;
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _bioController.text = photographer?.bio ?? user?.bio ?? '';
    _parseLocationString(photographer?.locationText ?? user?.location);
    _selectedSpecialties
      ..clear()
      ..addAll(photographer?.specialties ?? const <String>[]);

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _removePhoto() async {
    setState(() => _selectedImage = null);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _user == null) return;
    if (_province.isEmpty || _city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select province and city.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? photoUrl = _user!.photoUrl;
      if (_selectedImage != null) {
        photoUrl = await UserService().uploadProfilePhoto(
          _currentUid,
          _selectedImage!,
        );
      }

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final bio = _bioController.text.trim();
      final location = PhilippinesLocations.composeLocation(
        city: _city,
        province: _province,
        country: _country,
      );

      await UserService().updateProfile(
        uid: _currentUid,
        fields: {
          'name': name,
          'phone': phone.isEmpty ? null : phone,
          'bio': bio.isEmpty ? null : bio,
          'location': location.isEmpty ? null : location,
          'photoUrl': photoUrl,
          'isProfileComplete': true,
        },
      );

      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      if (photoUrl != null) {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(photoUrl);
      }

      if (_user!.isPhotographer && _photographer != null) {
        final specialties = _selectedSpecialties.toList();
        await PhotographerService().createOrUpdatePhotographerProfile(
          _photographer!.copyWith(
            name: name,
            photoUrl: photoUrl,
            bio: bio,
            locationText: location,
            specialties: specialties,
            primarySpecialty: specialties.isNotEmpty
                ? specialties.first
                : _photographer!.primarySpecialty,
          ),
        );
      }

      await MessagingService().syncParticipantPhotoForUser(_currentUid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: $error',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Profile Photo',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 20),
            _ImagePickerOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo',
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _ImagePickerOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if ((_user?.photoUrl?.isNotEmpty ?? false) ||
                _selectedImage != null) ...[
              const SizedBox(height: 12),
              _ImagePickerOption(
                icon: Icons.delete_rounded,
                label: 'Remove Selected Photo',
                onTap: () {
                  Navigator.of(context).pop();
                  _removePhoto();
                },
                color: const Color(0xFFE53935),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC62828)),
        ),
      );
    }

    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white),
        body: Center(
          child: Text(
            'Unable to load profile',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC62828),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: _selectedImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                                )
                              : AppProfileAvatar(
                                  displayName: user.name,
                                  photoUrl: user.photoUrl,
                                  size: 100,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImagePickerDialog,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC62828),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change photo',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      user.isPhotographer
                          ? Icons.camera_alt_rounded
                          : Icons.person_rounded,
                      color: const Color(0xFFC62828),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      user.isPhotographer
                          ? 'Photographer Account'
                          : 'Client Account',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLabel('Email Address'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'Email address',
                icon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 20),
              _buildLabel('Phone Number'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _phoneController,
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              PhLocationDropdowns(
                country: _country,
                province: _province,
                city: _city,
                dense: true,
                onCountryChanged: (c) => setState(() => _country = c),
                onProvinceChanged: (p) => setState(() {
                  _province = p;
                  final cities = PhilippinesLocations.citiesForProvince(p);
                  _city = cities.isNotEmpty ? cities.first : '';
                }),
                onCityChanged: (c) => setState(() => _city = c),
              ),
              const SizedBox(height: 20),
              _buildLabel('Bio'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF1A1A1A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tell clients about yourself...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFFBDBDBD),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              if (user.isPhotographer) ...[
                const SizedBox(height: 20),
                _buildLabel('Specialties'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _specialtyOptions
                      .map(
                        (specialty) => _SpecialtyChip(
                          label: specialty,
                          selected: _selectedSpecialties.contains(specialty),
                          onTap: () {
                            setState(() {
                              if (_selectedSpecialties.contains(specialty)) {
                                _selectedSpecialties.remove(specialty);
                              } else {
                                _selectedSpecialties.add(specialty);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFFBDBDBD),
        ),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFFBDBDBD)),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF3F4F6) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC62828), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEBEE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFC62828) : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 14,
                color: Color(0xFFC62828),
              ),
            if (selected) const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFFC62828)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerOption extends StatelessWidget {
  const _ImagePickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color?.withValues(alpha: 0.1) ?? const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFF374151), size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

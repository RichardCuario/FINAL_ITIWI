import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'identity_upload_service.dart';

class IdentityVerificationPage extends StatefulWidget {
  final VoidCallback? onBack;

  const IdentityVerificationPage({super.key, this.onBack});

  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _uploadService = IdentityUploadService();
  final _imagePicker = ImagePicker();

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  // Form fields
  final _fullNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  String _selectedIdType = 'national_id';
  Map<String, dynamic>? _verificationData;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showForm = false; // Track whether to show form or welcome screen

  // Image fields
  File? _idFrontImage;
  File? _idBackImage;
  File? _selfieImage;
  bool _isUploadingPhotos = false;

  bool _isNetworkError(Object error) {
    return error is SocketException ||
        error is HttpException ||
        error is HandshakeException ||
        error is TimeoutException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup');
  }

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadVerificationStatus() async {
    if (_currentUser == null) return;

    try {
      setState(() => _isLoading = true);
      final response = await _supabase
          .from('identity_verification')
          .select()
          .eq('user_id', _currentUser!.uid)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _verificationData = response;
          if (response != null) {
            _fullNameController.text = response['full_name'] ?? '';
            _idNumberController.text = response['id_number'] ?? '';
            _selectedIdType = response['id_type'] ?? 'national_id';
            if (response['date_of_birth'] != null) {
              _selectedDateOfBirth =
                  DateTime.parse(response['date_of_birth']);
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading verification status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isNetworkError(e)
                  ? 'No Internet Connection'
                  : 'Error loading verification: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _currentUser!;
      final displayName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email?.trim().isNotEmpty == true
              ? user.email!.trim()
              : 'User');

      try {
        await _supabase.from('users').upsert({
          'id': user.uid,
          'email': user.email ?? '',
          'display_name': displayName,
          'photo_url': user.photoURL,
        }, onConflict: 'id');
      } catch (e) {
        debugPrint('User sync warning (non-blocking): $e');
      }

      String? verificationId;

      if (_verificationData != null) {
        // Update existing verification
        await _supabase
            .from('identity_verification')
            .update({
              'full_name': _fullNameController.text.trim(),
              'id_type': _selectedIdType,
              'id_number': _idNumberController.text.trim(),
              'date_of_birth': DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
              'verification_status': 'pending',
              'rejection_reason': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.uid);
        verificationId = _verificationData!['id'];
      } else {
        // Create new verification
        final response = await _supabase
            .from('identity_verification')
            .insert({
              'user_id': user.uid,
              'full_name': _fullNameController.text.trim(),
              'id_type': _selectedIdType,
              'id_number': _idNumberController.text.trim(),
              'date_of_birth': DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
              'verification_status': 'pending',
            })
            .select()
            .single();
        verificationId = response['id'];
      }

      // Upload photos if provided
      if (_idFrontImage != null || _idBackImage != null || _selfieImage != null) {
        if (verificationId != null) {
          setState(() => _isUploadingPhotos = true);

          String? idFrontPhotoUrl;
          String? idBackPhotoUrl;
          String? selfiePhotoUrl;

          try {
            if (_idFrontImage != null) {
              idFrontPhotoUrl = await _uploadService.uploadIdFrontPhoto(
                imageFile: _idFrontImage!,
              );
            }

            if (_idBackImage != null) {
              idBackPhotoUrl = await _uploadService.uploadIdBackPhoto(
                imageFile: _idBackImage!,
              );
            }

            if (_selfieImage != null) {
              selfiePhotoUrl = await _uploadService.uploadSelfiePhoto(
                imageFile: _selfieImage!,
              );
            }

            // Update verification with photo URLs
            if (idFrontPhotoUrl != null ||
                idBackPhotoUrl != null ||
                selfiePhotoUrl != null) {
              await _uploadService.updateVerificationWithPhotos(
                verificationId: verificationId,
                idFrontPhotoUrl: idFrontPhotoUrl,
                idBackPhotoUrl: idBackPhotoUrl,
                selfiePhotoUrl: selfiePhotoUrl,
              );
            }
          } catch (e) {
            debugPrint('Error uploading photos: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isNetworkError(e)
                        ? 'No Internet Connection'
                        : 'Warning: Photo upload failed: $e',
                  ),
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isUploadingPhotos = false);
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification submitted! Your identity will be verified shortly.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _loadVerificationStatus();
      }
    } catch (e) {
      debugPrint('Error submitting verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isNetworkError(e)
                  ? 'No Internet Connection'
                  : 'Error submitting verification: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingPhotos = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source, String photoType) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          if (photoType == 'front') {
            _idFrontImage = File(pickedFile.path);
          } else if (photoType == 'back') {
            _idBackImage = File(pickedFile.path);
          } else if (photoType == 'selfie') {
            _selfieImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog(String photoType, String photoLabel) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload $photoLabel',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1a1a1a),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose where to get the photo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera, photoType);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFF1976D2),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Take Photo',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1a1a1a),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Use your camera',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery, photoType);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.image_rounded,
                                color: Color(0xFF0D47A1),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose from Gallery',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1a1a1a),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Select from your files',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _getIdTypeLabel(String idType) {
    switch (idType) {
      case 'national_id':
        return 'National ID';
      case 'driver_license':
        return 'Driver\'s License';
      case 'passport':
        return 'Passport';
      case 'voter_id':
        return 'Voter ID';
      default:
        return idType;
    }
  }

  Color _getStatusColorValue(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFE53935);
      case 'pending':
        return const Color(0xFFFFA726);
      default:
        return Colors.grey;
    }
  }

  Widget _buildPhotoUploadWidget(
    String label,
    File? imageFile,
    String photoType,
    IconData? icon,
  ) {
    final displayIcon = photoType == 'selfie' ? Icons.photo_camera_outlined : (icon ?? Icons.image_outlined);
    final isUploaded = imageFile != null;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isUploaded ? const Color(0xFF4CAF50) : Colors.grey.shade200,
          width: isUploaded ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isUploaded ? const Color(0xFFF1F8E9) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isUploaded 
              ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showImageSourceDialog(photoType, label),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageFile == null)
                Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1976D2),
                            Color(0xFF0D47A1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        displayIcon,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to upload',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4CAF50),
                            Color(0xFF388E3C),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Uploaded',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      imageFile.path.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _showForm ? false : true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showForm) {
          setState(() => _showForm = false);
        } else if (widget.onBack != null) {
          widget.onBack!();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFC),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [
                    Color(0xFF4FA9F5),
                    Color(0xFF7CBDF6),
                    Color(0xFFF3F4F6),
                  ],
                  stops: const [0.0, 0.62, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_showForm) {
                          setState(() => _showForm = false);
                        } else if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _showForm ? 'Complete Verification' : 'Identity Verification',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                      ),
                    )
                  : !_showForm
                      ? _buildWelcomeScreen()
                      : _buildFormScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAFBFC),
            Color(0xFFF0F4F9),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              const SizedBox(height: 4),
              
              // Hero Icon with Animated Gradient
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2196F3).withValues(alpha: 0.12),
                      const Color(0xFF1976D2).withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1976D2),
                          Color(0xFF0D47A1),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 14),
              
              // Main Title
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1976D2),
                    const Color(0xFF0D47A1),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Verify Your Identity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              Text(
                'Quick, secure, and trusted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Description
              Text(
                'Submit your details to access online services and reports.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.2,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.fact_check_rounded,
                      title: 'Manual',
                      description: 'Staff review',
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.shield_rounded,
                      title: 'Protected',
                      description: 'Handled securely',
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.verified_rounded,
                      title: 'Reviewed',
                      description: 'By our team',
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Security Info Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.06),
                  border: Border.all(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF1976D2),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your information is protected',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D47A1),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Your details are handled securely and used only for verification.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              height: 1.25,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // CTA Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1976D2),
                      Color(0xFF0D47A1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _showForm = true);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Start Verification',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Compliance Text
              Text(
                'Your privacy is our priority',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              
              const SizedBox(height: 2),
              ],
              ),
            ),
          ),
        ),
      ),
      );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1a1a1a),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAFBFC),
            Color(0xFFF0F4F9),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card - Enhanced
            if (_verificationData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColorValue(_verificationData!['verification_status']),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColorValue(_verificationData!['verification_status']).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _verificationData!['verification_status'] == 'verified'
                                ? Icons.check_circle_rounded
                                : _verificationData!['verification_status'] == 'pending'
                                    ? Icons.schedule_rounded
                                    : Icons.cancel_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verification Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _verificationData!['verification_status'].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_verificationData!['verification_status'] == 'rejected' &&
                        _verificationData!['rejection_reason'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reason: ${_verificationData!['rejection_reason']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Info Message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.07),
                border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_rounded,
                      color: Color(0xFF1976D2),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accurate information required',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1976D2),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Your identity will be verified by our admin team.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _fullNameController,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1a1a1a),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE53935),
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE53935),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF2196F3),
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date of Birth
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateOfBirth ?? DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF1976D2),
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() => _selectedDateOfBirth = pickedDate);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateOfBirth != null
                                ? DateFormat('MMM dd, yyyy').format(_selectedDateOfBirth!)
                                : 'Select date',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _selectedDateOfBirth != null
                                  ? Colors.black
                                  : Colors.grey.shade400,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey.shade500,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ID Type
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'ID Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedIdType,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF2196F3),
                        size: 20,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'national_id',
                        child: Text(_getIdTypeLabel('national_id')),
                      ),
                      DropdownMenuItem(
                        value: 'driver_license',
                        child: Text(_getIdTypeLabel('driver_license')),
                      ),
                      DropdownMenuItem(
                        value: 'passport',
                        child: Text(_getIdTypeLabel('passport')),
                      ),
                      DropdownMenuItem(
                        value: 'voter_id',
                        child: Text(_getIdTypeLabel('voter_id')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedIdType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // ID Number
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'ID Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _idNumberController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1a1a1a),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z\-]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter your ID number',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE53935),
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE53935),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.credit_card_outlined,
                        color: Color(0xFF2196F3),
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ID number is required';
                      }
                      if (value.trim().length < 5) {
                        return 'ID number must be at least 5 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Photo Uploads Section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'ID Document Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.07),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Color(0xFF1976D2),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Clear photos required',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1976D2),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Upload ID front, back, and a selfie for verification.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Photo Uploads Grid Layout
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.68,
                    children: [
                      _buildPhotoUploadWidget(
                        'ID Front Photo',
                        _idFrontImage,
                        'front',
                        Icons.image_outlined,
                      ),
                      _buildPhotoUploadWidget(
                        'ID Back Photo',
                        _idBackImage,
                        'back',
                        Icons.image_outlined,
                      ),
                      _buildPhotoUploadWidget(
                        'Selfie Photo',
                        _selfieImage,
                        'selfie',
                        Icons.photo_camera_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1976D2),
                          Color(0xFF0D47A1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSubmitting || _isUploadingPhotos
                            ? null
                            : _submitVerification,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            ),
                            child: _isSubmitting || _isUploadingPhotos
                                ? const SizedBox(
                                    key: ValueKey('submit-loading'),
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Center(
                                    key: ValueKey('submit-label'),
                                    child: Text(
                                      'Submit Verification',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

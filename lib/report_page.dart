import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_rate_limiter.dart';
import 'my_reports_page.dart';
import 'shared_widgets.dart';

class ReportPage extends StatefulWidget {
  final VoidCallback? onBack;

  const ReportPage({super.key, this.onBack});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  firebase_auth.User? get _currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      if (_selectedImages.length >= 5) {
        _showSnackBar('You can upload up to 5 images only.');
        return;
      }

      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1800,
      );

      if (image == null) return;

      setState(() {
        _selectedImages.add(image);
      });
    } catch (e) {
      _showSnackBar('Unable to pick image: $e');
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages(String reportId) async {
    final imageUrls = <String>[];

    for (var index = 0; index < _selectedImages.length; index++) {
      final image = _selectedImages[index];
      final bytes = await image.readAsBytes();
      final extension = image.path.split('.').last.toLowerCase();
      final safeExtension = extension.isEmpty ? 'jpg' : extension;
      final path =
          'public/${_currentUser?.uid ?? 'anonymous'}/$reportId-${index + 1}.$safeExtension';

      await _supabase.storage.from('report-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _contentTypeForExtension(safeExtension),
              upsert: false,
            ),
          );

      imageUrls.add(_supabase.storage.from('report-images').getPublicUrl(path));
    }

    return imageUrls;
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentUser == null) {
      _showSnackBar('Please sign in before submitting a report.');
      return;
    }

    const actionKey = 'report_submit';
    final rateLimitResult = await AppRateLimiter.checkAndLock(
      actionKey: actionKey,
      cooldown: const Duration(seconds: 30),
      message: 'Please wait 30 seconds before submitting another report.',
    );

    if (!rateLimitResult.allowed) {
      _showSnackBar(
        rateLimitResult.message ?? 'Please wait before submitting again.',
      );
      return;
    }

    if (!mounted) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final inserted = await _supabase
          .from('reports')
          .insert({
            'user_id': _currentUser!.uid,
            'message': _messageController.text.trim(),
            'status': 'pending',
          })
          .select('id')
          .single();

      final reportId = inserted['id'].toString();
      final imageUrls = await _uploadImages(reportId);

      if (imageUrls.isNotEmpty) {
        await _supabase.from('reports').update({
          'image_urls': imageUrls,
        }).eq('id', reportId);
      }

      // Upsert user info in users table to ensure display_name is available
      final displayName = (_currentUser!.displayName != null && _currentUser!.displayName!.isNotEmpty)
          ? _currentUser!.displayName
          : (_currentUser!.email ?? 'User');

      await _supabase.from('users').upsert({
        'id': _currentUser!.uid,
        'email': _currentUser!.email ?? '',
        'display_name': displayName,
        'photo_url': _currentUser!.photoURL,
      }, onConflict: 'id');

      if (!mounted) return;

      _messageController.clear();
      setState(() {
        _selectedImages.clear();
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showSnackBar('Unable to submit report: $e');
    } finally {
      await AppRateLimiter.release(actionKey);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBackground =
        isDark ? const Color(0xFF0B1220) : const Color(0xFFEAEAEA);
    final surfaceColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFF7F7F7);
    final secondarySurface =
        isDark ? const Color(0xFF243145) : const Color(0xFFE5E5E5);
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFD6DCE5);
    final topGradient = isDark
        ? const [
            Color(0xFF0F172A),
            Color(0xFF172554),
            Color(0xFF111827),
          ]
        : const [
            Color(0xFF1E88E5),
            Color(0xFF90CAF9),
            Color(0xFFEAEAEA),
          ];

    return Scaffold(
      backgroundColor: scaffoldBackground,
      body: Stack(
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topGradient,
                stops: const [0.0, 0.58, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 18, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed:
                            widget.onBack ?? () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Expanded(
                        child: Text(
                          'Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      children: [
                        _buildHeroCard(
                          context: context,
                          surfaceColor: surfaceColor,
                          secondarySurface: secondarySurface,
                          titleColor: titleColor,
                          subtitleColor: subtitleColor,
                        ),
                        const SizedBox(height: 16),
                        _buildMyReportsShortcut(
                          context: context,
                          surfaceColor: surfaceColor,
                          secondarySurface: secondarySurface,
                          titleColor: titleColor,
                          subtitleColor: subtitleColor,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 16),
                        _buildComposerCard(
                          context: context,
                          surfaceColor: surfaceColor,
                          secondarySurface: secondarySurface,
                          titleColor: titleColor,
                          subtitleColor: subtitleColor,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required BuildContext context,
    required Color surfaceColor,
    required Color secondarySurface,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: secondarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share a community concern',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Send complete details and optional photos so the municipality can review your concern faster. For life-threatening emergencies, use the Emergency Hotline feature.',
                  style: TextStyle(
                    fontSize: 12.8,
                    height: 1.45,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReportsShortcut({
    required BuildContext context,
    required Color surfaceColor,
    required Color secondarySurface,
    required Color titleColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: secondarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View my submitted reports',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your report status and latest updates in one place.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyReportsPage(
                    onBack: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Open',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerCard({
    required BuildContext context,
    required Color surfaceColor,
    required Color secondarySurface,
    required Color titleColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Include the exact location, what happened, and any details responders should know.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              maxLines: 7,
              minLines: 6,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your report message.';
                }
                if (value.trim().length < 10) {
                  return 'Please provide a little more detail.';
                }
                return null;
              },
              style: TextStyle(
                color: titleColor,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText:
                    'Example: There is a fallen electric post near Barangay Hall blocking the road...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13,
                ),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Photo attachments',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: secondarySurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_selectedImages.length}/5',
                    style: TextStyle(
                      color: subtitleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Attach clear images to help validate the report.',
              style: TextStyle(
                fontSize: 12.5,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _isSubmitting ? null : _pickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: secondarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload a photo',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose an image from your gallery',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: subtitleColor,
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final image = _selectedImages[index];
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              File(image.path),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _isSubmitting ? null : () => _removeImageAt(index),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.62),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Submitting report...' : 'Submit report',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_widgets.dart';
import 'app_rate_limiter.dart';
import 'shared_widgets.dart';

class AddNewsPage extends StatefulWidget {
  const AddNewsPage({super.key});

  @override
  _AddNewsPageState createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final supabase = Supabase.instance.client;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();
  bool isLoading = false;

  Future saveNews() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    const actionKey = 'news_create';
    final rateLimitResult = await AppRateLimiter.checkAndLock(
      actionKey: actionKey,
      cooldown: const Duration(seconds: 20),
      message: 'Please wait 20 seconds before publishing another article.',
    );

    if (!rateLimitResult.allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              rateLimitResult.message ??
                  'Please wait before publishing again.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.from('news').insert({
        'title': titleController.text,
        'description': descriptionController.text,
        'image_url': imageUrlController.text.isEmpty ? null : imageUrlController.text,
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Publish successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context, true); // Return to news page
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      await AppRateLimiter.release(actionKey);
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppHeader(
        title: 'Add New Article',
        onBackPressed: () => Navigator.pop(context),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AdminButton(
              label: isLoading ? 'Publishing...' : 'Publish',
              onPressed: isLoading ? () {} : saveNews,
              isLoading: isLoading,
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            AdminTextField(
              label: 'Title',
              hintText: 'Enter article title',
              controller: titleController,
              labelColor: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // Description Field
            AdminTextField(
              label: 'Description',
              hintText: 'Enter article description',
              controller: descriptionController,
              maxLines: 5,
              labelColor: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // Image URL Field
            AdminTextField(
              label: 'Image URL',
              hintText: 'Enter image URL',
              controller: imageUrlController,
              isRequired: false,
              labelColor: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // Image preview
            if (imageUrlController.text.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Image Preview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrlController.text,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }
}

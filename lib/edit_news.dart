import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shared_widgets.dart';
import 'admin_widgets.dart';

class EditNewsPage extends StatefulWidget {
  final String newsId;

  const EditNewsPage({required this.newsId});

  @override
  _EditNewsPageState createState() => _EditNewsPageState();
}

class _EditNewsPageState extends State<EditNewsPage> {
  final supabase = Supabase.instance.client;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();
  bool isLoading = false;
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    loadNewsData();
  }

  Future loadNewsData() async {
    try {
      final data = await supabase
          .from('news')
          .select()
          .eq('id', widget.newsId)
          .single();

      setState(() {
        titleController.text = data['title'] ?? '';
        descriptionController.text = data['description'] ?? '';
        imageUrlController.text = data['image_url'] ?? '';
        isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading news: $e')),
        );
      }
    }
  }

  Future updateNews() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.from('news').update({
        'title': titleController.text,
        'description': descriptionController.text,
        'image_url': imageUrlController.text.isEmpty ? null : imageUrlController.text,
      }).eq('id', widget.newsId);

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
                  'Updated successfully!',
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
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future deleteNews() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete News'),
        content: const Text('Are you sure you want to delete this news?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        await supabase.from('news').delete().eq('id', widget.newsId);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppHeader(
        title: 'Edit Article',
        onBackPressed: () => Navigator.pop(context),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AdminButton(
              label: isLoading ? 'Updating...' : 'Update',
              onPressed: isLoading ? () {} : updateNews,
              isLoading: isLoading,
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        const SizedBox(height: 32),
                      ],
                    ),

                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error!,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isLoading ? null : deleteNews,
                      child: const Text(
                        'Delete Article',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

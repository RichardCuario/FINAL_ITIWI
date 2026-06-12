import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shared_widgets.dart';
import 'admin_widgets.dart';

class AddBarangayPage extends StatefulWidget {
  const AddBarangayPage({super.key});

  @override
  State<AddBarangayPage> createState() => _AddBarangayPageState();
}

class _AddBarangayPageState extends State<AddBarangayPage> {
  final supabase = Supabase.instance.client;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final geographicDataController = TextEditingController();
  final officialsController = TextEditingController();
  bool isLoading = false;

  Future saveBarangay() async {
    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        geographicDataController.text.trim().isEmpty ||
        officialsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.from('barangays').insert({
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'geographic_data': geographicDataController.text.trim(),
        'officials': officialsController.text.trim(),
      });

      if (mounted) {
        await showDialog(
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
                  'Barangay saved successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdminAppHeader(
        title: 'Add Barangay',
        onBackPressed: () => Navigator.pop(context),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AdminButton(
              label: isLoading ? 'Saving...' : 'Save',
              onPressed: isLoading ? () {} : saveBarangay,
              isLoading: isLoading,
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminTextField(
                label: 'Barangay Name',
                hintText: 'Enter barangay name',
                controller: nameController,
                labelColor: AppColors.primary,
              ),
              const SizedBox(height: 20),
              AdminTextField(
                label: 'Description',
                hintText: 'Enter barangay description',
                controller: descriptionController,
                maxLines: 4,
                labelColor: AppColors.primary,
              ),
              const SizedBox(height: 20),
              AdminTextField(
                label: 'Geographic Data',
                hintText: 'Enter geographic data',
                controller: geographicDataController,
                maxLines: 4,
                labelColor: AppColors.primary,
              ),
              const SizedBox(height: 20),
              AdminTextField(
                label: 'Officials',
                hintText: 'Enter barangay officials',
                controller: officialsController,
                maxLines: 4,
                labelColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    geographicDataController.dispose();
    officialsController.dispose();
    super.dispose();
  }
}

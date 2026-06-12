import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shared_widgets.dart';
import 'admin_widgets.dart';

class EditBarangayPage extends StatefulWidget {
  final dynamic barangayId;

  const EditBarangayPage({super.key, required this.barangayId});

  @override
  State<EditBarangayPage> createState() => _EditBarangayPageState();
}

class _EditBarangayPageState extends State<EditBarangayPage> {
  final supabase = Supabase.instance.client;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final geographicDataController = TextEditingController();
  final officialsController = TextEditingController();

  bool isLoading = false;
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    loadBarangayData();
  }

  Future loadBarangayData() async {
    try {
      final data = await supabase
          .from('barangays')
          .select()
          .eq('id', widget.barangayId)
          .single();

      if (!mounted) return;

      setState(() {
        nameController.text = data['name']?.toString() ?? '';
        descriptionController.text = data['description']?.toString() ?? '';
        geographicDataController.text =
            data['geographic_data']?.toString() ?? '';
        officialsController.text = data['officials']?.toString() ?? '';
        isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading barangay: $e')),
        );
      }
    }
  }

  Future updateBarangay() async {
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
      await supabase.from('barangays').update({
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'geographic_data': geographicDataController.text.trim(),
        'officials': officialsController.text.trim(),
      }).eq('id', widget.barangayId);

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
                  'Barangay updated successfully!',
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

  Future deleteBarangay() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Barangay'),
        content: const Text(
          'Are you sure you want to delete this barangay record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      await supabase.from('barangays').delete().eq('id', widget.barangayId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barangay deleted successfully')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdminAppHeader(
        title: 'Edit Barangay',
        onBackPressed: () => Navigator.pop(context),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: AdminButton(
              label: isLoading ? 'Updating...' : 'Update',
              onPressed: isLoading ? () {} : updateBarangay,
              isLoading: isLoading,
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
      body: isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading ? null : deleteBarangay,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        'Delete Barangay',
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
    nameController.dispose();
    descriptionController.dispose();
    geographicDataController.dispose();
    officialsController.dispose();
    super.dispose();
  }
}
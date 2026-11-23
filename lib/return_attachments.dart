import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReturnAttachments extends StatelessWidget {
  const ReturnAttachments({super.key, required this.files});

  final dynamic files;

  @override
  Widget build(BuildContext context) {
    if (files is! List || (files as List).isEmpty) {
      return const SizedBox.shrink();
    }

    final attachments = (files as List).whereType<Map>().where((file) {
      final url = Uri.tryParse(file['url']?.toString() ?? '');
      return url != null && url.scheme == 'https';
    }).toList();
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text('Return attachments', style: TextStyle(fontWeight: FontWeight.w700)),
        for (final file in attachments)
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(file['url'].toString()), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.attach_file_rounded, size: 18),
            label: Text(file['name']?.toString() ?? 'View attachment'),
          ),
      ],
    );
  }
}

import 'service_date_time_picker.dart';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'upload_image_service.dart';

class BirthCertificateDetails extends ChangeNotifier {
  BirthCertificateDetails({
    this.includeBirthday = true,
    this.requireOwnerId = true,
    this.relationshipLabel = 'Relationship to Certificate Owner',
    this.relationshipOptions = relationships,
  });
  final bool includeBirthday;
  final bool requireOwnerId;
  final String relationshipLabel;
  final List<String> relationshipOptions;
  static const relationships = [
    'Self',
    'Parent',
    'Child',
    'Spouse',
    'Sibling',
    'Legal Guardian',
    'Other',
  ];
  final birthdayText = TextEditingController();
  final placeOfBirth = TextEditingController();
  final motherFullName = TextEditingController();
  final fatherFullName = TextEditingController();
  DateTime? birthday;
  String? relationship;
  PreparedUploadImage? authorization;
  PreparedUploadImage? ownerId;
  String? authorizationPath;
  String? ownerIdPath;
  bool get needsAuthorization => relationship != null && relationship != 'Self';

  void refresh() => notifyListeners();

  void selectRelationship(String? value) {
    relationship = value;
    notifyListeners();
  }

  void reset() {
    birthday = null;
    birthdayText.clear();
    placeOfBirth.clear();
    motherFullName.clear();
    fatherFullName.clear();
    relationship = null;
    authorization = ownerId = null;
    authorizationPath = ownerIdPath = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submissionFields() async {
    if ((includeBirthday && birthday == null) || relationship == null) {
      throw StateError('Complete the required request details.');
    }
    if (includeBirthday &&
        (placeOfBirth.text.trim().isEmpty ||
            motherFullName.text.trim().isEmpty)) {
      throw StateError(
        'Enter the certificate owner’s place of birth and mother’s full name.',
      );
    }
    if (needsAuthorization) {
      if (authorization == null || (requireOwnerId && ownerId == null)) {
        throw StateError(
          requireOwnerId
              ? 'Upload the authorization letter and certificate owner’s valid ID.'
              : 'Upload the authorization letter.',
        );
      }
      authorizationPath ??= await _upload(authorization!, 'authorization');
      if (requireOwnerId) ownerIdPath ??= await _upload(ownerId!, 'owner-id');
    }
    return {
      if (includeBirthday)
        'date_of_birth': birthday!.toIso8601String().split('T').first,
      if (includeBirthday) ...{
        'place_of_birth': placeOfBirth.text.trim(),
        'mother_full_name': motherFullName.text.trim(),
        'father_full_name': fatherFullName.text.trim().isEmpty
            ? null
            : fatherFullName.text.trim(),
      },
      'relationship_to_owner': relationship,
      'authorization_letter_path': needsAuthorization
          ? authorizationPath
          : null,
      if (requireOwnerId)
        'owner_valid_id_path': needsAuthorization ? ownerIdPath : null,
    };
  }

  Future<String> _upload(PreparedUploadImage image, String kind) async {
    const backend = String.fromEnvironment(
      'DIDIT_BACKEND_URL',
      defaultValue: 'https://itiwi-admin.vercel.app',
    );
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('Please sign in again.');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30);
    try {
      final request = await client.postUrl(
        Uri.parse('$backend/api/birth-certificate/upload'),
      );
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.write(
        jsonEncode({
          'kind': kind,
          'contentType': image.contentType,
          'image': base64Encode(image.bytes),
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      final body =
          jsonDecode(await utf8.decoder.bind(response).join())
              as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw StateError(
          body['error']?.toString() ?? 'Document upload failed.',
        );
      }
      return body['path'] as String;
    } finally {
      client.close(force: true);
    }
  }

  @override
  void dispose() {
    birthdayText.dispose();
    placeOfBirth.dispose();
    motherFullName.dispose();
    fatherFullName.dispose();
    super.dispose();
  }
}

class BirthCertificateDetailsFields extends StatelessWidget {
  const BirthCertificateDetailsFields({
    super.key,
    required this.details,
    this.enabled = true,
  });
  final BirthCertificateDetails details;
  final bool enabled;

  Future<void> _pickImage(BuildContext context, bool letter) async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null || !context.mounted) return;
      UploadImageService.validateInputSize(await file.length());
      final image = await UploadImageService.prepare(
        await file.readAsBytes(),
        identityDocument: true,
      );
      if (!context.mounted) return;
      if (letter) {
        details.authorization = image;
        details.authorizationPath = null;
      } else {
        details.ownerId = image;
        details.ownerIdPath = null;
      }
      details.refresh();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to use this image. Choose a JPEG, PNG, or WebP image smaller than 12 MB.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: details,
    builder: (context, _) => Column(
      children: [
        if (details.includeBirthday) ...[
          TextFormField(
            controller: details.placeOfBirth,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'Certificate Owner’s Place of Birth',
              hintText: 'City or municipality and province',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the certificate owner’s place of birth.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: details.motherFullName,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'Mother’s Full Name',
              hintText: 'Enter the certificate owner’s mother’s full name',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the mother’s full name.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: details.fatherFullName,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'Father’s Full Name (if available)',
              hintText: 'Enter the certificate owner’s father’s full name',
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (details.includeBirthday)
          TextFormField(
            controller: details.birthdayText,
            readOnly: true,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'Certificate Owner’s Birthday',
              hintText: 'Select date of birth',
              suffixIcon: Icon(Icons.calendar_month),
            ),
            validator: (_) => details.birthday == null
                ? 'Select the certificate owner’s birthday.'
                : null,
            onTap: () async {
              final now = DateTime.now();
              final date = await showServiceDatePicker(
                context: context,
                initialDate: details.birthday ?? now,
                firstDate: DateTime(1850),
                lastDate: now,
              );
              if (date != null && context.mounted) {
                details.birthday = date;
                details.birthdayText.text = date
                    .toIso8601String()
                    .split('T')
                    .first;
              }
            },
          ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: details.relationship,
          key: ValueKey(details.relationship),
          isExpanded: true,
          decoration: InputDecoration(labelText: details.relationshipLabel),
          items: details.relationshipOptions
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: enabled ? details.selectRelationship : null,
          validator: (value) =>
              value == null ? 'Please choose an option.' : null,
        ),
        if (details.needsAuthorization) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              details.requireOwnerId
                  ? 'For requests on behalf of someone else, upload both documents below.'
                  : 'Upload an authorization letter for this request.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final letter in [true, if (details.requireOwnerId) false])
            FormField<bool>(
              validator: (_) =>
                  (letter ? details.authorization : details.ownerId) == null
                  ? 'Please upload ${letter ? 'the authorization letter' : 'the certificate owner’s valid ID'}.'
                  : null,
              builder: (field) {
                final image = letter ? details.authorization : details.ownerId;
                return _DocumentUploadCard(
                  title: letter
                      ? 'Upload Authorization Letter'
                      : 'Upload Certificate Owner’s Valid ID',
                  hint: letter
                      ? 'A clear photo of the signed letter'
                      : 'A clear photo of the owner’s ID',
                  icon: letter
                      ? Icons.description_outlined
                      : Icons.badge_outlined,
                  image: image,
                  error: field.errorText,
                  enabled: enabled,
                  onPick: () async {
                    await _pickImage(context, letter);
                    if (context.mounted) field.validate();
                  },
                  onRemove: () {
                    if (letter) {
                      details.authorization = null;
                      details.authorizationPath = null;
                    } else {
                      details.ownerId = null;
                      details.ownerIdPath = null;
                    }
                    details.refresh();
                    field.validate();
                  },
                );
              },
            ),
        ],
      ],
    ),
  );
}

class _DocumentUploadCard extends StatelessWidget {
  const _DocumentUploadCard({
    required this.title,
    required this.hint,
    required this.icon,
    required this.image,
    required this.error,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final String title;
  final String hint;
  final IconData icon;
  final PreparedUploadImage? image;
  final String? error;
  final bool enabled;
  final Future<void> Function() onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = image != null;
    final borderColor = error != null
        ? colors.error
        : selected
        ? colors.primary.withValues(alpha: 0.55)
        : colors.outlineVariant;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.28)
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: enabled ? onPick : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: borderColor,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: selected
                          ? Image.memory(
                              image!.bytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  Icon(icon, color: colors.primary),
                            )
                          : Icon(icon, color: colors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selected ? 'Image added • Tap to replace' : hint,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selected && enabled)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Remove image'),
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6),
              child: Text(
                error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ),
        ],
      ),
    );
  }
}

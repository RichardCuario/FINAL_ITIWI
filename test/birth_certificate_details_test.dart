import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/upload_image_service.dart';
import 'package:hotline_app/birth_certificate_details.dart';

void main() {
  testWidgets('other services require only a letter for representatives', (
    tester,
  ) async {
    final details = BirthCertificateDetails(
      includeBirthday: false,
      requireOwnerId: false,
    );
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(
              key: form,
              child: BirthCertificateDetailsFields(details: details),
            ),
          ),
        ),
      ),
    );
    details.selectRelationship('Self');
    await tester.pump();
    expect(find.text('Certificate Owner’s Birthday'), findsNothing);
    expect(form.currentState!.validate(), true);
    final self = await details.submissionFields();
    expect(self.containsKey('date_of_birth'), false);
    expect(self['authorization_letter_path'], isNull);
    details.selectRelationship('Spouse');
    await tester.pump();
    expect(form.currentState!.validate(), false);
    expect(find.text('Upload Authorization Letter'), findsOneWidget);
    expect(find.text('Upload Certificate Owner’s Valid ID'), findsNothing);
    details.authorization = PreparedUploadImage(
      Uint8List(0),
      'jpg',
      'image/jpeg',
    );
    details.authorizationPath = 'user/letter.jpg';
    expect(form.currentState!.validate(), true);
    final representative = await details.submissionFields();
    expect(representative['authorization_letter_path'], 'user/letter.jpg');
    expect(representative.containsKey('owner_valid_id_path'), false);
    details.selectRelationship('Self');
    await tester.pump();
    expect(
      (await details.submissionFields())['authorization_letter_path'],
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    details.dispose();
  });
  testWidgets('self hides uploads; other relationships require both images', (
    tester,
  ) async {
    final details = BirthCertificateDetails();
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(
              key: form,
              child: BirthCertificateDetailsFields(details: details),
            ),
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), false);
    details.birthday = DateTime(2000, 1, 2);
    details.birthdayText.text = '2000-01-02';
    details.placeOfBirth.text = 'Tiwi, Albay';
    details.motherFullName.text = 'Maria Santos';
    details.fatherFullName.text = 'Pedro Santos';
    details.selectRelationship('Self');
    await tester.pump();
    expect(find.text('Upload Authorization Letter'), findsNothing);
    expect(form.currentState!.validate(), true);
    details.selectRelationship('Parent');
    await tester.pump();
    expect(find.text('Upload Authorization Letter'), findsOneWidget);
    expect(find.text('Upload Certificate Owner’s Valid ID'), findsOneWidget);
    expect(form.currentState!.validate(), false);
    details.authorization = PreparedUploadImage(
      Uint8List(0),
      'jpg',
      'image/jpeg',
    );
    details.ownerId = PreparedUploadImage(Uint8List(0), 'jpg', 'image/jpeg');
    details.authorizationPath = 'test/letter.jpg';
    details.ownerIdPath = 'test/owner-id.jpg';
    details.refresh();
    await tester.pump();
    expect(find.text('Image added • Tap to replace'), findsNWidgets(2));
    expect(find.text('Remove image'), findsNWidgets(2));
    expect(form.currentState!.validate(), true);
    final representativeFields = await details.submissionFields();
    expect(representativeFields['relationship_to_owner'], 'Parent');
    expect(representativeFields['place_of_birth'], 'Tiwi, Albay');
    expect(representativeFields['mother_full_name'], 'Maria Santos');
    await tester.tap(find.text('Remove image').first);
    await tester.pump();
    expect(details.authorization, isNull);
    expect(form.currentState!.validate(), false);
    details.selectRelationship('Self');
    await tester.pump();
    expect(form.currentState!.validate(), true);
    final fields = await details.submissionFields();
    expect(fields['date_of_birth'], '2000-01-02');
    expect(fields['place_of_birth'], 'Tiwi, Albay');
    expect(fields['mother_full_name'], 'Maria Santos');
    expect(fields['father_full_name'], 'Pedro Santos');
    expect(fields['authorization_letter_path'], isNull);
    expect(fields['owner_valid_id_path'], isNull);
    details.reset();
    await tester.pump();
    expect(form.currentState!.validate(), false);
    await tester.pumpWidget(const SizedBox());
    details.dispose();
  });
}

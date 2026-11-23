import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/upload_image_service.dart';
import 'package:image/image.dart' as img;

void main() {
  test(
    'large portrait is resized without cropping and remains decodable',
    () async {
      final source = img.Image(width: 1200, height: 2400);
      img.fill(source, color: img.ColorRgb8(80, 120, 180));
      final prepared = await UploadImageService.prepare(img.encodePng(source));
      final decoded = img.decodeImage(prepared.bytes)!;
      expect(decoded.width, 900);
      expect(decoded.height, 1800);
      expect(prepared.extension, 'jpg');
      expect(prepared.contentType, 'image/jpeg');
      expect(
        prepared.bytes.length,
        lessThanOrEqualTo(UploadImageService.maxOutputBytes),
      );
    },
  );

  test('small PNG is retained when JPEG would be larger', () async {
    final source = img.Image(width: 16, height: 16);
    final original = img.encodePng(source);
    final prepared = await UploadImageService.prepare(original);
    expect(prepared.bytes, orderedEquals(original));
    expect(prepared.extension, 'png');
    expect(prepared.contentType, 'image/png');
  });

  test('identity photos retain more resolution for text', () async {
    final source = img.Image(width: 2600, height: 1300);
    final prepared = await UploadImageService.prepare(
      img.encodePng(source),
      identityDocument: true,
    );
    final decoded = img.decodeImage(prepared.bytes)!;
    expect(decoded.width, 2400);
    expect(decoded.height, 1200);
  });

  test('invalid and oversized files are rejected', () async {
    await expectLater(
      UploadImageService.prepare(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
    await expectLater(
      UploadImageService.prepare(
        Uint8List(UploadImageService.maxInputBytes + 1),
      ),
      throwsFormatException,
    );
  });
}

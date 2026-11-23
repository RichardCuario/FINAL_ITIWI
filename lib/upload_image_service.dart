import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class PreparedUploadImage {
  final Uint8List bytes;
  final String extension;
  final String contentType;

  const PreparedUploadImage(this.bytes, this.extension, this.contentType);
}

/// Shared policy for user photo uploads. Documents must not use this encoder.
class UploadImageService {
  static const maxInputBytes = 12 * 1024 * 1024;
  static const maxOutputBytes = 2 * 1024 * 1024;

  static void validateInputSize(int length) {
    if (length == 0 || length > maxInputBytes) {
      throw const FormatException('Please choose an image smaller than 12 MB.');
    }
  }

  static Future<PreparedUploadImage> prepare(
    Uint8List bytes, {
    bool identityDocument = false,
  }) async {
    validateInputSize(bytes.length);
    try {
      return await compute(_prepare, (bytes, identityDocument));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'This image could not be read. Choose another JPEG, PNG, or WebP photo.',
      );
    }
  }

  static PreparedUploadImage _prepare((Uint8List, bool) request) {
    final (bytes, identityDocument) = request;
    final decoder = img.findDecoderForData(bytes);
    final String extension;
    final String contentType;
    if (decoder is img.JpegDecoder) {
      extension = 'jpg';
      contentType = 'image/jpeg';
    } else if (decoder is img.PngDecoder) {
      extension = 'png';
      contentType = 'image/png';
    } else if (decoder is img.WebPDecoder) {
      extension = 'webp';
      contentType = 'image/webp';
    } else {
      throw const FormatException('Please choose a JPEG, PNG, or WebP photo.');
    }
    final info = decoder!.startDecode(bytes);
    if (info == null ||
        info.width <= 0 ||
        info.height <= 0 ||
        info.width * info.height > 32000000 ||
        info.numFrames != 1) {
      throw const FormatException(
        'Please choose a still photo no larger than 32 megapixels.',
      );
    }
    final decoded = decoder.decodeFrame(0);
    if (decoded == null) {
      throw const FormatException(
        'This image could not be read. Choose another photo.',
      );
    }
    var photo = img.bakeOrientation(decoded);
    final maxSide = identityDocument ? 2400 : 1800;
    final needsResize = photo.width > maxSide || photo.height > maxSide;
    if (needsResize) {
      photo = img.copyResize(
        photo,
        width: photo.width >= photo.height ? maxSide : null,
        height: photo.height > photo.width ? maxSide : null,
        interpolation: img.Interpolation.average,
      );
    }
    // Flatten transparency onto white and omit source metadata in the JPEG.
    final canvas = img.Image(width: photo.width, height: photo.height);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(canvas, photo);
    final targetBytes = identityDocument ? 1500 * 1024 : 750 * 1024;
    final qualities = identityDocument ? [90, 85, 80] : [82, 75, 68];
    var compressed = img.encodeJpg(canvas, quality: qualities.first);
    for (final quality in qualities.skip(1)) {
      if (compressed.length <= targetBytes) break;
      compressed = img.encodeJpg(canvas, quality: quality);
    }
    // Keep an already small original when re-encoding would increase storage.
    final result = !needsResize && bytes.length <= compressed.length
        ? PreparedUploadImage(bytes, extension, contentType)
        : PreparedUploadImage(compressed, 'jpg', 'image/jpeg');
    if (result.bytes.length > maxOutputBytes) {
      throw const FormatException(
        'This image is still larger than 2 MB after compression. Choose a smaller photo.',
      );
    }
    return result;
  }
}

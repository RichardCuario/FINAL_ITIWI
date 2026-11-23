import 'dart:io';

import 'package:image/image.dart' as img;

// Run with `dart run tool/optimize_assets.dart`. Source artwork is preserved.
void main(List<String> args) {
  const sources = [
    'bg.jpg',
    'card.jpg',
    'municipal_hall.jpg',
    'onboarding1.png',
    'onboarding2.png',
    'onboarding3.png',
    'Group 112.png',
    'logo.png',
  ];
  final inspect = args.contains('--inspect');
  if (!inspect) Directory('assets/optimized').createSync(recursive: true);
  for (final name in sources) {
    final file = File('assets/$name');
    final bytes = file.readAsBytesSync();
    var photo = img.decodeImage(bytes);
    if (photo == null) throw StateError('Cannot decode ${file.path}');
    final transparent =
        photo.hasAlpha && photo.any((pixel) => pixel.a < pixel.maxChannelValue);
    stdout.writeln(
      '$name: ${photo.width}x${photo.height}, ${bytes.length} bytes, transparency=$transparent',
    );
    if (inspect) continue;
    photo = img.bakeOrientation(photo);
    final maxSide = name == 'Group 112.png' ? 680 : 1920;
    if (photo.width > maxSide || photo.height > maxSide) {
      photo = img.copyResize(
        photo,
        width: photo.width >= photo.height ? maxSide : null,
        height: photo.height > photo.width ? maxSide : null,
        interpolation: img.Interpolation.average,
      );
    }
    final keepPng =
        transparent || name == 'logo.png' || name == 'Group 112.png';
    final outputName = keepPng
        ? name
        : name.replaceFirst(RegExp(r'\.[^.]+$'), '.jpg');
    final encoded = keepPng
        ? img.encodePng(photo, level: 9)
        : img.encodeJpg(photo, quality: 85);
    final output = File('assets/optimized/$outputName');
    // Use the original encoding when recompression would make it larger.
    if (encoded.length >= bytes.length) {
      File('assets/optimized/$name').writeAsBytesSync(bytes);
      stdout.writeln('  -> original retained (${bytes.length} bytes)');
    } else {
      output.writeAsBytesSync(encoded);
      stdout.writeln('  -> ${output.path}: ${encoded.length} bytes');
    }
  }
}

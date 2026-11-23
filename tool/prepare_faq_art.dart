import 'dart:io';
import 'package:image/image.dart' as img;

// Resize the generated transparent artwork for the small FAQ header.
void main(List<String> args) {
  final source = img.decodeImage(File(args.single).readAsBytesSync())!;
  final small = img.copyResize(
    source,
    width: 420,
    interpolation: img.Interpolation.average,
  );
  final file = File('assets/optimized/faq_support.png');
  file.writeAsBytesSync(img.encodePng(small, level: 9));
  stdout.writeln('${file.path}: ${file.lengthSync()} bytes');
}

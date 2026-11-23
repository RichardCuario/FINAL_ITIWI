import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/hotline.dart';

void main() {
  test('decodeDataUriToBytes decodes a base64 data URI', () {
    final source = 'data:image/png;base64,${base64Encode([1, 2, 3, 4, 5])}';

    final bytes = decodeDataUriToBytes(source);

    expect(bytes, [1, 2, 3, 4, 5]);
  });
}

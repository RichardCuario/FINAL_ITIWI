import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/app_update_service.dart';

Map<String, dynamic> releaseJson() => {
  'packageName': 'com.ecoimpact.itiwi',
  'version': '1.0.4',
  'buildNumber': 7,
  'apkUrl': 'https://www.itiwi.online/downloads/itiwi-7.apk',
  'sha256': 'a' * 64,
  'notes': 'New features',
};

void main() {
  test('compares installed build numbers, including same-version rebuilds', () {
    final release = AppRelease.fromJson(releaseJson());
    expect(release.isNewerThan(6), isTrue);
    expect(release.isNewerThan(7), isFalse);
    expect(release.isNewerThan(8), isFalse);
  });

  test('rejects untrusted or insecure downloads', () {
    for (final url in [
      'http://www.itiwi.online/downloads/app.apk',
      'https://itiwi.online.evil.com/app.apk',
      'https://evil.com/app.apk',
      'https://user@itiwi.online/app.apk',
      'https://itiwi.online:8443/app.apk',
      'https://itiwi.online/index.html',
    ]) {
      expect(
        () => AppRelease.fromJson({...releaseJson(), 'apkUrl': url}),
        throwsFormatException,
      );
    }
  });

  test('rejects missing checksum, wrong package and invalid build', () {
    for (final patch in [
      {'sha256': ''},
      {'packageName': 'other.app'},
      {'buildNumber': 0},
      {'buildNumber': '7'},
      {'version': ''},
    ]) {
      expect(
        () => AppRelease.fromJson({...releaseJson(), ...patch}),
        throwsFormatException,
      );
    }
  });
}

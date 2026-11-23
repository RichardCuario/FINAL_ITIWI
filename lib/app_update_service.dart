import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppRelease {
  const AppRelease({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.sha256,
    required this.notes,
  });

  final String version;
  final int buildNumber;
  final Uri apkUrl;
  final String sha256;
  final String notes;

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final uri = Uri.tryParse(json['apkUrl'] as String? ?? '');
    final build = json['buildNumber'];
    final hash = json['sha256'] as String? ?? '';
    final version = json['version'] as String? ?? '';
    if (json['packageName'] != 'com.ecoimpact.itiwi' ||
        build is! int ||
        build <= 0 ||
        version.isEmpty ||
        uri == null ||
        uri.scheme != 'https' ||
        !{'www.itiwi.online', 'itiwi.online'}.contains(uri.host) ||
        uri.userInfo.isNotEmpty ||
        uri.port != 443 ||
        !uri.path.endsWith('.apk') ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash)) {
      throw const FormatException('Invalid app release');
    }
    return AppRelease(
      version: version,
      buildNumber: build,
      apkUrl: uri,
      sha256: hash.toLowerCase(),
      notes: json['notes'] as String? ?? '',
    );
  }

  bool isNewerThan(int installedBuild) => buildNumber > installedBuild;

  Map<String, dynamic> toNative() => {
    'apkUrl': apkUrl.toString(),
    'buildNumber': buildNumber,
    'sha256': sha256,
  };
}

class AppUpdateService {
  static const channel = MethodChannel('com.ecoimpact.itiwi/app_updates');

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<AppRelease?> check() async {
    if (!supported) return null;
    final data = await channel.invokeMapMethod<String, dynamic>('check');
    if (data == null) return null;
    final release = AppRelease.fromJson(
      jsonDecode(data['manifest'] as String) as Map<String, dynamic>,
    );
    return release.isNewerThan((data['installedBuild'] as num).toInt())
        ? release
        : null;
  }

  Future<void> download(
    AppRelease release,
    ValueChanged<double?> progress,
  ) async {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'progress') {
        progress((call.arguments as num?)?.toDouble());
      }
    });
    try {
      await channel.invokeMethod<void>('download', release.toNative());
    } finally {
      channel.setMethodCallHandler(null);
    }
  }

  Future<String> install() async =>
      await channel.invokeMethod<String>('install') ?? 'opened';
}

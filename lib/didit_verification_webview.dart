import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'identity_verification_theme.dart';

class DiditVerificationWebView extends StatefulWidget {
  const DiditVerificationWebView({super.key, required this.sessionUrl});

  final String sessionUrl;

  @override
  State<DiditVerificationWebView> createState() => _DiditVerificationWebViewState();
}

class _DiditVerificationWebViewState extends State<DiditVerificationWebView> {
  static const _mediaChannel = MethodChannel('com.ecoimpact.itiwi/verification_media');
  static const _callbackUrl = 'https://itiwi-admin.vercel.app/verification-complete';
  static const _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final PlatformWebViewControllerCreationParams params =
        WebViewPlatform.instance is WebKitWebViewPlatform
            ? WebKitWebViewControllerCreationParams(
                allowsInlineMediaPlayback: true,
                mediaTypesRequiringUserAction: const {},
              )
            : const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: _handlePermissionRequest,
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_mobileUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final callback = Uri.parse(_callbackUrl);
            if (uri?.scheme == callback.scheme &&
                uri?.host == callback.host &&
                uri?.path == callback.path) {
              if (mounted) Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.sessionUrl));

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  Future<void> _handlePermissionRequest(WebViewPermissionRequest request) async {
    final currentUrl = await _controller.currentUrl();
    final host = Uri.tryParse(currentUrl ?? '')?.host.toLowerCase();
    if (host != 'verify.didit.me' && !(host?.endsWith('.didit.me') ?? false)) {
      await request.deny();
      return;
    }

    try {
      final allowed = !Platform.isAndroid ||
          (await _mediaChannel.invokeMethod<bool>('requestMediaPermissions') ?? false);
      if (allowed) {
        await request.grant();
      } else {
        await request.deny();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera and microphone access are needed for verification.')),
          );
        }
      }
    } catch (_) {
      await request.deny();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = identityVerificationBlue(Theme.of(context).brightness);
    final barForeground = isDark ? Colors.black87 : Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify with iTIWI'),
        backgroundColor: barColor,
        foregroundColor: barForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: barColor,
          statusBarIconBrightness: isDark ? Brightness.dark : Brightness.light,
          statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(minHeight: 3),
        ],
      ),
    );
  }
}

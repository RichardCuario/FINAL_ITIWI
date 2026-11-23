import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_update_service.dart';

/// Lives above the navigator so a launch check works across login and pages.
class AppUpdatePrompt extends StatefulWidget {
  const AppUpdatePrompt({
    super.key,
    required this.navigatorKey,
    required this.child,
    this.service,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  final AppUpdateService? service;

  @override
  State<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends State<AppUpdatePrompt>
    with WidgetsBindingObserver {
  late final AppUpdateService _service = widget.service ?? AppUpdateService();
  Timer? _startup;
  bool _wasInBackground = false;
  bool _checking = false;
  bool _showing = false;
  final Set<int> _shownBuilds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startup = Timer(const Duration(seconds: 3), _check);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      _startup?.cancel();
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    if (_checking ||
        _showing ||
        !_service.supported ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.hidden) {
      return;
    }
    _checking = true;
    try {
      final release = await _service.check();
      if (!mounted ||
          release == null ||
          _shownBuilds.contains(release.buildNumber)) {
        return;
      }
      final context = widget.navigatorKey.currentState?.overlay?.context;
      if (context == null || !context.mounted) return;
      _shownBuilds.add(release.buildNumber);
      _showing = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _UpdateDialog(release: release, service: _service),
      );
    } catch (error) {
      // Offline, missing release metadata, and server errors never block the app.
      debugPrint('App update check unavailable: $error');
    } finally {
      _checking = false;
      _showing = false;
    }
  }

  @override
  void dispose() {
    _startup?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.release, required this.service});
  final AppRelease release;
  final AppUpdateService service;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _busy = false;
  bool _downloaded = false;
  double? _progress;
  String? _message;

  Future<void> _update() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (!_downloaded) {
        await widget.service.download(widget.release, (value) {
          if (mounted) setState(() => _progress = value);
        });
        _downloaded = true;
      }
      final status = await widget.service.install();
      if (mounted) {
        setState(
          () => _message = status == 'permission'
              ? 'Allow updates from iTIWI in Settings, then return here and tap Install update.'
              : 'Complete the Android installation prompt. If you cancelled, tap Install update to try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'The update could not be completed. Please try again or download from the website.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _website() async {
    try {
      if (!await launchUrl(
        widget.release.apkUrl,
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError('No browser');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Please visit www.itiwi.online to download the update.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? const Color(0xFFF1F5FF) : const Color(0xFF10213E);
    final secondary = dark ? const Color(0xFFB7C5DB) : const Color(0xFF62728B);
    const blue = Color(0xFF0875ED);
    return PopScope(
      canPop: !_busy,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [const Color(0xFF192940), const Color(0xFF111B2D)]
                    : [Colors.white, const Color(0xFFF3F7FF)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _UpdateArtwork(),
                          Text(
                            'New update available',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: foreground,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'iTIWI ${widget.release.version} is ready to download.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: secondary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (widget.release.notes.isNotEmpty) ...[
                            _UpdateInfoCard(
                              icon: Icons.article_outlined,
                              accent: blue,
                              title: "What's new",
                              message: widget.release.notes,
                            ),
                            const SizedBox(height: 12),
                          ],
                          const _UpdateInfoCard(
                            icon: Icons.verified_user_rounded,
                            accent: Color(0xFF0AAF75),
                            title: 'Your account and data are safe',
                            message:
                                'Your account and data will stay on your device. Android will ask you to confirm installation.',
                          ),
                          if (_busy) ...[
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 7,
                                color: blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _downloaded
                                  ? 'Opening installer…'
                                  : _progress == null
                                  ? 'Downloading update…'
                                  : 'Downloading update… ${(_progress! * 100).round()}%',
                              style: TextStyle(color: secondary, fontSize: 13),
                            ),
                          ],
                          if (_message != null) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _message!,
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _busy ? null : _update,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _downloaded
                                ? Icons.install_mobile_rounded
                                : Icons.download_rounded,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _downloaded ? 'Install update' : 'Update now',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dark
                            ? const Color(0xFF91C4FF)
                            : const Color(0xFF2870C6),
                        minimumSize: const Size.fromHeight(46),
                        side: BorderSide(
                          color: dark
                              ? const Color(0xFF3C5476)
                              : const Color(0xFFCBD8EC),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _busy ? null : _website,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text(
                        'Download in browser',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: secondary),
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Later'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateInfoCard extends StatelessWidget {
  const _UpdateInfoCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final Color accent;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF20314B) : const Color(0xFFEDF3FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: dark
                        ? const Color(0xFFF1F5FF)
                        : const Color(0xFF152744),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: dark
                        ? const Color(0xFFBDCCE1)
                        : const Color(0xFF4D607C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateArtwork extends StatelessWidget {
  const _UpdateArtwork();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 140,
      child: Center(
        child: SizedBox(
          width: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 210,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFF3394FF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(70),
                ),
              ),
              Transform.rotate(
                angle: -0.10,
                child: Container(
                  width: 79,
                  height: 119,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F1FF),
                    border: Border.all(
                      color: const Color(0xFF355889),
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF355889),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(5),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'i',
                            style: TextStyle(
                              fontSize: 48,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0875ED),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 0.65,
                            minHeight: 6,
                            color: Color(0xFF0875ED),
                            backgroundColor: Color(0xFFC5D8F5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: 12,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0875ED),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x302575E7),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const Positioned(
                left: 39,
                top: 40,
                child: Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF69ADFF),
                  size: 20,
                ),
              ),
              const Positioned(
                right: 48,
                top: 24,
                child: Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF69ADFF),
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

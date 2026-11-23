import 'dart:async';

import 'package:flutter/material.dart';

import 'app_splash_gate.dart';

/// Subscribe immediately, even while the splash is visible. Broadcast auth
/// streams need not replay a restored session to a late subscriber.
class AppSessionGate<T extends Object> extends StatefulWidget {
  const AppSessionGate({
    super.key,
    required this.sessions,
    required this.signedInBuilder,
    required this.signedOutBuilder,
    this.initialUser,
    this.readCurrentUser,
  });

  final Stream<T?> sessions;
  final T? initialUser;

  /// Reads the SDK's locally persisted session without requiring the network.
  final T? Function()? readCurrentUser;
  final Widget Function(BuildContext, T) signedInBuilder;
  final WidgetBuilder signedOutBuilder;

  @override
  State<AppSessionGate<T>> createState() => _AppSessionGateState<T>();
}

class _AppSessionGateState<T extends Object> extends State<AppSessionGate<T>>
    with WidgetsBindingObserver {
  StreamSubscription<T?>? _subscription;
  T? _user;
  bool _resolved = false;
  bool _restoreFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _user = widget.readCurrentUser?.call() ?? widget.initialUser;
    _resolved = _user != null;
    _subscribe();
  }

  void _subscribe() {
    _subscription = widget.sessions.listen(
      (user) {
        if (!mounted) return;
        setState(() {
          _user = user;
          _resolved = true;
          _restoreFailed = false;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        // An error is not a signed-out event. StreamBuilder would discard its
        // data here and incorrectly route an authenticated user to login.
        setState(() {
          _user = widget.readCurrentUser?.call() ?? _user;
          _restoreFailed = true;
        });
        debugPrint('Could not restore auth session: $error');
      },
      onDone: () {
        if (!mounted || _resolved) return;
        setState(() => _restoreFailed = true);
      },
    );
  }

  @override
  void didUpdateWidget(covariant AppSessionGate<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessions != widget.sessions) {
      _subscription?.cancel();
      _subscribe();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || widget.readCurrentUser == null) {
      return;
    }
    final user = widget.readCurrentUser!();
    // The native session may not have reached the Dart cache yet on resume.
    // Only an explicit null from the auth stream confirms a sign-out.
    // Keep the last confirmed session while waiting for that event.
    if (user == null) return;
    setState(() {
      _user = user;
      _resolved = true;
      _restoreFailed = false;
    });
  }

  void _retry() {
    _subscription?.cancel();
    setState(() => _restoreFailed = false);
    _subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return AppSplashGate(
      child: user != null
          ? widget.signedInBuilder(context, user)
          : _restoreFailed
          ? Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not restore your session. Please retry.'),
                    TextButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : !_resolved
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : widget.signedOutBuilder(context),
    );
  }
}

/// Authentication pages are temporary routes above the persistent session gate.
void returnToSessionRoot(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

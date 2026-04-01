import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    this.initialMode = AuthMode.login,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  final AuthMode initialMode;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

enum AuthMode { login, signUp }

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AuthMode _mode;
  bool _isLoading = false;

  bool get _isLogin => _mode == AuthMode.login;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _buildEmailValue();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showMessage('Email is required.');
      return;
    }

    if (!_isLogin && username.isEmpty) {
      _showMessage('Username is required.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomePage(
              isDarkMode: widget.isDarkMode,
              onToggleDarkMode: widget.onToggleDarkMode,
            ),
          ),
        );
      } else {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (username.isNotEmpty) {
          await credential.user?.updateDisplayName(username);
        }
        await credential.user?.sendEmailVerification();

        if (!mounted) return;
        _showMessage(
          'Sign up successful. Please verify your email before logging in.',
        );
        setState(() {
          _mode = AuthMode.login;
        });
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(_mapAuthError(error));
    } catch (_) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _buildEmailValue() {
    return _emailController.text.trim();
  }

  Future<void> _forgotPassword() async {
    final email = _buildEmailValue();

    if (email.isEmpty) {
      _showMessage('Enter your email first.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showMessage('Password reset email sent.');
    } on FirebaseAuthException catch (error) {
      _showMessage(_mapAuthError(error));
    } catch (_) {
      _showMessage('Unable to send reset email right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _showMessage('Google sign-in was cancelled.');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(
            isDarkMode: widget.isDarkMode,
            onToggleDarkMode: widget.onToggleDarkMode,
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      _showMessage(_mapAuthError(error));
    } catch (_) {
      _showMessage('Google sign-in is unavailable right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      switch (loginResult.status) {
        case LoginStatus.success:
          final accessToken = loginResult.accessToken;
          if (accessToken == null) {
            _showMessage('Facebook sign-in failed. Missing access token.');
            return;
          }

          final credential = FacebookAuthProvider.credential(
            accessToken.tokenString,
          );

          await _auth.signInWithCredential(credential);

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomePage(
                isDarkMode: widget.isDarkMode,
                onToggleDarkMode: widget.onToggleDarkMode,
              ),
            ),
          );
          break;
        case LoginStatus.cancelled:
          _showMessage('Facebook sign-in was cancelled.');
          break;
        case LoginStatus.failed:
          _showMessage(
            loginResult.message ?? 'Facebook sign-in failed. Please try again.',
          );
          break;
        case LoginStatus.operationInProgress:
          _showMessage('Facebook sign-in is already in progress.');
          break;
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(_mapAuthError(error));
    } catch (error) {
      _showMessage('Facebook sign-in failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Login now!' : 'Sign up now!';
    final subtitle = 'Start your journey now with ease.';
    final buttonLabel = _isLogin ? 'Login' : 'Sign up';
    final footerPrompt = _isLogin
        ? "Don't have an account? "
        : 'Already have an account? ';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            final compact = screenHeight < 760 || screenWidth < 380;
            final extraCompact = screenHeight < 690 || screenWidth < 360;
            final horizontalPadding = extraCompact
                ? 20.0
                : compact
                    ? 24.0
                    : 34.0;
            final topPanelPadding = extraCompact
                ? 20.0
                : compact
                    ? 24.0
                    : 36.0;
            final fieldSpacing = extraCompact
                ? 12.0
                : compact
                    ? 14.0
                    : 20.0;
            final sectionSpacing = extraCompact
                ? 16.0
                : compact
                    ? 20.0
                    : 28.0;
            final titleFontSize = extraCompact
                ? 19.0
                : compact
                    ? 21.0
                    : 24.0;
            final subtitleFontSize = extraCompact
                ? 13.0
                : compact
                    ? 14.0
                    : 15.0;
            final socialGap = extraCompact
                ? 8.0
                : compact
                    ? 12.0
                    : 18.0;
            final headerTopSpace = extraCompact ? 12.0 : compact ? 16.0 : 28.0;
            final headerBottomSpace =
                extraCompact ? 12.0 : compact ? 16.0 : 28.0;
            final blueHeaderHeight = extraCompact
                ? 210.0
                : compact
                    ? 240.0
                    : 290.0;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Container(
                  color: const Color(0xFFF2F2F2),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: const Color(0xFF2357A6),
                        padding: EdgeInsets.only(
                          top: headerTopSpace,
                          bottom: headerBottomSpace,
                        ),
                        child: _AuthHeader(compact: compact || extraCompact),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            topPanelPadding,
                            horizontalPadding,
                            extraCompact ? 16 : compact ? 20 : 28,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(34),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: extraCompact ? 4 : compact ? 6 : 8,
                              ),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  color: const Color(0xFF8A8A8A),
                                ),
                              ),
                              SizedBox(
                                height: extraCompact ? 18 : compact ? 22 : 34,
                              ),
                              _AuthTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                compact: compact || extraCompact,
                              ),
                              SizedBox(height: fieldSpacing),
                              if (!_isLogin) ...[
                                _AuthTextField(
                                  controller: _usernameController,
                                  hintText: 'Username or full name',
                                  icon: Icons.person_outline,
                                  compact: compact || extraCompact,
                                ),
                                SizedBox(height: fieldSpacing),
                              ],
                              _AuthTextField(
                                controller: _passwordController,
                                hintText: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                compact: compact || extraCompact,
                              ),
                              if (_isLogin) ...[
                                SizedBox(
                                  height: extraCompact ? 6 : compact ? 8 : 12,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed:
                                        _isLoading ? null : _forgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: const Color(0xFF0B4C8C),
                                        fontSize: extraCompact ? 13 : 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(
                                height: extraCompact ? 20 : compact ? 24 : 38,
                              ),
                              Center(
                                child: SizedBox(
                                  width: extraCompact
                                      ? 160
                                      : compact
                                          ? 170
                                          : 180,
                                  height: extraCompact
                                      ? 44
                                      : compact
                                          ? 46
                                          : 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B4C8C),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      disabledBackgroundColor:
                                          const Color(0xFF0B4C8C),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            buttonLabel,
                                            style: TextStyle(
                                              fontSize: extraCompact
                                                  ? 14
                                                  : compact
                                                      ? 15
                                                      : 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(height: sectionSpacing),
                              if (_isLogin) ...[
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                        color: Color(0xFFB7B7B7),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: extraCompact ? 10 : 14,
                                      ),
                                      child: Text(
                                        'or login with',
                                        style: TextStyle(
                                          fontSize: extraCompact ? 12 : 14,
                                          color: const Color(0xFF444444),
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                        color: Color(0xFFB7B7B7),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: extraCompact ? 14 : compact ? 18 : 28,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SocialButton(
                                        icon: Icons.g_mobiledata,
                                        label: 'Google',
                                        iconColor: const Color(0xFFDB4437),
                                        compact: compact || extraCompact,
                                        onTap:
                                            _isLoading ? null : _signInWithGoogle,
                                      ),
                                    ),
                                    SizedBox(width: socialGap),
                                    Expanded(
                                      child: _SocialButton(
                                        icon: Icons.facebook,
                                        label: 'Facebook',
                                        iconColor: const Color(0xFF1877F2),
                                        compact: compact || extraCompact,
                                        onTap: _isLoading
                                            ? null
                                            : _signInWithFacebook,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: extraCompact ? 14 : compact ? 20 : 28,
                                ),
                              ] else ...[
                                SizedBox(
                                  height: extraCompact ? 14 : compact ? 20 : 28,
                                ),
                                const Divider(color: Color(0xFFB7B7B7)),
                                SizedBox(
                                  height: extraCompact ? 14 : compact ? 18 : 24,
                                ),
                              ],
                              Center(
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _switchMode(
                                            _isLogin
                                                ? AuthMode.signUp
                                                : AuthMode.login,
                                          ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: extraCompact ? 14 : 15,
                                        color: const Color(0xFF8A8A8A),
                                      ),
                                      children: [
                                        TextSpan(text: footerPrompt),
                                        TextSpan(
                                          text: _isLogin ? 'Sign up' : 'Login',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: extraCompact ? 8 : 12),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: blueHeaderHeight > 0 ? 0 : 0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          height: compact ? 58 : 72,
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          'ITIWI',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 30 : 38,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: compact ? 1 : 2),
        Text(
          "ORAGON'S CHARM. BICOL'S SOUL.",
          style: TextStyle(
            color: Colors.white70,
            fontSize: compact ? 8.5 : 10,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.compact = false,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF666666)),
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFF555555),
          fontSize: compact ? 14 : 16,
        ),
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: EdgeInsets.symmetric(vertical: compact ? 14 : 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF9C9C9C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFF0B4C8C),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.compact = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: compact ? 40 : 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD0D0D0)),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: compact ? 22 : 26),
              SizedBox(width: compact ? 8 : 10),
              Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'data_compliance_page.dart';
import 'home_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_use_page.dart';

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
  bool _isResettingPassword = false;
  bool _hasAcceptedLegalConsent = false;
  bool _isPasswordVisible = false;

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

    if (!_isLogin && !_hasAcceptedLegalConsent) {
      _showMessage(
        'You must agree to the Privacy Policy, Terms of Use, and Data & Compliance notice.',
      );
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
      _isResettingPassword = true;
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
          _isResettingPassword = false;
        });
      }
    }
  }

  bool _canProceedWithSocialSignIn() {
    if (_hasAcceptedLegalConsent) {
      return true;
    }

    _showMessage(
      'You must agree to the Privacy Policy, Terms of Use, and Data & Compliance notice before using Google or Facebook sign-in.',
    );
    return false;
  }

  Future<void> _signInWithGoogle() async {
    if (!_canProceedWithSocialSignIn()) {
      return;
    }

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
    if (!_canProceedWithSocialSignIn()) {
      return;
    }

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
      _hasAcceptedLegalConsent = false;
    });
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  void _openTermsOfUse() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TermsOfUsePage()),
    );
  }

  void _openDataCompliance() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DataCompliancePage()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Widget _buildLegalConsentSection({
    required bool isDark,
    required Color titleColor,
    required bool extraCompact,
    required bool flatStyle,
  }) {
    final sectionPadding = flatStyle
        ? const EdgeInsets.symmetric(vertical: 2)
        : const EdgeInsets.all(12);

    return Container(
      width: double.infinity,
      padding: sectionPadding,
      decoration: flatStyle
          ? null
          : BoxDecoration(
              color: isDark ? const Color(0xFF1A2333) : const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFDCE3EC),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: flatStyle ? 26 : 32,
                height: flatStyle ? 26 : 32,
                child: Checkbox(
                  value: _hasAcceptedLegalConsent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _hasAcceptedLegalConsent = value ?? false;
                          });
                        },
                ),
              ),
              SizedBox(width: flatStyle ? 8 : 6),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: flatStyle ? 3 : 4),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: extraCompact ? 11.5 : 12.5,
                        height: 1.3,
                        color: titleColor.withValues(alpha: 0.82),
                      ),
                      children: const [
                        TextSpan(text: 'I have read and agree to the '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ', '),
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ', and '),
                        TextSpan(
                          text: 'Data Compliance',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: flatStyle ? 4 : 6),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _LegalChipButton(
                  label: 'Privacy',
                  onTap: _openPrivacyPolicy,
                ),
                _LegalChipButton(
                  label: 'Terms',
                  onTap: _openTermsOfUse,
                ),
                _LegalChipButton(
                  label: 'Compliance',
                  onTap: _openDataCompliance,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLayout({
    required bool isDark,
    required double screenHeight,
    required double screenWidth,
    required double horizontalPadding,
    required double topPanelPadding,
    required double fieldSpacing,
    required double titleFontSize,
    required double subtitleFontSize,
    required double socialGap,
    required double headerTopSpace,
    required double headerBottomSpace,
    required double bottomSafeArea,
    required bool useStackedSocialButtons,
    required double panelMaxWidth,
    required Color pageBackground,
    required Color panelBackground,
    required Color headerBackground,
    required Color titleColor,
    required Color subtitleColor,
    required Color dividerColor,
    required bool compact,
    required bool extraCompact,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required String footerPrompt,
  }) {
    final loginHorizontalPadding = extraCompact ? 18.0 : 22.0;
    final topGap = extraCompact ? 16.0 : 22.0;
    final titleGap = extraCompact ? 4.0 : 6.0;
    final introGap = extraCompact ? 14.0 : 18.0;
    final inputGap = extraCompact ? 10.0 : 12.0;
    final betweenMainSections = extraCompact ? 12.0 : 16.0;
    final legalGap = extraCompact ? 10.0 : 12.0;
    final dividerGap = extraCompact ? 10.0 : 12.0;
    final footerGap = extraCompact ? 4.0 : 6.0;

    return Container(
      color: pageBackground,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: headerBackground,
            padding: EdgeInsets.only(
              top: headerTopSpace,
              bottom: headerBottomSpace,
              left: horizontalPadding,
              right: horizontalPadding,
            ),
            child: _AuthHeader(
              compact: compact || extraCompact,
              screenWidth: screenWidth,
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: panelMaxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  extraCompact ? 14 : 18,
                  14,
                  extraCompact ? 14 : 18,
                  10 + bottomSafeArea,
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    loginHorizontalPadding,
                    topGap,
                    loginHorizontalPadding,
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: panelBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? const Color(0xFF243244) : const Color(0xFFE2E8F0),
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
                            color: titleColor,
                          ),
                        ),
                        SizedBox(height: titleGap),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: subtitleColor,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: introGap),
                        _AuthTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          compact: compact || extraCompact,
                        ),
                        SizedBox(height: inputGap),
                        _AuthTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: !_isPasswordVisible,
                          compact: compact || extraCompact,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                        SizedBox(height: extraCompact ? 4.0 : 6.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isResettingPassword || _isLoading
                                ? null
                                : _forgotPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _isResettingPassword
                                  ? 'Sending reset link...'
                                  : 'Forgot password?',
                              style: TextStyle(
                                color: const Color(0xFF0B4C8C),
                                fontSize: extraCompact ? 13 : 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: betweenMainSections),
                        SizedBox(
                          width: double.infinity,
                          height: extraCompact ? 46 : 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B4C8C),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    buttonLabel,
                                    style: TextStyle(
                                      fontSize: extraCompact ? 14 : 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: legalGap),
                        _buildLegalConsentSection(
                          isDark: isDark,
                          titleColor: titleColor,
                          extraCompact: extraCompact,
                          flatStyle: true,
                        ),
                        SizedBox(height: dividerGap + 2),
                        Row(
                          children: [
                            Expanded(child: Divider(color: dividerColor)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: extraCompact ? 10 : 14,
                              ),
                              child: Text(
                                'or login with',
                                style: TextStyle(
                                  fontSize: extraCompact ? 12 : 13,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: dividerColor)),
                          ],
                        ),
                        SizedBox(height: dividerGap),
                        Column(
                          children: [
                            _SocialButton(
                              icon: Icons.g_mobiledata,
                              label: 'Continue with Google',
                              iconColor: const Color(0xFFDB4437),
                              compact: compact || extraCompact,
                              onTap: _isLoading ? null : _signInWithGoogle,
                              fullWidth: true,
                            ),
                            SizedBox(height: socialGap),
                            _SocialButton(
                              icon: Icons.facebook,
                              label: 'Continue with Facebook',
                              iconColor: const Color(0xFF1877F2),
                              compact: compact || extraCompact,
                              onTap: _isLoading ? null : _signInWithFacebook,
                              fullWidth: true,
                            ),
                          ],
                        ),
                        SizedBox(height: extraCompact ? 14 : 18),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => _switchMode(AuthMode.signUp),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: titleColor,
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: extraCompact ? 14 : 15,
                                  color: subtitleColor,
                                ),
                                children: [
                                  TextSpan(text: footerPrompt),
                                  TextSpan(
                                    text: 'Sign up',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: footerGap),
                      ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLayout({
    required bool isDark,
    required double screenHeight,
    required double screenWidth,
    required double horizontalPadding,
    required double topPanelPadding,
    required double fieldSpacing,
    required double titleFontSize,
    required double subtitleFontSize,
    required double headerTopSpace,
    required double headerBottomSpace,
    required double bottomSafeArea,
    required double panelMaxWidth,
    required Color pageBackground,
    required Color panelBackground,
    required Color headerBackground,
    required Color titleColor,
    required Color subtitleColor,
    required Color dividerColor,
    required bool compact,
    required bool extraCompact,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required String footerPrompt,
  }) {
    final signupHorizontalPadding = extraCompact ? 18.0 : 22.0;
    final localFieldSpacing = extraCompact ? 10.0 : 12.0;

    return Container(
      color: pageBackground,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: headerBackground,
            padding: EdgeInsets.only(
              top: headerTopSpace,
              bottom: headerBottomSpace,
              left: horizontalPadding,
              right: horizontalPadding,
            ),
            child: _AuthHeader(
              compact: compact || extraCompact,
              screenWidth: screenWidth,
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: panelMaxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  extraCompact ? 14 : 18,
                  14,
                  extraCompact ? 14 : 18,
                  12 + bottomSafeArea,
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    signupHorizontalPadding,
                    extraCompact ? 16 : 20,
                    signupHorizontalPadding,
                    extraCompact ? 14 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: panelBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? const Color(0xFF243244) : const Color(0xFFE2E8F0),
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
                            color: titleColor,
                          ),
                        ),
                        SizedBox(height: extraCompact ? 4 : 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: subtitleColor,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: extraCompact ? 14 : 18),
                        _AuthTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          compact: true,
                        ),
                        SizedBox(height: localFieldSpacing),
                        _AuthTextField(
                          controller: _usernameController,
                          hintText: 'Username or full name',
                          icon: Icons.person_outline_rounded,
                          compact: true,
                        ),
                        SizedBox(height: localFieldSpacing),
                        _AuthTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: !_isPasswordVisible,
                          compact: true,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                        SizedBox(height: localFieldSpacing),
                        _buildLegalConsentSection(
                          isDark: isDark,
                          titleColor: titleColor,
                          extraCompact: true,
                          flatStyle: false,
                        ),
                        SizedBox(height: extraCompact ? 14 : 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isLoading || !_hasAcceptedLegalConsent
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B4C8C),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    buttonLabel,
                                    style: TextStyle(
                                      fontSize: extraCompact ? 14 : 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: extraCompact ? 12 : 14),
                        Divider(color: dividerColor),
                        SizedBox(height: extraCompact ? 10 : 12),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => _switchMode(AuthMode.login),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: titleColor,
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subtitleColor,
                                ),
                                children: [
                                  TextSpan(text: footerPrompt),
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: titleColor,
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = _isLogin ? 'Login now!' : 'Sign up now!';
    final subtitle = 'Start your journey now with ease.';
    final buttonLabel = _isLogin ? 'Login' : 'Sign up';
    final footerPrompt = _isLogin
        ? "Don't have an account? "
        : 'Already have an account? ';
    final pageBackground =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6F8);
    final panelBackground =
        isDark ? const Color(0xFF111827) : Colors.white;
    final headerBackground =
        isDark ? const Color(0xFF111B2E) : const Color(0xFF2357A6);
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF8A8A8A);
    final dividerColor = isDark ? Colors.white24 : const Color(0xFFB7B7B7);

    return Scaffold(
      backgroundColor: pageBackground,
      resizeToAvoidBottomInset: true,
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
                ? 16.0
                : compact
                    ? 20.0
                    : 28.0;
            final fieldSpacing = extraCompact
                ? 12.0
                : compact
                    ? 14.0
                    : 20.0;
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
            final socialGap = extraCompact ? 8.0 : 12.0;
            final headerTopSpace = extraCompact ? 12.0 : compact ? 16.0 : 28.0;
            final headerBottomSpace =
                extraCompact ? 12.0 : compact ? 16.0 : 28.0;
            final bottomSafeArea = MediaQuery.of(context).padding.bottom;
            final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
            final useStackedSocialButtons = screenWidth < 370;
            final panelMaxWidth = screenWidth > 520 ? 520.0 : screenWidth;

            final content = _isLogin
                ? _buildLoginLayout(
                    isDark: isDark,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                    horizontalPadding: horizontalPadding,
                    topPanelPadding: topPanelPadding,
                    fieldSpacing: fieldSpacing,
                    titleFontSize: titleFontSize,
                    subtitleFontSize: subtitleFontSize,
                    socialGap: socialGap,
                    headerTopSpace: headerTopSpace,
                    headerBottomSpace: headerBottomSpace,
                    bottomSafeArea: bottomSafeArea,
                    useStackedSocialButtons: useStackedSocialButtons,
                    panelMaxWidth: panelMaxWidth,
                    pageBackground: pageBackground,
                    panelBackground: panelBackground,
                    headerBackground: headerBackground,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    dividerColor: dividerColor,
                    compact: compact,
                    extraCompact: extraCompact,
                    title: title,
                    subtitle: subtitle,
                    buttonLabel: buttonLabel,
                    footerPrompt: footerPrompt,
                  )
                : _buildSignUpLayout(
                    isDark: isDark,
                    screenHeight: screenHeight,
                    screenWidth: screenWidth,
                    horizontalPadding: horizontalPadding,
                    topPanelPadding: topPanelPadding,
                    fieldSpacing: fieldSpacing,
                    titleFontSize: titleFontSize,
                    subtitleFontSize: subtitleFontSize,
                    headerTopSpace: headerTopSpace,
                    headerBottomSpace: headerBottomSpace,
                    bottomSafeArea: bottomSafeArea,
                    panelMaxWidth: panelMaxWidth,
                    pageBackground: pageBackground,
                    panelBackground: panelBackground,
                    headerBackground: headerBackground,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    dividerColor: dividerColor,
                    compact: compact,
                    extraCompact: extraCompact,
                    title: title,
                    subtitle: subtitle,
                    buttonLabel: buttonLabel,
                    footerPrompt: footerPrompt,
                  );

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: content,
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
  const _AuthHeader({
    required this.compact,
    required this.screenWidth,
  });

  final bool compact;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final logoSize = screenWidth < 360
        ? 54.0
        : compact
            ? 58.0
            : 72.0;
    final titleSize = screenWidth < 360
        ? 28.0
        : compact
            ? 30.0
            : 38.0;
    final taglineSize = screenWidth < 360
        ? 8.0
        : compact
            ? 8.5
            : 10.0;

    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          height: logoSize,
        ),
        SizedBox(height: compact ? 10 : 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'iTIWI',
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(height: compact ? 1 : 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "ORAGON'S CHARM. BICOL'S SOUL.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: taglineSize,
                letterSpacing: 0.8,
              ),
            ),
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
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool compact;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFD);
    final textColor = isDark ? Colors.white : const Color(0xFF172033);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF52709A);
    final hintColor = isDark ? Colors.white54 : const Color(0xFF7A8699);
    final borderColor = isDark ? const Color(0xFF475569) : const Color(0xFFD6E0EE);

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: textColor,
        fontSize: compact ? 14 : 16,
      ),
      cursorColor: isDark ? Colors.white : const Color(0xFF0B4C8C),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: compact ? 14 : 16,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: EdgeInsets.symmetric(vertical: compact ? 14 : 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFF0B4C8C),
            width: 1.6,
          ),
        ),
      ),
    );
  }
}

class _LegalChipButton extends StatelessWidget {
  const _LegalChipButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0B4C8C).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0B4C8C),
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
    this.fullWidth = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final bool compact;
  final bool fullWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: fullWidth ? double.infinity : null,
          height: compact ? 40 : 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9E2EF)),
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
